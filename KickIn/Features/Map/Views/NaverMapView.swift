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

    func updateUIView(_ uiView: NMFNaverMapView, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, NMFMapViewCameraDelegate {
        private let viewModel: MapViewModel

        init(viewModel: MapViewModel) {
            self.viewModel = viewModel
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
