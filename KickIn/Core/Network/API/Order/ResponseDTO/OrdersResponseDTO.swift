//
//  OrdersResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 01/07/26.
//

import Foundation

struct OrdersResponseDTO: Decodable {
    let data: [OrderItemDTO]?
}

struct OrderItemDTO: Decodable {
    let orderId: String?
    let orderCode: String?
    let estate: OrderEstateDTO?
    let paidAt: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case orderCode = "order_code"
        case estate
        case paidAt
        case createdAt
        case updatedAt
    }
}

struct OrderEstateDTO: Decodable {
    let id: String?
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
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
