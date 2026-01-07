//
//  PaymentOrderInfo.swift
//  KickIn
//
//  Created by 서준일 on 1/7/26.
//

import Foundation

struct PaymentOrderInfo: Identifiable {
    let id = UUID()
    let title: String
    let buyerName: String
    let orderCode: String
    let amount: Int
}
