//
//  UserProfileResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct UserProfileResponseDTO: Decodable {
    let userId: String?
    let email: String?
    let nick: String?
    let introduction: String?
    let profileImage: String?
    let phoneNum: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case nick
        case introduction
        case profileImage
        case phoneNum
    }
}
