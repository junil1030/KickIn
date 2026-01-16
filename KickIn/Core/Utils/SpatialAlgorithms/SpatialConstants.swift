//
//  SpatialConstants.swift
//  KickIn
//
//  Created by 서준일 on 01/09/26.
//

import Foundation
import OSLog

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
    
    // MARK: - Adaptive Epsilon (지도 반경 기반)
    
    /// 줌 레벨(반경)에 따른 적응형 epsilon 계산
    /// - Parameter maxDistance: 지도 반경 (미터)
    /// - Returns: 적절한 epsilon 값 (미터)
    static func epsilon(forMaxDistance distance: Int) -> Double {
        // 줌 아웃할수록 (반경이 클수록) 큰 epsilon 사용 (넓은 범위 클러스터링)
        // 줌 인할수록 (반경이 작을수록) 작은 epsilon 사용 (세밀한 클러스터링)
        
        let dist = Double(max(distance, 1))
        let rawFactor = 0.255 - log10(dist) * 0.05
        let factor = max(0.05, min(rawFactor, 0.15))
        let epsilon = dist * factor
        let result = max(40.0, min(epsilon, 1500.0))
        
        Logger.default.info("Epsilon: \(epsilon) / Result: \(result)")
        
        return result
    }
    
    // MARK: - Adaptive MinPts (지도 반경 기반)
    
    /// 줌 레벨(반경)에 따른 적응형 MinPts 계산
    /// - Parameter maxDistance: 지도 반경 (미터)
    /// - Returns: 적절한 minPts 값 (미터)
    static func minPoints(forMaxDistance distance: Int) -> Int {
        if distance < 1200 { return 2 }
        return defaultMinPoints
    }

    // MARK: - Strategy Selection

    /// 클러스터링 전략 선택 임계값
    /// - 데이터 크기가 이 값보다 크면 Grid-based 전략 사용
    /// - 데이터 크기가 이 값보다 작고 필터가 활성화되면 DBSCAN 전략 사용
    static let strategyThreshold: Int = 5_000

    // MARK: - Grid-based Clustering

    /// 지도 반경에 따른 적응형 Grid Depth 계산
    /// - Parameter maxDistance: 지도 반경 (미터)
    /// - Returns: QuadTree grid depth (1~10)
    static func gridDepth(forMaxDistance distance: Int) -> Int {
        switch distance {
        case 0..<500:        return 4  // Very zoomed in
        case 500..<1000:     return 3
        case 1000..<3000:    return 2
        case 3000..<10000:   return 1
        case 10000..<50000:  return 1
        default:             return 1   // Very zoomed out
        }
    }

    /// Jitter factor for grid-based clustering (7.5%)
    /// Applied as percentage of grid cell size to break up visual grid patterns
    static let gridJitterFactor: Double = 0.075
}
