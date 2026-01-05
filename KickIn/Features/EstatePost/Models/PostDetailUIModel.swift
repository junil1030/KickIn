//
//  PostDetailUIModel.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation

struct PostDetailUIModel: Identifiable {
    let id: String
    let category: String
    let title: String
    let content: String
    let authorId: String
    let authorName: String
    let authorIntroduction: String
    let authorProfileImage: String?
    let files: [String]
    let isLike: Bool
    let likeCount: Int
    let comments: [PostCommentUIModel]
    let createdAt: String
    let updatedAt: String
}

struct PostCommentUIModel: Identifiable {
    let id: String
    let content: String
    let createdAt: String
    let authorId: String
    let authorName: String
    let authorIntroduction: String
    let authorProfileImage: String?
    let replies: [PostCommentReplyUIModel]
}

struct PostCommentReplyUIModel: Identifiable {
    let id: String
    let content: String
    let createdAt: String
    let authorId: String
    let authorName: String
    let authorIntroduction: String
    let authorProfileImage: String?
}

extension PostResponseDTO {
    func toPostDetailUIModel() -> PostDetailUIModel {
        PostDetailUIModel(
            id: postId ?? UUID().uuidString,
            category: category ?? "",
            title: title ?? "",
            content: content ?? "",
            authorId: creator?.userId ?? "",
            authorName: creator?.nick ?? "익명",
            authorIntroduction: creator?.introduction ?? "",
            authorProfileImage: creator?.profileImage,
            files: files ?? [],
            isLike: isLike ?? false,
            likeCount: likeCount ?? 0,
            comments: comments?.map { $0.toPostCommentUIModel() } ?? [],
            createdAt: createdAt ?? "",
            updatedAt: updatedAt ?? ""
        )
    }
}

extension PostCommentDTO {
    func toPostCommentUIModel() -> PostCommentUIModel {
        PostCommentUIModel(
            id: commentId ?? UUID().uuidString,
            content: content ?? "",
            createdAt: createdAt ?? "",
            authorId: creator?.userId ?? "",
            authorName: creator?.nick ?? "익명",
            authorIntroduction: creator?.introduction ?? "",
            authorProfileImage: creator?.profileImage,
            replies: replies?.map { $0.toPostCommentReplyUIModel() } ?? []
        )
    }
}

extension PostCommentReplyDTO {
    func toPostCommentReplyUIModel() -> PostCommentReplyUIModel {
        PostCommentReplyUIModel(
            id: commentId ?? UUID().uuidString,
            content: content ?? "",
            createdAt: createdAt ?? "",
            authorId: creator?.userId ?? "",
            authorName: creator?.nick ?? "익명",
            authorIntroduction: creator?.introduction ?? "",
            authorProfileImage: creator?.profileImage
        )
    }
}
