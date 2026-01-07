//
//  PaymentValidationRequestDTO.swift
//  KickIn
//
//  Created by 서준일 on 01/07/26.
//

import Foundation

struct PaymentValidationRequestDTO: Encodable {
    let impUid: String

    enum CodingKeys: String, CodingKey {
        case impUid = "imp_uid"
    }
}
