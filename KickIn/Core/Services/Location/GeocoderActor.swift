//
//  GeocoderActor.swift
//  KickIn
//
//  Created by 서준일 on 12/23/25.
//

import CoreLocation

actor GeocoderActor {
    
    private let geocoder = CLGeocoder()
    
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> CLPlacemark? {

        let location = CLLocation(latitude: latitude, longitude: longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        return placemarks.first
    }
}
