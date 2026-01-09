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
