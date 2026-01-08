//
//  BannerResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import Foundation

struct BannerResponseDTO: Decodable {
    let data: [BannerItemDTO]?
}

struct BannerItemDTO: Decodable {
    let name: String?
    let imageUrl: String?
    let payload: BannerPayloadDTO?
}

struct BannerPayloadDTO: Decodable {
    let type: BannerPayloadType?
    let value: String?
}

enum BannerPayloadType: String, Decodable {
    case webview = "WEBVIEW"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = BannerPayloadType(rawValue: rawValue) ?? .unknown
    }
}
