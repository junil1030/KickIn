//
//  MediaItem.swift
//  KickIn
//
//  Created by 서준일 on 01/11/26
//

import Foundation

enum MediaType: String, Codable {
    case image
    case video
    case pdf
}

struct MediaItem: Identifiable, Codable, Hashable {
    let id: String  // chatId or unique identifier
    let type: MediaType
    let url: String
    let thumbnailURL: String?
    let createdAt: String
    var roomId: String

    // 영상 메타데이터
    var duration: TimeInterval?  // 영상 길이
    var size: Int64?  // 파일 크기

    // PDF 전용 메타데이터
    var fileName: String?
    var fileSize: Int64?
}

// MARK: - Helper Extensions

extension String {
    var mediaType: MediaType {
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v"]
        let pdfExtensions = ["pdf"]
        let ext = (self as NSString).pathExtension.lowercased()

        if pdfExtensions.contains(ext) {
            return .pdf
        } else if videoExtensions.contains(ext) {
            return .video
        } else {
            return .image
        }
    }

    /// 비디오 URL에서 썸네일 URL 생성
    func toThumbnailURL() -> String {
        VideoUploadService.getThumbnailURL(from: self)
    }
}
