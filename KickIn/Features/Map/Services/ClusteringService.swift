//
//  ClusteringService.swift
//  KickIn
//
//  Created by 서준일 on 01/09/26.
//

import Foundation
import OSLog

/// 클러스터링 서비스 구현체
///
/// DBSCAN 알고리즘을 사용하여 매물 점들을 클러스터링합니다.
/// - QuadTree 기반 O(n log n) 성능
/// - 백그라운드 스레드에서 비동기 실행
/// - 성능 측정 로깅 포함
final class ClusteringService: ClusteringServiceProtocol {

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// QuadPoint 배열을 DBSCAN으로 클러스터링
    /// - Parameters:
    ///   - points: 클러스터링할 점들
    ///   - epsilon: 이웃 검색 반경 (미터, 기본값: 100m)
    ///   - minPoints: 클러스터 형성 최소 점 개수 (기본값: 3)
    /// - Returns: ClusterResult (비동기)
    func cluster(
        points: [QuadPoint],
        epsilon: Double = SpatialConstants.defaultEpsilon,
        minPoints: Int = SpatialConstants.defaultMinPoints
    ) async -> ClusterResult {
        // 점이 너무 적으면 클러스터링 건너뛰기
        guard points.count > minPoints else {
            Logger.default.info("🔍 Clustering skipped: too few points (\(points.count))")
            // 모든 점을 개별 "클러스터"로 반환
            let individualClusters = points.map { [$0] }
            return ClusterResult(clusters: individualClusters, noise: [])
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        // DBSCAN 인스턴스 생성 및 클러스터링 (백그라운드 실행)
        let dbscan = DBSCAN(points: points, epsilon: epsilon, minPoints: minPoints)
        let result = await dbscan.cluster()

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        Logger.default.info("""
        🎯 ClusteringService Complete:
           Input: \(points.count) points
           Output: \(result.clusterCount) clusters, \(result.noise.count) noise
           Total Time: \(String(format: "%.2f", elapsed * 1000))ms
           Epsilon: \(epsilon)m, MinPoints: \(minPoints)
        """)

        return result
    }

    /// QuadTree 인덱스 구축
    /// - Parameter points: 인덱싱할 점들
    /// - Returns: QuadTree 인스턴스
    func buildQuadTree(points: [QuadPoint]) -> QuadTree {
        let startTime = CFAbsoluteTimeGetCurrent()

        let tree = QuadTree(points: points)

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        Logger.default.info("""
        🌳 QuadTree Built:
           Points: \(tree.count())
           Depth: \(tree.depth())
           Time: \(String(format: "%.2f", elapsed * 1000))ms
        """)

        return tree
    }
}
