//
//  SpatialConstants.swift
//  KickIn
//
//  Created by 서준일 on 01/09/26.
//

import Foundation

/// 공간 알고리즘 관련 상수
enum SpatialConstants {
    // MARK: - QuadTree Configuration

    /// QuadTree 노드당 기본 용량
    static let defaultCapacity = 32

    /// QuadTree 최대 깊이 (무한 subdivision 방지)
    static let defaultMaxDepth = 15

    // MARK: - DBSCAN Configuration

    /// DBSCAN 기본 반경 (미터)
    /// - 100m: 인근 건물들을 하나의 클러스터로 그룹화
    static let defaultEpsilon: Double = 100.0

    /// DBSCAN 최소 점 개수
    /// - 3개 이상의 점이 모여야 클러스터 형성
    static let defaultMinPoints: Int = 3

    // MARK: - Adaptive Epsilon (줌 레벨 기반)

    /// 줌 레벨에 따른 적응형 epsilon 계산
    /// - Parameter zoomLevel: 지도 줌 레벨 (높을수록 확대)
    /// - Returns: 적절한 epsilon 값 (미터)
    static func epsilon(forZoomLevel zoomLevel: Double) -> Double {
        // 줌 레벨이 높을수록 (더 확대) 작은 epsilon 사용
        if zoomLevel > 16 {
            return 50.0  // 거리 레벨 (개별 건물)
        } else if zoomLevel > 14 {
            return 100.0  // 동네 레벨
        } else if zoomLevel > 12 {
            return 200.0  // 구 레벨
        } else {
            return 500.0  // 시 레벨
        }
    }

    /// 점 개수에 따른 적응형 epsilon 계산
    /// - Parameter pointCount: 점 개수
    /// - Returns: 적절한 epsilon 값 (미터)
    static func epsilon(forPointCount pointCount: Int) -> Double {
        // 점이 많을수록 작은 epsilon 사용 (세밀한 클러스터링)
        if pointCount > 1000 {
            return 50.0
        } else if pointCount > 500 {
            return 100.0
        } else if pointCount > 100 {
            return 150.0
        } else {
            return 200.0
        }
    }
}
