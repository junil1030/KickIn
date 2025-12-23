//
//  GeocodeServiceProtocol.swift
//  KickIn
//
//  Created by 서준일 on 12/22/25.
//

import Foundation
import CoreLocation

/// 좌표를 주소로 변환하는 서비스 프로토콜
protocol GeocodeServiceProtocol {
    /// 위도/경도를 받아 지역과 동 정보를 반환
    /// - Parameters:
    ///   - latitude: 위도
    ///   - longitude: 경도
    /// - Returns: (지역, 동) 튜플 (예: ("서울특별시 강남구", "역삼동"))
    func getAddress(latitude: Double?, longitude: Double?) async -> (locality: String?, subLocality: String?)

    /// 위도/경도를 받아 주소 문자열을 반환
    /// - Parameters:
    ///   - latitude: 위도
    ///   - longitude: 경도
    /// - Returns: 주소 문자열 (예: "서울특별시 강남구 역삼동")
    func getLocationString(latitude: Double?, longitude: Double?) async -> String
}
