//
//  PostLikeResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct PostLikeResponseDTO: Decodable {
    let likeStatus: Bool?

    enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}
