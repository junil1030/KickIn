//
//  UserSearchResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct UserSearchResponseDTO: Decodable {
    let data: [UserSearchItemDTO]?
}

struct UserSearchItemDTO: Decodable {
    let userId: String?
    let nick: String?
    let introduction: String?
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case introduction
        case profileImage
    }
}
