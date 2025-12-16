//
//  PostsGeolocationResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct PostsGeolocationResponseDTO: Decodable {
    let data: [PostListItemDTO]?
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}

struct PostListItemDTO: Decodable {
    let postId: String?
    let category: String?
    let title: String?
    let content: String?
    let geolocation: PostGeolocationDTO?
    let creator: PostCreatorDTO?
    let files: [String]?
    let isLike: Bool?
    let likeCount: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case category
        case title
        case content
        case geolocation
        case creator
        case files
        case isLike = "is_like"
        case likeCount = "like_count"
        case createdAt
        case updatedAt
    }
}
