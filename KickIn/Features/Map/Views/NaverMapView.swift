//
//  NaverMapView.swift
//  KickIn
//
//  Created by 서준일 on 1/9/26.
//

import SwiftUI
import NMapsMap
import CoreLocation

struct NaverMapView: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel

    func makeUIView(context: Context) -> NMFNaverMapView {
        let mapView = NMFNaverMapView()

        // Set delegate to coordinator
        mapView.mapView.addCameraDelegate(delegate: context.coordinator)

        // Set initial camera position if available
        if let initialLocation = viewModel.initialLocation {
            let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(
                lat: initialLocation.latitude,
                lng: initialLocation.longitude
            ))
            cameraUpdate.animation = .easeIn
            mapView.mapView.moveCamera(cameraUpdate)
        }

        return mapView
    }

    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        // Update initial location if changed and not yet set
        if let initialLocation = viewModel.initialLocation,
           !context.coordinator.hasSetInitialLocation {
            let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(
                lat: initialLocation.latitude,
                lng: initialLocation.longitude
            ))
            cameraUpdate.animation = .easeIn
            cameraUpdate.animationDuration = 1.0
            uiView.mapView.moveCamera(cameraUpdate)
            context.coordinator.hasSetInitialLocation = true
        }

        // Handle move to location button tap
        if viewModel.shouldMoveToLocation != context.coordinator.lastMoveToLocationTrigger,
           let initialLocation = viewModel.initialLocation {
            let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(
                lat: initialLocation.latitude,
                lng: initialLocation.longitude
            ))
            cameraUpdate.animation = .easeIn
            cameraUpdate.animationDuration = 0.5
            uiView.mapView.moveCamera(cameraUpdate)
            context.coordinator.lastMoveToLocationTrigger = viewModel.shouldMoveToLocation
        }

        context.coordinator.updateClusters(viewModel.clusters, on: uiView.mapView)
        context.coordinator.updateNoiseMarkers(viewModel.noisePoints, on: uiView.mapView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, NMFMapViewCameraDelegate {
        private let viewModel: MapViewModel
        private var clusterMarkers: [NMFMarker] = []
        private var noiseMarkers: [NMFMarker] = []
        private var markerPriceMap: [String: [NMFMarker]] = [:] // priceText -> markers
        var hasSetInitialLocation = false
        var lastMoveToLocationTrigger = false

        init(viewModel: MapViewModel) {
            self.viewModel = viewModel
            super.init()

            // Listen for marker image load notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleMarkerImageDidLoad(_:)),
                name: .markerImageDidLoad,
                object: nil
            )
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        func updateClusters(_ clusters: [ClusterCenter], on mapView: NMFMapView) {
            clusterMarkers.forEach { $0.mapView = nil }
            clusterMarkers = clusters.map { cluster in
                let marker = NMFMarker()
                marker.position = NMGLatLng(
                    lat: cluster.coordinate.latitude,
                    lng: cluster.coordinate.longitude
                )

                // Use cached custom cluster image
                let clusterImage = MarkerImageCache.shared.clusterImage(count: cluster.pointCount)
                marker.iconImage = NMFOverlayImage(image: clusterImage)

                // Set anchor to center to prevent clipping
                marker.anchor = CGPoint(x: 0.5, y: 0.5)

                marker.mapView = mapView
                return marker
            }
        }

        func updateNoiseMarkers(_ noisePoints: [QuadPoint], on mapView: NMFMapView) {
            // 기존 노이즈 마커 제거
            noiseMarkers.forEach { $0.mapView = nil }
            markerPriceMap.removeAll()

            // 새로운 노이즈 마커 생성 (개별 마커로 표시)
            noiseMarkers = noisePoints.compactMap { point in
                // Use MapPoint reference (added in QuadPoint)
                guard let mapPoint = point.mapPoint else { return nil }

                let marker = NMFMarker()
                marker.position = NMGLatLng(
                    lat: point.coordinate.latitude,
                    lng: point.coordinate.longitude
                )

                // Format price
                let priceText = PriceFormatter.formatForMarker(
                    deposit: mapPoint.deposit,
                    monthlyRent: mapPoint.monthly_rent
                )

                // Use cached custom estate image
                let estateImage = MarkerImageCache.shared.estateImage(
                    priceText: priceText,
                    imageURL: mapPoint.imageURL
                )
                marker.iconImage = NMFOverlayImage(image: estateImage)

                // Set anchor to center to prevent clipping
                marker.anchor = CGPoint(x: 0.5, y: 0.5)

                marker.mapView = mapView

                // Track marker by price for later updates
                if markerPriceMap[priceText] == nil {
                    markerPriceMap[priceText] = []
                }
                markerPriceMap[priceText]?.append(marker)

                return marker
            }
        }

        // Handle marker image loaded notification
        @objc private func handleMarkerImageDidLoad(_ notification: Notification) {
            guard let priceText = notification.userInfo?["priceText"] as? String,
                  let markers = markerPriceMap[priceText] else {
                return
            }

            // Update markers with newly loaded image on main thread
            Task { @MainActor in
                let updatedImage = MarkerImageCache.shared.estateImage(
                    priceText: priceText,
                    imageURL: nil // Already cached, will return cached image
                )

                for marker in markers {
                    marker.iconImage = NMFOverlayImage(image: updatedImage)
                }
            }
        }

        // Called when camera movement ends
        func mapView(_ mapView: NMFMapView, cameraDidChangeByReason reason: Int, animated: Bool) {
            // Get current camera position
            let cameraPosition = mapView.cameraPosition
            let center = cameraPosition.target

            // Get visible bounds
            let bounds = mapView.coveringBounds
            let southWest = bounds.southWest
            let northEast = bounds.northEast

            // Notify ViewModel
            viewModel.handleCameraChange(
                center: CLLocationCoordinate2D(latitude: center.lat, longitude: center.lng),
                southWest: CLLocationCoordinate2D(latitude: southWest.lat, longitude: southWest.lng),
                northEast: CLLocationCoordinate2D(latitude: northEast.lat, longitude: northEast.lng),
                reason: reason
            )
        }
    }
}

#Preview {
    NaverMapView(viewModel: MapViewModel())
}
