//
//  CreatePostRequestDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct CreatePostRequestDTO: Encodable {
    let category: String?
    let title: String?
    let content: String?
    let latitude: Double?
    let longitude: Double?
    let files: [String]?
}
