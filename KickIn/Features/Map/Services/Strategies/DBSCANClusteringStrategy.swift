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

        // QuadTree 기반 DBSCAN (성능 비교용 - 주석 해제 시 QuadTree vs KDTree 비교 가능)
        /*
        let quadTreeDBSCAN = DBSCAN(
            points: points,
            epsilon: context.epsilon,
            minPoints: context.minPoints,
            indexKind: .quadTree
        )
        let quadTreeStartTime = CFAbsoluteTimeGetCurrent()
        let quadTreeResult = await quadTreeDBSCAN.cluster()
        let quadTreeElapsed = CFAbsoluteTimeGetCurrent() - quadTreeStartTime
        */

        // KD-Tree 기반 DBSCAN
        let kdTreeDBSCAN = DBSCAN(
            points: points,
            epsilon: context.epsilon,
            minPoints: context.minPoints,
            indexKind: .kdTree
        )
        let kdTreeStartTime = CFAbsoluteTimeGetCurrent()
        let kdTreeResult = await kdTreeDBSCAN.cluster()
        let kdTreeElapsed = CFAbsoluteTimeGetCurrent() - kdTreeStartTime

        // 비교 로깅 (QuadTree 측정 시 주석 해제)
        /*
        let totalElapsed = CFAbsoluteTimeGetCurrent() - startTime
        let speedup = quadTreeElapsed / kdTreeElapsed

        Logger.default.info("""
           DBSCAN Performance Comparison:
           QuadTree: \(String(format: "%.2f", quadTreeElapsed * 1000))ms (\(quadTreeResult.clusterCount) clusters, \(quadTreeResult.noise.count) noise)
           KD-Tree:  \(String(format: "%.2f", kdTreeElapsed * 1000))ms (\(kdTreeResult.clusterCount) clusters, \(kdTreeResult.noise.count) noise)
           Speedup:  \(String(format: "%.2f", speedup))x \(speedup >= 1.0 ? "(KD-Tree faster)" : "(QuadTree faster)")
           Total:    \(String(format: "%.2f", totalElapsed * 1000))ms
        """)
        */

        // KD-Tree 결과 반환
        return ClusterResult(
            clusters: kdTreeResult.clusters,
            noise: kdTreeResult.noise,
            mode: .densityBased,
            executionTime: kdTreeElapsed,
            reason: "Density-based analysis with KD-Tree"
        )
    }
}
