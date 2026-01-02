//
//  GeocodeService.swift
//  KickIn
//
//  Created by 서준일 on 12/23/25.
//

import CoreLocation
import OSLog

final class GeocodeService: GeocodeServiceProtocol {
    
    private let geocoderActor: GeocoderActor
    
    init(geocoderActor: GeocoderActor = GeocoderActor()) {
        self.geocoderActor = geocoderActor
    }

    // MARK: - Simple Address Methods

    func getSimpleAddress(latitude: Double?, longitude: Double?) async -> (locality: String?, subLocality: String?) {
        guard let latitude, let longitude else { return (nil, nil) }
        
        do {
            let placemark = try await geocoderActor.reverseGeocode(latitude: latitude, longitude: longitude)
            
            return (placemark?.locality, placemark?.subLocality)
        } catch {
            Logger.default.error("Reverse geocoding failed: \(error.localizedDescription)")
            return (nil, nil)
        }
    }

    func getSimpleLocationString(latitude: Double?, longitude: Double?) async -> String {
        let (locality, subLocality) = await getSimpleAddress(latitude: latitude, longitude: longitude)

        var components: [String] = []
        
        if let locality { components.append(locality) }
        if let subLocality { components.append(subLocality) }
        
        return components.isEmpty ? "위치 정보 없음" : components.joined(separator: " ")
    }
    
    // MARK: - Detailed Address Methods
    
    func getDetailedAddress(latitude: Double?, longitude: Double?) async -> (administrativeArea: String?, locality: String?, thoroughfare: String?, subThoroughfare: String?) {
        guard let latitude, let longitude else { return (nil, nil, nil, nil) }
        
        do {
            let placemark = try await geocoderActor.reverseGeocode(latitude: latitude, longitude: longitude)
            
            return (
                placemark?.administrativeArea,
                placemark?.locality,
                placemark?.thoroughfare,
                placemark?.subThoroughfare
            )
        } catch {
            Logger.default.error("Reverse geocoding failed: \(error.localizedDescription)")
            return (nil, nil, nil, nil)
        }
    }
    
    func getDetailedLocationString(latitude: Double?, longitude: Double?) async -> String {
        let (administrativeArea, locality, thoroughfare, subThoroughfare) = await getDetailedAddress(latitude: latitude, longitude: longitude)

        var components: [String] = []
        
//        if let administrativeArea { components.append(administrativeArea) }
        if let locality { components.append(locality) }
        if let thoroughfare { components.append(thoroughfare) }
        if let subThoroughfare { components.append(subThoroughfare) }
        
        return components.isEmpty ? "위치 정보 없음" : components.joined(separator: " ")
    }
}
