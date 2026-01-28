//
//  ChatRoomObject.swift
//  KickIn
//
//  Created by 서준일 on 01/28/26.
//

import Foundation
import RealmSwift

final class ChatRoomObject: Object {
    @Persisted(primaryKey: true) var roomId: String
    @Persisted var createdAt: String
    @Persisted var updatedAt: String?

    // 참가자들 (나 + 상대방)
    @Persisted var participants: List<UserObject>

    // 마지막 메시지 참조 (목록 정렬/미리보기용)
    @Persisted var lastMessage: ChatMessageObject?

    // 페이지네이션 메타데이터
    @Persisted var lastCursor: String?
    @Persisted var hasMoreData: Bool = true
    @Persisted var lastSyncedAt: String?

    // 역참조 - 이 방의 모든 메시지
    @Persisted(originProperty: "room") var messages: LinkingObjects<ChatMessageObject>

    convenience init(
        roomId: String,
        createdAt: String,
        updatedAt: String? = nil,
        participants: [UserObject] = [],
        lastMessage: ChatMessageObject? = nil,
        lastCursor: String? = nil,
        hasMoreData: Bool = true,
        lastSyncedAt: String? = nil
    ) {
        self.init()
        self.roomId = roomId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.participants.append(objectsIn: participants)
        self.lastMessage = lastMessage
        self.lastCursor = lastCursor
        self.hasMoreData = hasMoreData
        self.lastSyncedAt = lastSyncedAt
    }
}

// MARK: - DTO → Realm Object Extension

extension ChatRoomItemDTO {
    func toRealmObject(existingUsers: [String: UserObject]) -> ChatRoomObject {
        let participantObjects = (self.participants ?? []).map { dto -> UserObject in
            if let existing = existingUsers[dto.userId ?? ""] {
                return existing
            }
            return dto.toRealmObject()
        }

        return ChatRoomObject(
            roomId: self.roomId ?? UUID().uuidString,
            createdAt: self.createdAt ?? ISO8601DateFormatter().string(from: Date()),
            updatedAt: self.updatedAt,
            participants: participantObjects
        )
    }
}
