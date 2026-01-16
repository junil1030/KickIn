//
//  DBSCANClusteringStrategy.swift
//  KickIn
//
//  Created by 서준일 on 01/13/26.
//

import Foundation
import OSLog

/// DBSCAN 기반 클러스터링 전략
///
/// 밀도 기반 클러스터링으로 정밀한 핫스팟 분석을 제공합니다.
/// - O(n log n) 복잡도 (QuadTree 활용)
/// - 필터링된 소규모 데이터셋에 적합 (< 5,000 points)
/// - 노이즈 점 탐지 가능
final class DBSCANClusteringStrategy: ClusteringStrategy {
    // MARK: - ClusteringStrategy Protocol

    let mode: ClusteringMode = .densityBased

    /// DBSCAN 알고리즘으로 클러스터링 수행
    /// - Parameters:
    ///   - points: 클러스터링할 점들
    ///   - context: 클러스터링 컨텍스트 (epsilon, minPoints 포함)
    /// - Returns: ClusterResult with enhanced metadata
    func cluster(points: [QuadPoint], context: ClusteringContext) async -> ClusterResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // 점이 너무 적으면 클러스터링 건너뛰기
        guard points.count > context.minPoints else {
            Logger.default.info("""
            🔍 DBSCAN Clustering skipped: too few points (\(points.count))
            """)

            // 모든 점을 개별 "클러스터"로 반환
            let individualClusters = points.map { [$0] }
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime

            return ClusterResult(
                clusters: individualClusters,
                noise: [],
                mode: .densityBased,
                executionTime: elapsed,
                reason: "Too few points for clustering"
            )
        }

        Logger.default.info("""
        🎯 DBSCAN Clustering Started:
           Points: \(points.count)
           Epsilon: \(String(format: "%.1f", context.epsilon))m
           MinPoints: \(context.minPoints)
        """)

        // DBSCAN 인스턴스 생성 및 클러스터링
        let dbscan = DBSCAN(
            points: points,
            epsilon: context.epsilon,
            minPoints: context.minPoints
        )
        let basicResult = await dbscan.cluster()

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Enhanced ClusterResult 반환
        return ClusterResult(
            clusters: basicResult.clusters,
            noise: basicResult.noise,
            mode: .densityBased,
            executionTime: elapsed,
            reason: "Density-based analysis for filtered data"
        )
    }
}
