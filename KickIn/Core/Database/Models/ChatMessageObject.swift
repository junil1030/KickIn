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
    @Persisted(indexed: true) var roomId: String
    @Persisted var content: String?
    @Persisted var createdAt: String
    @Persisted var updatedAt: String?

    // Sender info
    @Persisted var senderUserId: String?
    @Persisted var senderNickname: String?
    @Persisted var senderProfileImage: String?
    @Persisted var senderIntroduction: String?

    // Files
    @Persisted var files: List<String>

    // Local metadata
    @Persisted var isSentByMe: Bool
    @Persisted var isTemporary: Bool = false
    @Persisted var sendFailedReason: String?

    convenience init(
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
        isTemporary: Bool = false
    ) {
        self.init()
        self.chatId = chatId
        self.roomId = roomId
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.senderUserId = senderUserId
        self.senderNickname = senderNickname
        self.senderProfileImage = senderProfileImage
        self.senderIntroduction = senderIntroduction
        self.files.append(objectsIn: files)
        self.isSentByMe = isSentByMe
        self.isTemporary = isTemporary
    }
}

// MARK: - DTO → Realm Object Extension

extension ChatMessageItemDTO {
    func toRealmObject(myUserId: String) -> ChatMessageObject {
        ChatMessageObject(
            chatId: self.chatId ?? UUID().uuidString,
            roomId: self.roomId ?? "",
            content: self.content,
            createdAt: self.createdAt ?? ISO8601DateFormatter().string(from: Date()),
            updatedAt: self.updatedAt,
            senderUserId: self.sender?.userId,
            senderNickname: self.sender?.nick,
            senderProfileImage: self.sender?.profileImage,
            senderIntroduction: self.sender?.introduction,
            files: self.files ?? [],
            isSentByMe: self.sender?.userId == myUserId,
            isTemporary: false
        )
    }
}
