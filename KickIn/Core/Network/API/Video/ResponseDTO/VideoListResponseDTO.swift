//
//  VideoListResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import Foundation

struct VideoListResponseDTO: Decodable {
    let data: [VideoItemDTO]?
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}

struct VideoItemDTO: Decodable {
    let videoId: String?
    let fileName: String?
    let title: String?
    let description: String?
    let duration: Double?
    let thumbnailUrl: String?
    let availableQualities: [String]?
    let viewCount: Int?
    let likeCount: Int?
    let isLiked: Bool?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case videoId = "video_id"
        case fileName = "file_name"
        case title
        case description
        case duration
        case thumbnailUrl = "thumbnail_url"
        case availableQualities = "available_qualities"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case isLiked = "is_liked"
        case createdAt
    }
}
