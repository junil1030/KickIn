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

    // MARK: - CRUD Operations

    func saveMessages(_ messages: [ChatMessageObject]) async throws {
        try await actor.write { realm in
            realm.add(messages, update: .modified)  // upsert
        }
        Logger.database.info("💾 Saved \(messages.count) messages")
    }

    func saveMessage(_ message: ChatMessageObject) async throws {
        try await actor.write { realm in
            realm.add(message, update: .modified)
        }
        Logger.database.info("💾 Saved message: \(message.chatId)")
    }

    func saveMessageFromDTO(_ messageDTO: ChatMessageItemDTO, myUserId: String) async throws {
        try await actor.write { realm in
            let message = ChatMessageObject()
            message.chatId = messageDTO.chatId ?? UUID().uuidString
            message.roomId = messageDTO.roomId ?? ""
            message.content = messageDTO.content
            message.createdAt = messageDTO.createdAt ?? ISO8601DateFormatter().string(from: Date())
            message.updatedAt = messageDTO.updatedAt
            message.senderUserId = messageDTO.sender?.userId
            message.senderNickname = messageDTO.sender?.nick
            message.senderProfileImage = messageDTO.sender?.profileImage
            message.senderIntroduction = messageDTO.sender?.introduction
            if let files = messageDTO.files {
                message.files.append(objectsIn: files)
            }
            message.isSentByMe = messageDTO.sender?.userId == myUserId
            message.isTemporary = false

            realm.add(message, update: .modified)
        }
        Logger.database.info("💾 Saved message from DTO: \(messageDTO.chatId ?? "unknown")")
    }

    func createAndSaveMessage(
        chatId: String,
        roomId: String,
        content: String?,
        createdAt: String,
        updatedAt: String?,
        senderUserId: String?,
        senderNickname: String?,
        senderProfileImage: String?,
        senderIntroduction: String?,
        files: [String],
        isSentByMe: Bool,
        isTemporary: Bool
    ) async throws {
        try await actor.write { realm in
            let message = ChatMessageObject()
            message.chatId = chatId
            message.roomId = roomId
            message.content = content
            message.createdAt = createdAt
            message.updatedAt = updatedAt
            message.senderUserId = senderUserId
            message.senderNickname = senderNickname
            message.senderProfileImage = senderProfileImage
            message.senderIntroduction = senderIntroduction
            message.files.append(objectsIn: files)
            message.isSentByMe = isSentByMe
            message.isTemporary = isTemporary

            realm.add(message, update: .modified)
        }
        Logger.database.info("💾 Created and saved message: \(chatId)")
    }

    func fetchMessages(roomId: String, limit: Int = 50, beforeDate: String? = nil) async throws -> [ChatMessageObject] {
        try await actor.read { realm in
            var query = realm.objects(ChatMessageObject.self)
                .where { $0.roomId == roomId }

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
                .where { $0.roomId == roomId }

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
                    senderNickname: message.senderNickname ?? "알 수 없음",
                    senderProfileImage: message.senderProfileImage,
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
                .where { $0.roomId == roomId }
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

    func saveMessagesFromDTOs(_ messages: [ChatMessageItemDTO], myUserId: String) async throws {
        guard !messages.isEmpty else { return }

        try await actor.write { realm in
            for messageDTO in messages {
                let message = ChatMessageObject()
                message.chatId = messageDTO.chatId ?? UUID().uuidString
                message.roomId = messageDTO.roomId ?? ""
                message.content = messageDTO.content
                message.createdAt = messageDTO.createdAt ?? ISO8601DateFormatter().string(from: Date())
                message.updatedAt = messageDTO.updatedAt
                message.senderUserId = messageDTO.sender?.userId
                message.senderNickname = messageDTO.sender?.nick
                message.senderProfileImage = messageDTO.sender?.profileImage
                message.senderIntroduction = messageDTO.sender?.introduction
                if let files = messageDTO.files {
                    message.files.append(objectsIn: files)
                }
                message.isSentByMe = messageDTO.sender?.userId == myUserId
                message.isTemporary = false

                realm.add(message, update: .modified)
            }
        }
        Logger.database.info("💾 [Batch] Saved \(messages.count) messages in single transaction")
    }

    // MARK: - Metadata Operations

    func getMetadata(roomId: String) async throws -> ChatRoomMetadataObject? {
        try await actor.read { realm in
            realm.object(ofType: ChatRoomMetadataObject.self, forPrimaryKey: roomId)?.freeze()
        }
    }

    func updateMetadata(roomId: String, lastCursor: String?, hasMoreData: Bool) async throws {
        try await actor.write { realm in
            let metadata = ChatRoomMetadataObject()
            metadata.roomId = roomId
            metadata.lastCursor = lastCursor
            metadata.hasMoreData = hasMoreData
            metadata.lastSyncedAt = ISO8601DateFormatter().string(from: Date())
            realm.add(metadata, update: .modified)
            Logger.database.info("✏️ Updated metadata for room: \(roomId)")
        }
    }
}
