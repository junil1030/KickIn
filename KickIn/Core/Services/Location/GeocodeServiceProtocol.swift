//
//  GeocodeServiceProtocol.swift
//  KickIn
//
//  Created by 서준일 on 12/22/25.
//

import Foundation
import CoreLocation

private let sharedGeocoder = CLGeocoder()

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

extension GeocodeServiceProtocol {
    func getAddress(latitude: Double?, longitude: Double?) async -> (locality: String?, subLocality: String?) {
        guard let latitude = latitude, let longitude = longitude else { return (nil, nil) }
        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            let placemarks = try await sharedGeocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                return (nil, nil)
            }

            return (placemark.locality, placemark.subLocality)
        } catch {
            print("Reverse geocoding failed: \(error.localizedDescription)")
            return (nil, nil)
        }
    }

    func getLocationString(latitude: Double?, longitude: Double?) async -> String {
        guard let latitude = latitude, let longitude = longitude else { return "위치 정보 없음" }
        let (locality, subLocality) = await getAddress(latitude: latitude, longitude: longitude)

        var components: [String] = []

        if let locality = locality {
            components.append(locality)
        }

        if let subLocality = subLocality {
            components.append(subLocality)
        }

        return components.isEmpty ? "위치 정보 없음" : components.joined(separator: " ")
    }
}
