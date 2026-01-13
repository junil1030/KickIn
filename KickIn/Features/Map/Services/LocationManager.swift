//
//  LocationManager.swift
//  KickIn
//
//  Created by 서준일 on 01/13/26.
//

import Foundation
import CoreLocation
import Combine
import OSLog

final class LocationManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Private Properties
    private let locationManager = CLLocationManager()

    // MARK: - Initialization
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Public Methods

    /// Request location permission
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Start updating location
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    /// Stop updating location
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        currentLocation = location.coordinate
        Logger().info("📍 Current location: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        // Stop updating after getting first location
        stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger().error("❌ Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            Logger().info("✅ Location permission granted")
            startUpdatingLocation()
        case .denied, .restricted:
            Logger().warning("⚠️ Location permission denied")
        case .notDetermined:
            Logger().info("❓ Location permission not determined")
        @unknown default:
            break
        }
    }
}
