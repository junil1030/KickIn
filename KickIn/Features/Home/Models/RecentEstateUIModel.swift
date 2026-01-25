//
//  RecentEstateUIModel.swift
//  KickIn
//
//  Created by 서준일 on 01/24/26.
//

import Foundation

struct RecentEstateUIModel: Identifiable {
    let id: String
    let estateId: String
    let category: String?
    let deposit: Int?
    let monthlyRent: Int?
    let latitude: Double?
    let longitude: Double?
    let area: Double?
    let thumbnailURL: String?

    init(estateId: String, category: String?, deposit: Int?,
         monthlyRent: Int?, latitude: Double?, longitude: Double?,
         area: Double?, thumbnailURL: String?) {
        self.id = estateId
        self.estateId = estateId
        self.category = category
        self.deposit = deposit
        self.monthlyRent = monthlyRent
        self.latitude = latitude
        self.longitude = longitude
        self.area = area
        self.thumbnailURL = thumbnailURL
    }
}
