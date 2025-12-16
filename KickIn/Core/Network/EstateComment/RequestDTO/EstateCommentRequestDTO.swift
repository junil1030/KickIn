//
//  EstateCommentRequestDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct EstateCommentRequestDTO: Encodable {
    let parentCommentId: String?
    let content: String?

    enum CodingKeys: String, CodingKey {
        case parentCommentId = "parent_comment_id"
        case content
    }
}
