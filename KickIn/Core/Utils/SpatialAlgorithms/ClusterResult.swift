//
//  ClusterResult.swift
//  KickIn
//
//  Created by 서준일 on 01/09/26.
//

import Foundation
import CoreLocation

/// Seeded random number generator for deterministic jitter
fileprivate struct SeededRandomGenerator: RandomNumberGenerator {
    private var seed: UInt64

    init(seed: Int) {
        self.seed = UInt64(bitPattern: Int64(seed))
    }

    mutating func next() -> UInt64 {
        // Linear Congruential Generator (LCG)
        seed = (seed &* 6364136223846793005) &+ 1442695040888963407
        return seed
    }
}

/// 클러스터링 모드
enum ClusteringMode {
    /// Grid-based 클러스터링 (QuadTree 기반, O(n) 복잡도)
    case gridBased

    /// Density-based 클러스터링 (DBSCAN, O(n log n) 복잡도)
    case densityBased
}

/// DBSCAN 클러스터링 결과
struct ClusterResult {
    /// 클러스터 그룹들 (각 그룹은 QuadPoint 배열)
    let clusters: [[QuadPoint]]

    /// 노이즈 점들 (어떤 클러스터에도 속하지 않는 점)
    let noise: [QuadPoint]

    /// 클러스터링 모드 (선택적, 전략 패턴용)
    let mode: ClusteringMode?

    /// 실행 시간 (초 단위, 선택적)
    let executionTime: TimeInterval?

    /// 전략 선택 이유 (선택적)
    let reason: String?

    /// Grid cell 크기 (Grid-based 클러스터링용, 선택적)
    let gridCellSize: Double?

    // MARK: - Initializers

    /// Enhanced initializer (전략 패턴용)
    /// - Parameters:
    ///   - clusters: 클러스터 그룹들
    ///   - noise: 노이즈 점들
    ///   - mode: 클러스터링 모드
    ///   - executionTime: 실행 시간 (초)
    ///   - reason: 전략 선택 이유
    init(
        clusters: [[QuadPoint]],
        noise: [QuadPoint],
        mode: ClusteringMode? = nil,
        executionTime: TimeInterval? = nil,
        reason: String? = nil,
        gridCellSize: Double? = nil
    ) {
        self.clusters = clusters
        self.noise = noise
        self.mode = mode
        self.executionTime = executionTime
        self.reason = reason
        self.gridCellSize = gridCellSize
    }

    // MARK: - Computed Properties

    /// 클러스터 개수
    var clusterCount: Int {
        clusters.count
    }

    /// 전체 점 개수 (클러스터 + 노이즈)
    var totalPoints: Int {
        clusters.reduce(0) { $0 + $1.count } + noise.count
    }

    /// 특정 점이 속한 클러스터 찾기
    /// - Parameter pointId: 검색할 점의 ID
    /// - Returns: 해당 점이 속한 클러스터, 없으면 nil
    func cluster(containing pointId: String) -> [QuadPoint]? {
        return clusters.first { cluster in
            cluster.contains { $0.id == pointId }
        }
    }

    /// 클러스터 중심점들 계산 (지도 마커 표시용)
    /// - Returns: ClusterCenter 배열
    func clusterCenters() -> [ClusterCenter] {
        return clusters.map { cluster in
            ClusterCenter(
                points: cluster,
                mode: mode,
                gridCellSize: gridCellSize
            )
        }
    }
}

/// 클러스터의 중심점 (지도 표시용)
struct ClusterCenter: Identifiable {
    /// 고유 ID (클러스터 내 점들의 ID 조합)
    var id: String {
        pointIds.sorted().joined(separator: ",")
    }

    /// 중심 좌표 (클러스터 내 점들의 평균)
    let coordinate: CLLocationCoordinate2D

    /// 클러스터에 속한 점 개수
    let pointCount: Int

    /// 클러스터에 속한 점들의 ID
    let pointIds: [String]

    /// 클러스터에 속한 점들 (매물 정보 포함)
    let points: [QuadPoint]

    /// 클러스터 내 매물들을 InterestUIModel 배열로 변환
    var estates: [InterestUIModel] {
        points.compactMap { point in
            guard let mapPoint = point.mapPoint else { return nil }
            return mapPoint.toInterestUIModel(id: point.id)
        }
    }

    /// QuadPoint 배열로부터 중심점 계산
    /// - Parameters:
    ///   - points: 클러스터를 구성하는 점들
    ///   - mode: 클러스터링 모드 (선택적)
    ///   - gridCellSize: Grid cell 크기 (선택적, Grid-based 전용)
    init(
        points: [QuadPoint],
        mode: ClusteringMode? = nil,
        gridCellSize: Double? = nil
    ) {
        guard !points.isEmpty else {
            self.coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            self.pointCount = 0
            self.pointIds = []
            self.points = []
            return
        }

        // 중심점 계산 (centroid) - 클러스터 내 매물들의 위경도 평균
        let avgLat = points.map { $0.latitude }.reduce(0, +) / Double(points.count)
        let avgLon = points.map { $0.longitude }.reduce(0, +) / Double(points.count)

        // 단일 매물일 때는 정확히 해당 위치에, 여러 매물일 때는 중심점에 마커 표시
        self.coordinate = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
        self.pointCount = points.count
        self.pointIds = points.map { $0.id }
        self.points = points
    }
}
