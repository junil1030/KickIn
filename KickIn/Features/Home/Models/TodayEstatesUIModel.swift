//
//  TodayEstatesUIModel.swift
//  KickIn
//
//  Created by 서준일 on 12/21/25.
//

import Foundation

struct TodayEstateUIModel {
    let estateId: String?
    let category: String?
    let title: String?
    let introduction: String?
    let thumbnails: [String]?
    let longitude: Double?
    let latitude: Double?
}

extension TodayEstateItemDTO {
    func toUIModel() -> TodayEstateUIModel {
        return TodayEstateUIModel(
            estateId: self.estateId,
            category: self.category,
            title: self.title,
            introduction: self.introduction,
            thumbnails: self.thumbnails,
            longitude: self.geolocation?.longitude,
            latitude: self.geolocation?.latitude
        )
    }
}
