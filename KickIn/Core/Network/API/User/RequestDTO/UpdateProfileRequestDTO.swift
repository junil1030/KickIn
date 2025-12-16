//
//  UpdateProfileRequestDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct UpdateProfileRequestDTO: Encodable {
    let nick: String?
    let introduction: String?
    let phoneNum: String?
    let profileImage: String?
}
