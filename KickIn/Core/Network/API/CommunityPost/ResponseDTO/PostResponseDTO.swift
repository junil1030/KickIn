//
//  PostResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct PostResponseDTO: Decodable {
    let postId: String?
    let category: String?
    let title: String?
    let content: String?
    let geolocation: PostGeolocationDTO?
    let creator: PostCreatorDTO?
    let files: [String]?
    let isLike: Bool?
    let likeCount: Int?
    let comments: [PostCommentDTO]?
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
        case comments
        case createdAt
        case updatedAt
    }
}

struct PostGeolocationDTO: Decodable {
    let longitude: Double?
    let latitude: Double?
}

struct PostCreatorDTO: Decodable {
    let userId: String?
    let nick: String?
    let introduction: String?
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case introduction
        case profileImage
    }
}

struct PostCommentDTO: Decodable {
    let commentId: String?
    let content: String?
    let createdAt: String?
    let creator: PostCreatorDTO?
    let replies: [PostCommentReplyDTO]?

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case createdAt
        case creator
        case replies
    }
}

struct PostCommentReplyDTO: Decodable {
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
