//
//  VideoLikeRequestDTO.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import Foundation

struct VideoLikeRequestDTO: Encodable {
    let likeStatus: Bool

    enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}
