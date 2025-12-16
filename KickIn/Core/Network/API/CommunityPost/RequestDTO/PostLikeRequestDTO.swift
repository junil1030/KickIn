//
//  PostLikeRequestDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct PostLikeRequestDTO: Encodable {
    let likeStatus: Bool?

    enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}
