//
//  ChatMessageRepository.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation
import RealmSwift
import OSLog

// MARK: - RealmActor for Thread Safety

actor RealmActor {
    private let configuration: Realm.Configuration

    init(configuration: Realm.Configuration = Realm.Configuration.defaultConfiguration) {
        self.configuration = configuration
    }

    func write<T>(_ block: (Realm) throws -> T) throws -> T {
        let realm = try Realm(configuration: configuration)
        return try realm.write {
            try block(realm)
        }
    }

    func read<T>(_ block: (Realm) throws -> T) throws -> T {
        let realm = try Realm(configuration: configuration)
        return try block(realm)
    }
}

// MARK: - ChatMessageRepository

final class ChatMessageRepository: ChatMessageRepositoryProtocol {
    private let actor: RealmActor

    init(configuration: Realm.Configuration = Realm.Configuration.defaultConfiguration) {
        self.actor = RealmActor(configuration: configuration)
    }

    // MARK: - User Operations

    func getOrCreateUser(userId: String, nickname: String, profileImage: String?, introduction: String?) async throws -> UserObject {
        try await actor.write { realm in
            if let existing = realm.object(ofType: UserObject.self, forPrimaryKey: userId) {
                // 기존 유저 정보 업데이트
                existing.nickname = nickname
                existing.profileImage = profileImage
                existing.introduction = introduction
                existing.updatedAt = ISO8601DateFormatter().string(from: Date())
                return existing
            } else {
                // 새 유저 생성
                let user = UserObject(
                    userId: userId,
                    nickname: nickname,
                    profileImage: profileImage,
                    introduction: introduction,
                    updatedAt: ISO8601DateFormatter().string(from: Date())
                )
                realm.add(user)
                Logger.database.info("👤 Created new user: \(userId)")
                return user
            }
        }
    }

    func updateUser(userId: String, nickname: String?, profileImage: String?, introduction: String?) async throws {
        try await actor.write { realm in
            if let user = realm.object(ofType: UserObject.self, forPrimaryKey: userId) {
                if let nickname = nickname {
                    user.nickname = nickname
                }
                if let profileImage = profileImage {
                    user.profileImage = profileImage
                }
                if let introduction = introduction {
                    user.introduction = introduction
                }
                user.updatedAt = ISO8601DateFormatter().string(from: Date())
                Logger.database.info("👤 Updated user: \(userId)")
            }
        }
    }

    func getUser(userId: String) async throws -> UserObject? {
        try await actor.read { realm in
            realm.object(ofType: UserObject.self, forPrimaryKey: userId)?.freeze()
        }
    }

    // MARK: - Room Operations

    func getOrCreateRoom(roomId: String, createdAt: String, participants: [UserObject]) async throws -> ChatRoomObject {
        try await actor.write { realm in
            if let existing = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) {
                return existing
            } else {
                let room = ChatRoomObject(
                    roomId: roomId,
                    createdAt: createdAt
                )
                // participants 추가 (managed objects 필요)
                for participant in participants {
                    if let managedUser = realm.object(ofType: UserObject.self, forPrimaryKey: participant.userId) {
                        room.participants.append(managedUser)
                    } else {
                        realm.add(participant)
                        room.participants.append(participant)
                    }
                }
                realm.add(room)
                Logger.database.info("🏠 Created new room: \(roomId)")
                return room
            }
        }
    }

    func getRoom(roomId: String) async throws -> ChatRoomObject? {
        try await actor.read { realm in
            realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId)?.freeze()
        }
    }

    func updateRoomLastMessage(roomId: String, message: ChatMessageObject) async throws {
        try await actor.write { realm in
            if let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId),
               let managedMessage = realm.object(ofType: ChatMessageObject.self, forPrimaryKey: message.chatId) {
                room.lastMessage = managedMessage
                room.updatedAt = message.createdAt
            }
        }
    }

    // MARK: - Message CRUD

    func saveMessage(_ message: ChatMessageObject) async throws {
        try await actor.write { realm in
            realm.add(message, update: .modified)
        }
        Logger.database.info("💾 Saved message: \(message.chatId)")
    }

    func saveMessageFromDTO(_ messageDTO: ChatMessageItemDTO, roomId: String, myUserId: String) async throws {
        try await actor.write { realm in
            // Room 가져오기 또는 생성
            let room: ChatRoomObject
            if let existingRoom = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) {
                room = existingRoom
            } else {
                room = ChatRoomObject(
                    roomId: roomId,
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )
                realm.add(room)
            }

            // Sender 가져오기 또는 생성
            var sender: UserObject?
            if let senderDTO = messageDTO.sender, let senderId = senderDTO.userId {
                if let existingSender = realm.object(ofType: UserObject.self, forPrimaryKey: senderId) {
                    sender = existingSender
                } else {
                    sender = senderDTO.toRealmObject()
                    realm.add(sender!)
                }
            }

            // 메시지 생성
            let message = ChatMessageObject(
                chatId: messageDTO.chatId ?? UUID().uuidString,
                room: room,
                content: messageDTO.content,
                createdAt: messageDTO.createdAt ?? ISO8601DateFormatter().string(from: Date()),
                updatedAt: messageDTO.updatedAt,
                sender: sender,
                files: messageDTO.files ?? [],
                isSentByMe: messageDTO.sender?.userId == myUserId,
                isTemporary: false
            )

            realm.add(message, update: .modified)

            // Room의 lastMessage 업데이트
            room.lastMessage = message
            room.updatedAt = message.createdAt
        }
        Logger.database.info("💾 Saved message from DTO: \(messageDTO.chatId ?? "unknown")")
    }

    func createAndSaveTemporaryMessage(
        chatId: String,
        roomId: String,
        content: String?,
        createdAt: String,
        senderUserId: String,
        senderNickname: String,
        senderProfileImage: String?,
        files: [String]
    ) async throws {
        try await actor.write { realm in
            // Room 가져오기 또는 생성
            let room: ChatRoomObject
            if let existingRoom = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) {
                room = existingRoom
            } else {
                room = ChatRoomObject(
                    roomId: roomId,
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )
                realm.add(room)
            }

            // Sender 가져오기 또는 생성
            let sender: UserObject
            if let existingSender = realm.object(ofType: UserObject.self, forPrimaryKey: senderUserId) {
                sender = existingSender
            } else {
                sender = UserObject(
                    userId: senderUserId,
                    nickname: senderNickname,
                    profileImage: senderProfileImage
                )
                realm.add(sender)
            }

            // 임시 메시지 생성
            let message = ChatMessageObject(
                chatId: chatId,
                room: room,
                content: content,
                createdAt: createdAt,
                sender: sender,
                files: files,
                isSentByMe: true,
                isTemporary: true
            )

            realm.add(message, update: .modified)
        }
        Logger.database.info("💾 Created temporary message: \(chatId)")
    }

    func fetchMessages(roomId: String, limit: Int = 50, beforeDate: String? = nil) async throws -> [ChatMessageObject] {
        try await actor.read { realm in
            var query = realm.objects(ChatMessageObject.self)
                .where { $0.room.roomId == roomId }

            if let beforeDate = beforeDate {
                query = query.where { $0.createdAt < beforeDate }
            }

            let results = query
                .sorted(byKeyPath: "createdAt", ascending: false)
                .prefix(limit)

            return Array(results.map { $0.freeze() })
        }
    }

    func fetchMessagesAsUIModels(roomId: String, limit: Int = 50, beforeDate: String? = nil) async throws -> [ChatMessageUIModel] {
        try await actor.read { realm in
            var query = realm.objects(ChatMessageObject.self)
                .where { $0.room.roomId == roomId }

            if let beforeDate = beforeDate {
                query = query.where { $0.createdAt < beforeDate }
            }

            let results = query
                .sorted(byKeyPath: "createdAt", ascending: false)
                .prefix(limit)

            // RealmActor 내부에서 UIModel로 변환
            return results.map { message in
                ChatMessageUIModel(
                    id: message.chatId,
                    content: message.content,
                    createdAt: message.createdAt,
                    senderUserId: message.sender?.userId,
                    senderNickname: message.sender?.nickname ?? "알 수 없음",
                    senderProfileImage: message.sender?.profileImage,
                    files: Array(message.files),
                    isSentByMe: message.isSentByMe,
                    isTemporary: message.isTemporary,
                    sendFailed: message.sendFailedReason != nil
                )
            }
        }
    }

    func fetchChatIds(roomId: String) async throws -> Set<String> {
        try await actor.read { realm in
            let results = realm.objects(ChatMessageObject.self)
                .where { $0.room.roomId == roomId }
            return Set(results.map { $0.chatId })
        }
    }

    func deleteMessage(chatId: String) async throws {
        try await actor.write { realm in
            if let message = realm.object(ofType: ChatMessageObject.self, forPrimaryKey: chatId) {
                realm.delete(message)
                Logger.database.info("🗑️ Deleted message: \(chatId)")
            }
        }
    }

    func updateMessageStatus(chatId: String, isTemporary: Bool, failReason: String?) async throws {
        try await actor.write { realm in
            if let message = realm.object(ofType: ChatMessageObject.self, forPrimaryKey: chatId) {
                message.isTemporary = isTemporary
                message.sendFailedReason = failReason
                Logger.database.info("✏️ Updated message status: \(chatId)")
            }
        }
    }

    // MARK: - Batch Operations

    func saveMessagesFromDTOs(_ messages: [ChatMessageItemDTO], roomId: String, myUserId: String) async throws {
        guard !messages.isEmpty else { return }

        try await actor.write { realm in
            // Room 가져오기 또는 생성
            let room: ChatRoomObject
            if let existingRoom = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) {
                room = existingRoom
            } else {
                room = ChatRoomObject(
                    roomId: roomId,
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )
                realm.add(room)
            }

            // 유저 캐시 (같은 트랜잭션 내 중복 조회 방지)
            var userCache: [String: UserObject] = [:]

            for messageDTO in messages {
                // Sender 처리
                var sender: UserObject?
                if let senderDTO = messageDTO.sender, let senderId = senderDTO.userId {
                    if let cachedUser = userCache[senderId] {
                        sender = cachedUser
                    } else if let existingSender = realm.object(ofType: UserObject.self, forPrimaryKey: senderId) {
                        sender = existingSender
                        userCache[senderId] = existingSender
                    } else {
                        let newSender = senderDTO.toRealmObject()
                        realm.add(newSender)
                        sender = newSender
                        userCache[senderId] = newSender
                    }
                }

                // 메시지 생성
                let message = ChatMessageObject(
                    chatId: messageDTO.chatId ?? UUID().uuidString,
                    room: room,
                    content: messageDTO.content,
                    createdAt: messageDTO.createdAt ?? ISO8601DateFormatter().string(from: Date()),
                    updatedAt: messageDTO.updatedAt,
                    sender: sender,
                    files: messageDTO.files ?? [],
                    isSentByMe: messageDTO.sender?.userId == myUserId,
                    isTemporary: false
                )

                realm.add(message, update: .modified)
            }

            // 가장 최신 메시지로 room.lastMessage 업데이트
            if let latestMessage = messages.max(by: { ($0.createdAt ?? "") < ($1.createdAt ?? "") }),
               let latestChatId = latestMessage.chatId,
               let savedMessage = realm.object(ofType: ChatMessageObject.self, forPrimaryKey: latestChatId) {
                room.lastMessage = savedMessage
                room.updatedAt = savedMessage.createdAt
            }
        }
        Logger.database.info("💾 [Batch] Saved \(messages.count) messages in single transaction")
    }

    // MARK: - Metadata Operations

    func getMetadata(roomId: String) async throws -> (lastCursor: String?, hasMoreData: Bool)? {
        try await actor.read { realm in
            guard let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) else {
                return nil
            }
            return (room.lastCursor, room.hasMoreData)
        }
    }

    func updateMetadata(roomId: String, lastCursor: String?, hasMoreData: Bool) async throws {
        try await actor.write { realm in
            if let room = realm.object(ofType: ChatRoomObject.self, forPrimaryKey: roomId) {
                room.lastCursor = lastCursor
                room.hasMoreData = hasMoreData
                room.lastSyncedAt = ISO8601DateFormatter().string(from: Date())
                Logger.database.info("✏️ Updated metadata for room: \(roomId)")
            } else {
                // Room이 없으면 생성
                let room = ChatRoomObject(
                    roomId: roomId,
                    createdAt: ISO8601DateFormatter().string(from: Date()),
                    lastCursor: lastCursor,
                    hasMoreData: hasMoreData,
                    lastSyncedAt: ISO8601DateFormatter().string(from: Date())
                )
                realm.add(room)
                Logger.database.info("🏠 Created room with metadata: \(roomId)")
            }
        }
    }
}
