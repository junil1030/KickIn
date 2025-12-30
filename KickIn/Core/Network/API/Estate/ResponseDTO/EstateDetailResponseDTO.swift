//
//  EstateDetailResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct EstateDetailResponseDTO: Decodable {
    let estateId: String?
    let category: String?
    let title: String?
    let introduction: String?
    let reservationPrice: Int?
    let thumbnails: [String]?
    let description: String?
    let deposit: Int?
    let monthlyRent: Int?
    let builtYear: String?
    let maintenanceFee: Int?
    let area: Double?
    let parkingCount: Int?
    let floors: Int?
    let options: EstateOptionsDTO?
    let geolocation: GeolocationDTO?
    let creator: EstateCreatorDTO?
    let isLiked: Bool?
    let isReserved: Bool?
    let likeCount: Int?
    let isSafeEstate: Bool?
    let isRecommended: Bool?
    let comments: [EstateCommentDTO]?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case estateId = "estate_id"
        case category
        case title
        case introduction
        case reservationPrice = "reservation_price"
        case thumbnails
        case description
        case deposit
        case monthlyRent = "monthly_rent"
        case builtYear = "built_year"
        case maintenanceFee = "maintenance_fee"
        case area
        case parkingCount = "parking_count"
        case floors
        case options
        case geolocation
        case creator
        case isLiked = "is_liked"
        case isReserved = "is_reserved"
        case likeCount = "like_count"
        case isSafeEstate = "is_safe_estate"
        case isRecommended = "is_recommended"
        case comments
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct EstateOptionsDTO: Decodable {
    let option1: String?
    let option2: String?
    let option3: String?
    let option4: String?
    let option5: String?
    let option6: String?
    let option7: String?
    let option8: String?
    let option9: String?
    let option10: String?
}

struct GeolocationDTO: Decodable {
    let longitude: Double?
    let latitude: Double?
}

struct EstateCreatorDTO: Decodable {
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

struct EstateCommentDTO: Decodable {
    let commentId: String?
    let content: String?
    let createdAt: String?
    let creator: EstateCreatorDTO?
    let replies: [EstateCommentDTO]?

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case createdAt = "created_at"
        case creator
        case replies
    }
}
