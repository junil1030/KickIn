//
//  PaymentValidationResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 01/07/26.
//

import Foundation

struct PaymentValidationResponseDTO: Decodable {
    let paymentId: String?
    let orderItem: OrderItemDTO?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case paymentId = "payment_id"
        case orderItem = "order_item"
        case createdAt
        case updatedAt
    }
}
