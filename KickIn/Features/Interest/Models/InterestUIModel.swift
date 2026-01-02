//
//  InterestUIModel.swift
//  KickIn
//
//  Created by 서준일 on 12/30/25.
//

import Foundation

struct InterestUIModel: Identifiable, Hashable {
    let id: String
    let title: String
    let thumbnailURL: String?
    let deposit: Int
    let monthlyRent: Int
    let area: Double?
    let builtYear: String?
    let floors: Int?
    let longitude: Double?
    let latitude: Double?

    init(
        id: String,
        title: String,
        thumbnailURL: String?,
        deposit: Int,
        monthlyRent: Int,
        area: Double?,
        builtYear: String?,
        floors: Int?,
        longitude: Double?,
        latitude: Double?
    ) {
        self.id = id
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.deposit = deposit
        self.monthlyRent = monthlyRent
        self.area = area
        self.builtYear = builtYear
        self.floors = floors
        self.longitude = longitude
        self.latitude = latitude
    }
}

extension EstateLikeItemDTO {
    func toUIModel() -> InterestUIModel {
        InterestUIModel(
            id: estateId ?? "",
            title: title ?? "",
            thumbnailURL: thumbnails?.first,
            deposit: deposit ?? 0,
            monthlyRent: monthlyRent ?? 0,
            area: area,
            builtYear: builtYear,
            floors: floors,
            longitude: geolocation?.longitude,
            latitude: geolocation?.latitude
        )
    }
}
