//
//  PostCommentResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct PostCommentResponseDTO: Decodable {
    let commentId: String?
    let content: String?
    let createdAt: String?
    let creator: PostCreatorDTO?

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case createdAt
        case creator
    }
}
