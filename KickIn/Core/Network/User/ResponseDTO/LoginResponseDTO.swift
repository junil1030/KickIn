//
//  LoginResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct LoginResponseDTO: Decodable {
    let userId: String?
    let email: String?
    let nick: String?
    let profileImage: String?
    let accessToken: String?
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case nick
        case profileImage
        case accessToken
        case refreshToken
    }
}
