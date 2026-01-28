//
//  ChatMessageObject.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation
import RealmSwift

final class ChatMessageObject: Object, Identifiable {
    @Persisted(primaryKey: true) var chatId: String
    @Persisted var content: String?
    @Persisted var createdAt: String
    @Persisted var updatedAt: String?

    // Files
    @Persisted var files: List<String>

    // 관계 참조
    @Persisted var room: ChatRoomObject?
    @Persisted var sender: UserObject?

    // Local metadata
    @Persisted var isSentByMe: Bool
    @Persisted var isTemporary: Bool = false
    @Persisted var sendFailedReason: String?

    convenience init(
        chatId: String,
        room: ChatRoomObject? = nil,
        content: String?,
        createdAt: String,
        updatedAt: String? = nil,
        sender: UserObject? = nil,
        files: [String] = [],
        isSentByMe: Bool,
        isTemporary: Bool = false
    ) {
        self.init()
        self.chatId = chatId
        self.room = room
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sender = sender
        self.files.append(objectsIn: files)
        self.isSentByMe = isSentByMe
        self.isTemporary = isTemporary
    }
}

// MARK: - DTO → Realm Object Extension

extension ChatMessageItemDTO {
    func toRealmObject(
        myUserId: String,
        room: ChatRoomObject?,
        existingUsers: [String: UserObject]
    ) -> ChatMessageObject {
        let senderObject: UserObject? = {
            guard let senderDTO = self.sender else { return nil }
            if let existing = existingUsers[senderDTO.userId ?? ""] {
                return existing
            }
            return senderDTO.toRealmObject()
        }()

        return ChatMessageObject(
            chatId: self.chatId ?? UUID().uuidString,
            room: room,
            content: self.content,
            createdAt: self.createdAt ?? ISO8601DateFormatter().string(from: Date()),
            updatedAt: self.updatedAt,
            sender: senderObject,
            files: self.files ?? [],
            isSentByMe: self.sender?.userId == myUserId,
            isTemporary: false
        )
    }
}
