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

/// Consolidated map state for atomic updates
struct MapState {
    var mapPoints: [MapPoint] = []
    var quadPoints: [QuadPoint] = []
    var clusters: [ClusterCenter] = []
    var noisePoints: [QuadPoint] = []
    var isLoading = false
    var errorMessage: String?
    var selectedCluster: ClusterCenter? = nil
}

final class MapViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var state = MapState()
    @Published var initialLocation: CLLocationCoordinate2D?
    @Published var shouldMoveToLocation = false
    @Published var filterState: EstateFilter?

    // MARK: - Private Properties
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    private let clusteringManager: ClusteringStrategyManager
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()

    // Combine subject for camera changes (user-initiated only)
    private let cameraChangeSubject = PassthroughSubject<CameraChangeEvent, Never>()

    // 마지막으로 계산된 maxDistance (필터 적용 시 재사용)
    private var lastMaxDistance: Int = 5000  // 기본값 5km

    // 원본 데이터 저장 (클라이언트 사이드 필터링용)
    private var allMapPoints: [MapPoint] = []
    private var allQuadPoints: [QuadPoint] = []

    // MARK: - Initialization
    init(clusteringManager: ClusteringStrategyManager = ClusteringStrategyManager()) {
        self.clusteringManager = clusteringManager
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
            .receive(on: DispatchQueue.main)
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

    /// Select a cluster to show estate list
    func selectCluster(_ cluster: ClusterCenter?) {
        var newState = state
        newState.selectedCluster = cluster
        state = newState
    }

    /// Update filter and re-apply to cached data
    func updateFilter(_ filter: EstateFilter) {
        self.filterState = filter.isActive ? filter : nil

        // 원본 데이터가 있으면 필터링 + 클러스터링만 재적용 (API 호출 없음)
        if !allMapPoints.isEmpty {
            Task {
                await applyFilterAndCluster()
            }
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

        // 마지막 maxDistance 저장 (필터 적용 시 재사용)
        lastMaxDistance = maxDistance

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
        let pipelineStartTime = CFAbsoluteTimeGetCurrent()

        await MainActor.run {
            var loadingState = self.state
            loadingState.isLoading = true
            loadingState.errorMessage = nil
            self.state = loadingState
        }

        do {
            let apiRequestStartTime = CFAbsoluteTimeGetCurrent()
            let response: EstateGeolocationResponseDTO = try await networkService.request(
                EstateRouter.geolocation(
                    category: nil,
                    longitude: String(event.center.longitude),
                    latitude: String(event.center.latitude),
                    maxDistance: event.maxDistance
                )
            )
            let apiRequestTime = CFAbsoluteTimeGetCurrent() - apiRequestStartTime

            let estates = response.data ?? []

            // Convert DTOs to MapPoint and QuadPoint
            let mapPoints = estates.compactMap { $0.toMapPoint() }
            let quadPoints = estates.compactMap { estate in
                let mapPoint = estate.toMapPoint()
                return estate.toQuadPoint(with: mapPoint)
            }

            // 원본 데이터 저장 (클라이언트 사이드 필터링용)
            await MainActor.run {
                self.allMapPoints = mapPoints
                self.allQuadPoints = quadPoints
            }

            // 필터링 + 클러스터링 적용
            let (filteredMapPoints, filteredQuadPoints) = applyFilter(
                mapPoints: mapPoints,
                quadPoints: quadPoints,
                filter: filterState
            )

            // Perform clustering
            let clusterResult = await performClustering(points: filteredQuadPoints, maxDistance: event.maxDistance)

            // 마커 렌더링 시간 측정 시작
            let markerRenderStartTime = CFAbsoluteTimeGetCurrent()

            // Atomic state update: Single objectWillChange notification
            await MainActor.run {
                var newState = MapState()
                newState.mapPoints = filteredMapPoints
                newState.quadPoints = filteredQuadPoints
                newState.clusters = clusterResult.clusterCenters()
                newState.noisePoints = clusterResult.noise
                newState.isLoading = false
                newState.errorMessage = nil
                self.state = newState
            }

            let markerRenderTime = CFAbsoluteTimeGetCurrent() - markerRenderStartTime
            let totalPipelineTime = CFAbsoluteTimeGetCurrent() - pipelineStartTime
            
            Logger.network.info("""
            ⏳ EstateGeolocationResponse Success:
                Total Time: \(String(format: "%.2f", apiRequestTime * 1000))ms
            """)

            Logger.network.info("""
            ✅ Geolocation API Success:
               Center: (\(event.center.latitude), \(event.center.longitude))
               Max Distance: \(event.maxDistance)m
               Results: \(estates.count) estates
               Original: \(mapPoints.count) estates
               Filtered: \(filteredMapPoints.count) estates
               Clusters: \(clusterResult.clusterCount), Noise: \(clusterResult.noise.count)
            """)

            Logger.default.info("""
            🖼️ Marker Rendering Performance:
               UI Update Time: \(String(format: "%.2f", markerRenderTime * 1000))ms
               Total Pipeline Time: \(String(format: "%.2f", totalPipelineTime * 1000))ms
               Cluster Markers: \(clusterResult.clusterCount)
               Individual Markers: \(clusterResult.noise.count)
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
                var errorState = self.state
                errorState.isLoading = false
                errorState.errorMessage = error.localizedDescription
                self.state = errorState
            }
        } catch {
            Logger.network.error("❌ Unknown error: \(error.localizedDescription)")
            await MainActor.run {
                var errorState = self.state
                errorState.isLoading = false
                errorState.errorMessage = "주변 매물을 불러오는데 실패했습니다."
                self.state = errorState
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

    // MARK: - Filtering

    /// 필터를 적용하여 MapPoint와 QuadPoint 배열을 필터링
    /// - Parameters:
    ///   - mapPoints: 원본 MapPoint 배열
    ///   - quadPoints: 원본 QuadPoint 배열
    ///   - filter: 적용할 EstateFilter (nil이면 필터링 안함)
    /// - Returns: 필터링된 (MapPoint, QuadPoint) 튜플
    private func applyFilter(
        mapPoints: [MapPoint],
        quadPoints: [QuadPoint],
        filter: EstateFilter?
    ) -> ([MapPoint], [QuadPoint]) {
        guard let filter = filter, filter.isActive else {
            // 필터가 없거나 비활성화된 경우 원본 반환
            return (mapPoints, quadPoints)
        }

        // MapPoint 필터링
        let filteredMapPoints = mapPoints.filter { mapPoint in
            // 1. 거래 유형 필터
            if let transactionType = filter.transactionType {
                switch transactionType {
                case .jeonse:
                    // 전세: 월세가 0
                    if mapPoint.monthly_rent > 0 { return false }
                case .monthly:
                    // 월세: 월세가 0보다 큼
                    if mapPoint.monthly_rent == 0 { return false }
                }
            }

            // 2. 보증금 범위 필터
            if let depositRange = filter.depositRange {
                if mapPoint.deposit < depositRange.lowerBound || mapPoint.deposit > depositRange.upperBound {
                    return false
                }
            }

            // 3. 월세 범위 필터
            if let monthlyRentRange = filter.monthlyRentRange {
                if mapPoint.monthly_rent < monthlyRentRange.lowerBound || mapPoint.monthly_rent > monthlyRentRange.upperBound {
                    return false
                }
            }

            // 4. 면적 범위 필터
            if let areaRange = filter.areaRange {
                if mapPoint.area < areaRange.lowerBound || mapPoint.area > areaRange.upperBound {
                    return false
                }
            }

            // 5. 층수 필터
            if !filter.selectedFloors.isEmpty && !filter.selectedFloors.contains(.all) {
                var floorMatched = false
                for floorOption in filter.selectedFloors {
                    switch floorOption {
                    case .all:
                        floorMatched = true
                    case .semiBasement:
                        // 반지하: 0층 이하 (음수 포함)
                        if mapPoint.floors <= 0 { floorMatched = true }
                    case .firstFloor:
                        // 1층
                        if mapPoint.floors == 1 { floorMatched = true }
                    case .aboveGround:
                        // 지상층: 2층 이상
                        if mapPoint.floors >= 2 { floorMatched = true }
                    case .rooftop:
                        // 옥탑: 특정 값 또는 로직 필요 (현재는 건너뜀)
                        // TODO: 옥탑 판단 로직 추가 필요
                        break
                    }
                }
                if !floorMatched { return false }
            }

            // 6. 편의시설 필터
            // TODO: MapPoint에 amenities 정보가 추가되면 구현
            // if !filter.selectedAmenities.isEmpty { ... }

            return true
        }

        // 필터링된 MapPoint의 ID 집합
        let filteredIds = Set(filteredMapPoints.map { "\($0.longitude),\($0.latitude)" })

        // QuadPoint 필터링 (MapPoint와 동일한 위치만 유지)
        let filteredQuadPoints = quadPoints.filter { quadPoint in
            let key = "\(quadPoint.coordinate.longitude),\(quadPoint.coordinate.latitude)"
            return filteredIds.contains(key)
        }

        return (filteredMapPoints, filteredQuadPoints)
    }

    /// 저장된 원본 데이터에 필터를 적용하고 클러스터링 재수행
    private func applyFilterAndCluster() async {
        let filterStartTime = CFAbsoluteTimeGetCurrent()

        // 필터링 적용
        let (filteredMapPoints, filteredQuadPoints) = applyFilter(
            mapPoints: allMapPoints,
            quadPoints: allQuadPoints,
            filter: filterState
        )

        // 클러스터링 수행
        let clusterResult = await performClustering(points: filteredQuadPoints, maxDistance: lastMaxDistance)

        let totalTime = CFAbsoluteTimeGetCurrent() - filterStartTime

        // State 업데이트
        await MainActor.run {
            var newState = MapState()
            newState.mapPoints = filteredMapPoints
            newState.quadPoints = filteredQuadPoints
            newState.clusters = clusterResult.clusterCenters()
            newState.noisePoints = clusterResult.noise
            newState.isLoading = false
            newState.errorMessage = nil
            self.state = newState

            Logger.default.info("""
            🔍 Filter Applied:
               Original: \(self.allMapPoints.count) estates
               Filtered: \(filteredMapPoints.count) estates
               Clusters: \(clusterResult.clusterCount)
               Noise: \(clusterResult.noise.count)
               Time: \(String(format: "%.2f", totalTime * 1000))ms
            """)
        }
    }

    // MARK: - Clustering

    /// 클러스터링 수행 (하이브리드 전략 패턴)
    /// - Parameters:
    ///   - points: 클러스터링할 QuadPoint 배열
    ///   - maxDistance: 지도 반경 (미터)
    /// - Returns: ClusterResult
    private func performClustering(points: [QuadPoint], maxDistance: Int) async -> ClusterResult {
        // ClusteringContext 생성 (적응형 파라미터 자동 계산)
        let context = ClusteringContext(
            maxDistance: maxDistance,
            dataSize: points.count,
            filterState: filterState
        )

        // ClusteringStrategyManager를 통해 전략 선택 및 클러스터링 수행
        let result = await clusteringManager.cluster(points: points, context: context)

        // Enhanced metrics 로깅
        if let mode = result.mode, let executionTime = result.executionTime {
            let modeName = mode == .gridBased ? "Grid-based" : "DBSCAN"
            Logger.default.info("""
            🎯 Clustering Complete:
               Mode: \(modeName)
               Clusters: \(result.clusterCount)
               Noise: \(result.noise.count)
               Time: \(String(format: "%.2f", executionTime * 1000))ms
            """)
        }

        return result
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
