//
//  VideoUIModel.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import Foundation

struct VideoUIModel {
    let videoId: String?
    let title: String?
    let thumbnailUrl: String?
    let duration: Double?
    let isLiked: Bool?
    let viewCount: Int?
}

extension VideoItemDTO {
    func toUIModel() -> VideoUIModel {
        return VideoUIModel(
            videoId: self.videoId,
            title: self.title,
            thumbnailUrl: self.thumbnailUrl,
            duration: self.duration,
            isLiked: self.isLiked,
            viewCount: self.viewCount
        )
    }
}
