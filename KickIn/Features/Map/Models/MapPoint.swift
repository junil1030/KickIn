//
//  MapPoint.swift
//  KickIn
//
//  Created by 서준일 on 1/9/26.
//

import CoreLocation

/// 지도에 표시할 맵 포인트
struct MapPoint {
    let title: String
    let category: String
    let deposit: Int
    let monthly_rent: Int
    let area: Double
    let floors: Int
    let imageURL: String
    let longitude: Double
    let latitude: Double
}

// MARK: - InterestUIModel Conversion
extension MapPoint {
    /// MapPoint를 InterestUIModel로 변환
    /// - Parameter id: 매물 ID (QuadPoint.id)
    /// - Returns: InterestUIModel
    func toInterestUIModel(id: String) -> InterestUIModel {
        InterestUIModel(
            id: id,
            title: title,
            thumbnailURL: imageURL.isEmpty ? nil : imageURL,
            deposit: deposit,
            monthlyRent: monthly_rent,
            area: area,
            builtYear: nil, // MapPoint에 없는 정보
            floors: floors,
            longitude: longitude,
            latitude: latitude
        )
    }
}
