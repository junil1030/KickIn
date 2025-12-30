//
//  SimilarEstateUIModel.swift
//  KickIn
//
//  Created by 서준일 on 12/29/25.
//

import Foundation

struct SimilarEstateUIModel {
    let estateId: String?
    let category: String?
    let title: String?
    let introduction: String?
    let thumbnails: [String]?
    let deposit: Int?
    let monthlyRent: Int?
    let area: Double?
    let likeCount: Int?
    let longitude: Double?
    let latitude: Double?
}

extension SimilarEstateItemDTO {
    func toUIModel() -> SimilarEstateUIModel {
        return SimilarEstateUIModel(
            estateId: self.estateId,
            category: self.category,
            title: self.title,
            introduction: self.introduction,
            thumbnails: self.thumbnails,
            deposit: self.deposit,
            monthlyRent: self.monthlyRent,
            area: self.area,
            likeCount: self.likeCount,
            longitude: self.geolocation?.longitude,
            latitude: self.geolocation?.latitude
        )
    }
}
