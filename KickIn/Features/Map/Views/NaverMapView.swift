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

        return mapView
    }

    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
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

        init(viewModel: MapViewModel) {
            self.viewModel = viewModel
        }

        func updateClusters(_ clusters: [ClusterCenter], on mapView: NMFMapView) {
            clusterMarkers.forEach { $0.mapView = nil }
            clusterMarkers = clusters.map { cluster in
                let marker = NMFMarker()
                marker.position = NMGLatLng(lat: cluster.coordinate.latitude, lng: cluster.coordinate.longitude)
                marker.captionText = "\(cluster.pointCount)"
                marker.captionMinZoom = 0
                marker.mapView = mapView
                return marker
            }
        }

        func updateNoiseMarkers(_ noisePoints: [QuadPoint], on mapView: NMFMapView) {
            // 기존 노이즈 마커 제거
            noiseMarkers.forEach { $0.mapView = nil }

            // 새로운 노이즈 마커 생성 (개별 마커로 표시)
            noiseMarkers = noisePoints.map { point in
                let marker = NMFMarker()
                marker.position = NMGLatLng(lat: point.coordinate.latitude, lng: point.coordinate.longitude)
                // 기본 마커 사용 (클러스터와 구별되도록)
                marker.iconTintColor = UIColor.systemBlue
                marker.mapView = mapView
                return marker
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
