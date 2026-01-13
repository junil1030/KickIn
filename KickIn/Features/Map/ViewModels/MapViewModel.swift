//
//  MapViewModel.swift
//  KickIn
//
//  Created by 서준일 on 01/09/26.
//

import Foundation
import Combine
import CoreLocation
import OSLog

final class MapViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var mapPoints: [MapPoint] = []
    @Published var quadPoints: [QuadPoint] = []
    @Published var clusters: [ClusterCenter] = []
    @Published var noisePoints: [QuadPoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var initialLocation: CLLocationCoordinate2D?
    @Published var shouldMoveToLocation = false

    // MARK: - Private Properties
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    private let clusteringService: ClusteringServiceProtocol
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()

    // Combine subject for camera changes (user-initiated only)
    private let cameraChangeSubject = PassthroughSubject<CameraChangeEvent, Never>()

    // MARK: - Initialization
    init(clusteringService: ClusteringServiceProtocol = ClusteringService()) {
        self.clusteringService = clusteringService
        setupDebounce()
        setupLocationObserver()
        requestLocationPermission()
    }

    // MARK: - Setup
    private func setupDebounce() {
        cameraChangeSubject
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.fetchNearbyEstates(event: event)
                }
            }
            .store(in: &cancellables)
    }

    private func setupLocationObserver() {
        locationManager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.initialLocation = location
                Logger.ui.info("📍 Initial location set: \(location.latitude), \(location.longitude)")
            }
            .store(in: &cancellables)
    }

    private func requestLocationPermission() {
        locationManager.requestPermission()
    }

    // MARK: - Public Methods

    /// Move camera to current location
    func moveToCurrentLocation() {
        if let location = locationManager.currentLocation {
            initialLocation = location
            shouldMoveToLocation.toggle()
            Logger.ui.info("📍 Moving to current location: \(location.latitude), \(location.longitude)")
        } else {
            // Request location if not available
            locationManager.startUpdatingLocation()
        }
    }

    /// Called from NaverMapView when camera changes (only user-initiated)
    func handleCameraChange(center: CLLocationCoordinate2D,
                           southWest: CLLocationCoordinate2D,
                           northEast: CLLocationCoordinate2D,
                           reason: Int) {
        // Only process user-initiated camera changes (byReason == -1)
        guard reason == -1 else {
            Logger.ui.debug("🗺️ Camera change ignored (programmatic): reason=\(reason)")
            return
        }

        // Calculate radius using Haversine distance
        let maxDistance = calculateRadius(from: southWest, to: northEast)

        Logger.ui.info("""
        🗺️ Camera change detected:
           Center: (\(center.latitude), \(center.longitude))
           SW: (\(southWest.latitude), \(southWest.longitude))
           NE: (\(northEast.latitude), \(northEast.longitude))
           Max Distance: \(maxDistance)m
           Reason: \(reason)
        """)

        let event = CameraChangeEvent(
            center: center,
            maxDistance: maxDistance
        )

        // Send to debounce subject
        cameraChangeSubject.send(event)
    }

    // MARK: - Private Methods

    /// Fetch nearby estates from API
    private func fetchNearbyEstates(event: CameraChangeEvent) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let response: EstateGeolocationResponseDTO = try await networkService.request(
                EstateRouter.geolocation(
                    category: nil,
                    longitude: String(event.center.longitude),
                    latitude: String(event.center.latitude),
                    maxDistance: event.maxDistance
                )
            )

            let estates = response.data ?? []

            // Convert DTOs to MapPoint and QuadPoint
            let mapPoints = estates.compactMap { $0.toMapPoint() }
            let quadPoints = estates.compactMap { estate in
                let mapPoint = estate.toMapPoint()
                return estate.toQuadPoint(with: mapPoint)
            }

            // Perform clustering
            let clusterResult = await performClustering(points: quadPoints, maxDistance: event.maxDistance)

            await MainActor.run {
                self.mapPoints = mapPoints
                self.quadPoints = quadPoints
                self.clusters = clusterResult.clusterCenters()
                self.noisePoints = clusterResult.noise
                self.isLoading = false
            }

            Logger.network.info("""
            ✅ Geolocation API Success:
               Center: (\(event.center.latitude), \(event.center.longitude))
               Max Distance: \(event.maxDistance)m
               Results: \(estates.count) estates
               MapPoints: \(mapPoints.count), QuadPoints: \(quadPoints.count)
               Clusters: \(clusterResult.clusterCount), Noise: \(clusterResult.noise.count)
            """)

            // Log individual results for debugging
            if !estates.isEmpty {
                Logger.network.debug("📍 Estate details:")
                for estate in estates.prefix(5) {
                    if let estateId = estate.estateId,
                       let title = estate.title,
                       let distance = estate.distance {
                        Logger.network.debug("  - \(estateId): \(title) (\(Int(distance))m away)")
                    }
                }
                if estates.count > 5 {
                    Logger.network.debug("  ... and \(estates.count - 5) more")
                }
            }

        } catch let error as NetworkError {
            Logger.network.error("❌ Geolocation API Failed: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        } catch {
            Logger.network.error("❌ Unknown error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "주변 매물을 불러오는데 실패했습니다."
                self.isLoading = false
            }
        }
    }

    /// Calculate radius (half the diagonal distance between SW and NE corners)
    /// Uses Haversine formula for accurate distance on Earth's surface
    private func calculateRadius(from southWest: CLLocationCoordinate2D,
                                to northEast: CLLocationCoordinate2D) -> Int {
        let distance = haversineDistance(from: southWest, to: northEast)
        let radius = Int(distance / 2.0)
        return radius
    }

    /// Haversine formula to calculate distance between two coordinates in meters
    private func haversineDistance(from: CLLocationCoordinate2D,
                                   to: CLLocationCoordinate2D) -> Double {
        let earthRadius = 6371000.0 // meters

        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLat = (to.latitude - from.latitude) * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180

        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLon / 2) * sin(deltaLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }

    // MARK: - Clustering

    /// 클러스터링 수행 (줌 레벨 기반)
    /// - Parameters:
    ///   - points: 클러스터링할 QuadPoint 배열
    ///   - maxDistance: 지도 반경 (미터)
    /// - Returns: ClusterResult
    private func performClustering(points: [QuadPoint], maxDistance: Int) async -> ClusterResult {
        // 줌 레벨(반경)에 따른 적응형 epsilon과 minPoints
        let epsilon = calculateAdaptiveEpsilon(maxDistance: maxDistance)
        let minPoints = calculateAdaptiveMinPts(maxDistance: maxDistance)

        // ClusteringService를 통해 클러스터링 수행
        // 모든 줌 레벨에서 클러스터링을 수행하여:
        // - 밀집 지역: 클러스터로 표시
        // - 떨어진 점: 노이즈(개별 마커)로 표시
        return await clusteringService.cluster(
            points: points,
            epsilon: epsilon,
            minPoints: minPoints
        )
    }

    /// 줌 레벨(반경)에 따른 적응형 epsilon 계산
    /// - Parameter maxDistance: 지도 반경 (미터)
    /// - Returns: 적절한 epsilon 값 (미터)
    private func calculateAdaptiveEpsilon(maxDistance: Int) -> Double {
        // 줌 아웃할수록 (반경이 클수록) 큰 epsilon 사용 (넓은 범위 클러스터링)
        // 줌 인할수록 (반경이 작을수록) 작은 epsilon 사용 (세밀한 클러스터링)
        SpatialConstants.epsilon(forMaxDistance: maxDistance)
    }
    
    /// 줌 레벨(반경)에 따른 적응형 minPts 계산
    /// - Parameter maxDistance: 지도 반경 (미터)
    /// - Returns: 적절한 minPts 값 (미터)
    private func calculateAdaptiveMinPts(maxDistance: Int) -> Int {
        // 줌 아웃할수록 (반경이 클수록) 큰 epsilon 사용 (넓은 범위 클러스터링)
        // 줌 인할수록 (반경이 작을수록) 작은 epsilon 사용 (세밀한 클러스터링)
        SpatialConstants.minPoints(forMaxDistance: maxDistance)
    }
}

// MARK: - Camera Change Event
struct CameraChangeEvent {
    let center: CLLocationCoordinate2D
    let maxDistance: Int
}

// MARK: - DTO to Model Conversion
extension EstateLikeItemDTO {
    /// Convert DTO to MapPoint for map display
    func toMapPoint() -> MapPoint? {
        guard let longitude = geolocation?.longitude,
              let latitude = geolocation?.latitude,
              let title = title,
              let category = category else {
            return nil
        }

        return MapPoint(
            title: title,
            category: category,
            deposit: deposit ?? 0,
            monthly_rent: monthlyRent ?? 0,
            area: area ?? 0,
            floors: floors ?? 0,
            imageURL: thumbnails?.first ?? "",
            longitude: longitude,
            latitude: latitude
        )
    }

    /// Convert DTO to QuadPoint for clustering
    func toQuadPoint(with mapPoint: MapPoint?) -> QuadPoint? {
        guard let estateId = estateId,
              let longitude = geolocation?.longitude,
              let latitude = geolocation?.latitude else {
            return nil
        }

        return QuadPoint(
            id: estateId,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            mapPoint: mapPoint
        )
    }
}
