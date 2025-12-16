//
//  SendMessageRequestDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct SendMessageRequestDTO: Encodable {
    let content: String?
    let files: [String]?
}
