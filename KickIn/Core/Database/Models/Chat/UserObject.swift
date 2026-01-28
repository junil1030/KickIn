//
//  UserObject.swift
//  KickIn
//
//  Created by 서준일 on 01/28/26.
//

import Foundation
import RealmSwift

final class UserObject: Object {
    @Persisted(primaryKey: true) var userId: String
    @Persisted var nickname: String
    @Persisted var profileImage: String?
    @Persisted var introduction: String?
    @Persisted var updatedAt: String?

    // 역참조 - 이 유저가 보낸 메시지들
    @Persisted(originProperty: "sender") var sentMessages: LinkingObjects<ChatMessageObject>

    convenience init(
        userId: String,
        nickname: String,
        profileImage: String? = nil,
        introduction: String? = nil,
        updatedAt: String? = nil
    ) {
        self.init()
        self.userId = userId
        self.nickname = nickname
        self.profileImage = profileImage
        self.introduction = introduction
        self.updatedAt = updatedAt
    }
}

// MARK: - DTO → Realm Object Extension

extension ChatSenderDTO {
    func toRealmObject() -> UserObject {
        UserObject(
            userId: self.userId ?? UUID().uuidString,
            nickname: self.nick ?? "알 수 없는 사용자",
            profileImage: self.profileImage,
            introduction: self.introduction
        )
    }
}

extension ChatParticipantDTO {
    func toRealmObject() -> UserObject {
        UserObject(
            userId: self.userId ?? UUID().uuidString,
            nickname: self.nick ?? "알 수 없는 사용자",
            profileImage: self.profileImage,
            introduction: self.introduction
        )
    }
}
