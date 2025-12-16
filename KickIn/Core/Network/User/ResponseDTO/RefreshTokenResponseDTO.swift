//
//  RefreshTokenResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct RefreshTokenResponseDTO: Decodable {
    let accessToken: String?
    let refreshToken: String?
}
