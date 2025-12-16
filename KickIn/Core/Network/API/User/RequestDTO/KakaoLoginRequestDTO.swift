//
//  KakaoLoginRequestDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct KakaoLoginRequestDTO: Encodable {
    let oauthToken: String?
    let deviceToken: String?
}
