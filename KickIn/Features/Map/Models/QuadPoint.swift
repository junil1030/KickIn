//
//  QuadPoint.swift
//  KickIn
//
//  Created by 서준일 on 1/9/26.
//

import CoreLocation

/// 클러스터링에 사용될 쿼드 트리의 포인트
struct QuadPoint {
    // 매물 id로 indexing
    let id: String
    let coordinate: CLLocationCoordinate2D
    let mapPoint: MapPoint? // For marker rendering

    var latitude: Double { coordinate.latitude }
    var longitude: Double { coordinate.longitude }
}
