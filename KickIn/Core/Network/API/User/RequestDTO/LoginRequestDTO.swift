//
//  LoginRequestDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct LoginRequestDTO: Encodable {
    let email: String?
    let password: String?
    let deviceToken: String?
}
