//
//  JoinRequestDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct JoinRequestDTO: Encodable {
    let email: String?
    let password: String?
    let nick: String?
    let phoneNum: String?
    let introduction: String?
    let deviceToken: String?
}
