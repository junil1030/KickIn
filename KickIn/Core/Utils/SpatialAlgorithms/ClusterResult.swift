//
//  ClusterResult.swift
//  KickIn
//
//  Created by 서준일 on 01/09/26.
//

import Foundation
import CoreLocation

/// DBSCAN 클러스터링 결과
struct ClusterResult {
    /// 클러스터 그룹들 (각 그룹은 QuadPoint 배열)
    let clusters: [[QuadPoint]]

    /// 노이즈 점들 (어떤 클러스터에도 속하지 않는 점)
    let noise: [QuadPoint]

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
            ClusterCenter(points: cluster)
        }
    }
}

/// 클러스터의 중심점 (지도 표시용)
struct ClusterCenter {
    /// 중심 좌표 (클러스터 내 점들의 평균)
    let coordinate: CLLocationCoordinate2D

    /// 클러스터에 속한 점 개수
    let pointCount: Int

    /// 클러스터에 속한 점들의 ID
    let pointIds: [String]

    /// QuadPoint 배열로부터 중심점 계산
    /// - Parameter points: 클러스터를 구성하는 점들
    init(points: [QuadPoint]) {
        guard !points.isEmpty else {
            self.coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            self.pointCount = 0
            self.pointIds = []
            return
        }

        // 중심점 계산 (centroid)
        let avgLat = points.map { $0.latitude }.reduce(0, +) / Double(points.count)
        let avgLon = points.map { $0.longitude }.reduce(0, +) / Double(points.count)

        self.coordinate = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
        self.pointCount = points.count
        self.pointIds = points.map { $0.id }
    }
}
