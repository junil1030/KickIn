//  UserPostUIModel.swift
//  KickIn
//  Created by 서준일 on 01/22/26

import Foundation

struct UserPostUIModel: Identifiable {
    let id: String
    let title: String
    let content: String
    let category: String?
    let files: [String]
    let isLike: Bool
    let likeCount: Int
    let createdAt: String
}

// MARK: - Mapping to UserPostUIModel
extension PostListItemDTO {
    func toUserPostUIModel() -> UserPostUIModel? {
        guard let id = postId,
              let title = title,
              let content = content,
              let createdAt = createdAt else {
            return nil
        }

        return UserPostUIModel(
            id: id,
            title: title,
            content: content,
            category: category,
            files: files ?? [],
            isLike: isLike ?? false,
            likeCount: likeCount ?? 0,
            createdAt: createdAt
        )
    }
}
