//
//  UserProfileUIModel.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation

struct UserProfileUIModel {
    let userId: String?
    let nick: String?
    let introduction: String?
    let profileImage: String?
}

extension UserProfileResponseDTO {
    func toUIModel() -> UserProfileUIModel {
        return UserProfileUIModel(
            userId: self.userId,
            nick: self.nick,
            introduction: self.introduction,
            profileImage: self.profileImage
        )
    }
}
