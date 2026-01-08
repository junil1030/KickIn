//
//  VideoStreamResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import Foundation

struct VideoStreamResponseDTO: Decodable {
    let videoId: String?
    let streamUrl: String?
    let qualities: [VideoStreamQualityDTO]?
    let subtitles: [VideoStreamSubtitleDTO]?

    enum CodingKeys: String, CodingKey {
        case videoId = "video_id"
        case streamUrl = "stream_url"
        case qualities
        case subtitles
    }
}

struct VideoStreamQualityDTO: Decodable {
    let quality: String?
    let url: String?
}

struct VideoStreamSubtitleDTO: Decodable {
    let language: String?
    let name: String?
    let isDefault: Bool?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case language
        case name
        case isDefault = "is_default"
        case url
    }
}
