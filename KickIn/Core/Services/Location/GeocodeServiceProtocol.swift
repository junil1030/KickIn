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
    /// 위도/경도를 받아 간단한 지역 정보를 반환
    /// - Parameters:
    ///   - latitude: 위도
    ///   - longitude: 경도
    /// - Returns: (지역, 동) 튜플 (예: ("서울특별시 강남구", "역삼동"))
    func getSimpleAddress(latitude: Double?, longitude: Double?) async -> (locality: String?, subLocality: String?)

    /// 위도/경도를 받아 간단한 주소 문자열을 반환
    /// - Parameters:
    ///   - latitude: 위도
    ///   - longitude: 경도
    /// - Returns: 주소 문자열 (예: "서울특별시 강남구 역삼동")
    func getSimpleLocationString(latitude: Double?, longitude: Double?) async -> String

    /// 위도/경도를 받아 상세 주소 정보를 반환
    /// - Parameters:
    ///   - latitude: 위도
    ///   - longitude: 경도
    /// - Returns: (시/도, 시/군/구, 도로명, 번지) 튜플 (예: ("서울", "영등포구", "선유로9길", "30"))
    func getDetailedAddress(latitude: Double?, longitude: Double?) async -> (administrativeArea: String?, locality: String?, thoroughfare: String?, subThoroughfare: String?)

    /// 위도/경도를 받아 상세 주소 문자열을 반환
    /// - Parameters:
    ///   - latitude: 위도
    ///   - longitude: 경도
    /// - Returns: 주소 문자열 (예: "서울 영등포구 선유로9길 30")
    func getDetailedLocationString(latitude: Double?, longitude: Double?) async -> String
}
