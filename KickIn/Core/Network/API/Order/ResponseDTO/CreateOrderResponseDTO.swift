//
//  CreateOrderResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 01/07/26.
//

import Foundation

struct CreateOrderResponseDTO: Decodable {
    let orderId: String?
    let orderCode: String?
    let totalPrice: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case orderCode = "order_code"
        case totalPrice = "total_price"
        case createdAt
        case updatedAt
    }
}
