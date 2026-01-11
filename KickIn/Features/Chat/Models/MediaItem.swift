//
//  MediaItem.swift
//  KickIn
//
//  Created by 서준일 on 01/11/26
//

import Foundation

enum MediaType: String, Codable {
    case image
    case video  // Future: 영상 지원
}

struct MediaItem: Identifiable, Codable, Hashable {
    let id: String  // chatId or unique identifier
    let type: MediaType
    let url: String
    let thumbnailURL: String?
    let createdAt: String
    var roomId: String

    // Future: 영상 메타데이터
    var duration: TimeInterval?  // 영상 길이
    var size: Int64?  // 파일 크기
}

// MARK: - Helper Extensions

extension String {
    var mediaType: MediaType {
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v"]
        let ext = (self as NSString).pathExtension.lowercased()
        return videoExtensions.contains(ext) ? .video : .image
    }
}
