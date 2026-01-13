//
//  GridClusteringStrategy.swift
//  KickIn
//
//  Created by 서준일 on 01/13/26.
//

import Foundation
import OSLog

/// Grid-based 클러스터링 전략 (QuadTree 활용)
///
/// 공간 기반 그리드 분할로 빠른 렌더링을 제공합니다.
/// - O(n) 복잡도
/// - 대규모 데이터셋에 적합 (5,000+ points)
/// - 노이즈 점 없음 (모든 점이 클러스터에 포함)
final class GridClusteringStrategy: ClusteringStrategy {
    // MARK: - ClusteringStrategy Protocol

    let mode: ClusteringMode = .gridBased

    /// Grid-based 클러스터링 수행
    /// - Parameters:
    ///   - points: 클러스터링할 점들
    ///   - context: 클러스터링 컨텍스트 (gridDepth 포함)
    /// - Returns: ClusterResult with enhanced metadata
    func cluster(points: [QuadPoint], context: ClusteringContext) async -> ClusterResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // 빈 배열 처리
        guard !points.isEmpty else {
            Logger.default.info("🔲 Grid Clustering skipped: no points")
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            return ClusterResult(
                clusters: [],
                noise: [],
                mode: .gridBased,
                executionTime: elapsed,
                reason: "No points to cluster"
            )
        }

        Logger.default.info("""
        🔲 Grid Clustering Started:
           Points: \(points.count)
           Target Depth: \(context.gridDepth)
           Max Distance: \(context.maxDistance)m
        """)

        // Task.detached로 백그라운드 실행
        let result = await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else {
                return ClusterResult(clusters: [], noise: [])
            }
            return await self.performGridClustering(
                points: points,
                targetDepth: context.gridDepth,
                maxDistance: context.maxDistance
            )
        }.value

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        Logger.default.info("""
        🔲 Grid Clustering Complete:
           Clusters: \(result.clusterCount)
           Time: \(String(format: "%.2f", elapsed * 1000))ms
        """)

        // Enhanced ClusterResult 반환
        return ClusterResult(
            clusters: result.clusters,
            noise: result.noise,
            mode: .gridBased,
            executionTime: elapsed,
            reason: "Grid-based for large dataset"
        )
    }

    // MARK: - Private Methods

    /// 실제 Grid 클러스터링 수행
    /// - Parameters:
    ///   - points: 클러스터링할 점들
    ///   - targetDepth: Grid depth (1~10)
    ///   - maxDistance: 지도 반경 (미터)
    /// - Returns: ClusterResult
    private func performGridClustering(
        points: [QuadPoint],
        targetDepth: Int,
        maxDistance: Int
    ) async -> ClusterResult {
        // 1. QuadTree 구축
        let quadTree = QuadTree(points: points)
        let bounds = quadTree.boundary

        // 2. Grid cell 크기 계산
        // targetDepth가 클수록 더 작은 셀 (더 세밀한 그리드)
        let cellSize = max(bounds.xMax - bounds.xMin, bounds.yMax - bounds.yMin) / pow(2.0, Double(targetDepth))

        // 3. Grid 위치마다 쿼리하여 클러스터 수집
        var clusters: [[QuadPoint]] = []
        var processedIds: Set<String> = [] // 중복 방지

        let xRange = stride(from: bounds.xMin, to: bounds.xMax, by: cellSize)
        let yRange = stride(from: bounds.yMin, to: bounds.yMax, by: cellSize)

        for gridX in xRange {
            for gridY in yRange {
                // Grid cell 영역 정의
                let cell = QuadBox(
                    xMin: gridX,
                    yMin: gridY,
                    xMax: gridX + cellSize,
                    yMax: gridY + cellSize
                )

                // 해당 영역의 점들 쿼리
                let pointsInCell = quadTree.query(range: cell)

                // 중복 제거 (점이 경계선에 걸친 경우)
                let uniquePoints = pointsInCell.filter { !processedIds.contains($0.id) }

                if !uniquePoints.isEmpty {
                    clusters.append(uniquePoints)
                    // 처리된 점들 기록
                    uniquePoints.forEach { processedIds.insert($0.id) }
                }
            }
        }

        // Grid-based는 노이즈 없음 (모든 점이 클러스터에 포함)
        return ClusterResult(clusters: clusters, noise: [])
    }
}
