//
//  CreateOrderRequestDTO.swift
//  KickIn
//
//  Created by 서준일 on 01/07/26.
//

import Foundation

struct CreateOrderRequestDTO: Encodable {
    let estateId: String
    let totalPrice: Int

    enum CodingKeys: String, CodingKey {
        case estateId = "estate_id"
        case totalPrice = "total_price"
    }
}
