//
//  EstateLikesResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct EstateLikesResponseDTO: Decodable {
    let data: [EstateLikeItemDTO]?
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}

struct EstateLikeItemDTO: Decodable {
    let estateId: String?
    let category: String?
    let title: String?
    let introduction: String?
    let thumbnails: [String]?
    let deposit: Int?
    let monthlyRent: Int?
    let builtYear: String?
    let area: Double?
    let floors: Int?
    let geolocation: GeolocationDTO?
    let distance: Double?
    let likeCount: Int?
    let isSafeEstate: Bool?
    let isRecommended: Bool?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case estateId = "estate_id"
        case category
        case title
        case introduction
        case thumbnails
        case deposit
        case monthlyRent = "monthly_rent"
        case builtYear = "built_year"
        case area
        case floors
        case geolocation
        case distance
        case likeCount = "like_count"
        case isSafeEstate = "is_safe_estate"
        case isRecommended = "is_recommended"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
