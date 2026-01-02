//
//  EstatePostUIModel.swift
//  KickIn
//
//  Created by 서준일 on 01/02/26.
//

import Foundation

struct EstatePostUIModel: Identifiable {
    let id: String
    let title: String
    let authorName: String
    let authorProfileImage: String?
    let content: String
    let likeCount: Int
    let createdAt: String
}

extension PostListItemDTO {
    func toEstatePostUIModel() -> EstatePostUIModel {
        EstatePostUIModel(
            id: postId ?? UUID().uuidString,
            title: title ?? "",
            authorName: creator?.nick ?? "익명",
            authorProfileImage: creator?.profileImage,
            content: content ?? "",
            likeCount: likeCount ?? 0,
            createdAt: createdAt ?? ""
        )
    }
}
