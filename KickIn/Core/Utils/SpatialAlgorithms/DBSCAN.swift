//
//  DBSCAN.swift
//  KickIn
//
//  Created by 서준일 on 01/09/26.
//

import Foundation
import CoreLocation
import OSLog

/// DBSCAN (Density-Based Spatial Clustering of Applications with Noise)
///
/// 밀도 기반 클러스터링 알고리즘으로 QuadTree를 활용하여 O(n log n) 성능 달성
/// - epsilon 반경 내 minPoints 이상의 점이 모이면 클러스터 형성
/// - 클러스터에 속하지 않는 점은 노이즈로 분류
/// - Swift Concurrency를 사용한 비동기 처리로 메인 스레드 블로킹 방지
final class DBSCAN {
    // MARK: - Types

    /// 점의 방문 상태
    private enum PointStatus {
        case unvisited      // 아직 방문하지 않음
        case visited        // 방문했지만 클러스터 미결정
        case clustered      // 클러스터에 포함됨
    }

    // MARK: - Properties

    private let quadTree: QuadTree
    private let epsilon: Double
    private let minPoints: Int

    // 방문 상태 추적 (Dictionary로 O(1) 조회)
    private var pointStatus: [String: PointStatus] = [:]

    // 결과 저장
    private var clusters: [[QuadPoint]] = []

    // MARK: - Initialization

    /// DBSCAN 초기화
    /// - Parameters:
    ///   - points: 클러스터링할 점들
    ///   - epsilon: 이웃 검색 반경 (미터)
    ///   - minPoints: 클러스터 형성에 필요한 최소 점 개수
    init(points: [QuadPoint], epsilon: Double, minPoints: Int) {
        // QuadTree 구축
        self.quadTree = QuadTree(points: points)
        self.epsilon = epsilon
        self.minPoints = minPoints

        // 모든 점을 unvisited로 초기화
        for point in points {
            pointStatus[point.id] = .unvisited
        }
    }

    // MARK: - Clustering (Async)

    /// 비동기 클러스터링 수행 (메인 스레드 블로킹 방지)
    /// - Returns: ClusterResult (클러스터 그룹 + 노이즈)
    func cluster() async -> ClusterResult {
        // Task.detached를 사용하여 백그라운드 스레드에서 실행
        return await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else {
                return ClusterResult(clusters: [], noise: [])
            }
            return await self.performClustering()
        }.value
    }

    // MARK: - Private Methods

    /// 실제 클러스터링 로직 수행
    private func performClustering() async -> ClusterResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        self.clusters = []
        var noise: [QuadPoint] = []

        // QuadTree에서 모든 점 가져오기
        let boundary = self.quadTree.boundary
        let allPoints = self.quadTree.query(range: boundary)

        // 모든 점에 대해 순회
        for point in allPoints {
            // 이미 처리된 점은 건너뛰기
            guard self.pointStatus[point.id] == .unvisited else { continue }

            // 방문 표시
            self.pointStatus[point.id] = .visited

            // epsilon 반경 내 이웃 찾기 (QuadTree의 O(log n) 쿼리)
            let neighbors = self.findNeighbors(of: point)

            if neighbors.count < self.minPoints {
                // 이웃이 충분하지 않음 → 노이즈
                noise.append(point)
            } else {
                // 이웃이 충분함 → 새 클러스터 시작
                let cluster = self.expandCluster(from: point, neighbors: neighbors)
                self.clusters.append(cluster)
            }
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        Logger.default.info("""
        🔍 DBSCAN Clustering Complete:
           Points: \(allPoints.count)
           Clusters: \(self.clusters.count)
           Noise: \(noise.count)
           Time: \(String(format: "%.2f", elapsed * 1000))ms
           Epsilon: \(self.epsilon)m, MinPoints: \(self.minPoints)
        """)

        return ClusterResult(clusters: self.clusters, noise: noise)
    }

    /// 점의 이웃 찾기 (QuadTree 활용)
    /// - Parameter point: 검색할 점
    /// - Returns: epsilon 반경 내의 이웃 점들 (자신 제외)
    private func findNeighbors(of point: QuadPoint) -> [QuadPoint] {
        // QuadTree의 queryRadius로 O(log n) 검색
        let neighbors = quadTree.queryRadius(
            center: point.coordinate,
            radius: epsilon
        )

        // 자신은 제외
        return neighbors.filter { $0.id != point.id }
    }

    /// 클러스터 확장 (BFS)
    /// - Parameters:
    ///   - seed: 클러스터의 시드 점
    ///   - neighbors: 시드 점의 이웃들
    /// - Returns: 확장된 클러스터 (QuadPoint 배열)
    private func expandCluster(from seed: QuadPoint, neighbors: [QuadPoint]) -> [QuadPoint] {
        var cluster: [QuadPoint] = [seed]
        var queue: [QuadPoint] = neighbors
        var queueIndex = 0

        // 시드를 클러스터에 포함
        pointStatus[seed.id] = .clustered

        // BFS로 클러스터 확장
        while queueIndex < queue.count {
            let current = queue[queueIndex]
            queueIndex += 1

            // 이미 클러스터에 포함된 점은 건너뛰기
            if pointStatus[current.id] == .clustered {
                continue
            }

            // 클러스터에 추가
            cluster.append(current)
            pointStatus[current.id] = .clustered

            // 현재 점의 이웃 검색
            let currentNeighbors = findNeighbors(of: current)

            // Core point인 경우 (이웃이 충분하면) 그 이웃들도 큐에 추가
            if currentNeighbors.count >= minPoints {
                for neighbor in currentNeighbors {
                    if pointStatus[neighbor.id] == .unvisited {
                        queue.append(neighbor)
                        pointStatus[neighbor.id] = .visited
                    }
                }
            }
        }

        return cluster
    }
}

// MARK: - Synchronous Wrapper (Optional)

extension DBSCAN {
    /// 동기식 클러스터링 (테스트용)
    /// - Returns: ClusterResult
    /// - Warning: 메인 스레드에서 호출하면 블로킹됨
    func clusterSync() -> ClusterResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        self.clusters = []
        var noise: [QuadPoint] = []

        // QuadTree에서 모든 점 가져오기
        let boundary = self.quadTree.boundary
        let allPoints = self.quadTree.query(range: boundary)

        // 모든 점에 대해 순회
        for point in allPoints {
            guard self.pointStatus[point.id] == .unvisited else { continue }
            self.pointStatus[point.id] = .visited

            let neighbors = self.findNeighbors(of: point)

            if neighbors.count < self.minPoints {
                noise.append(point)
            } else {
                let cluster = self.expandCluster(from: point, neighbors: neighbors)
                self.clusters.append(cluster)
            }
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        Logger.default.info("""
        🔍 DBSCAN Clustering Complete (Sync):
           Points: \(allPoints.count)
           Clusters: \(self.clusters.count)
           Noise: \(noise.count)
           Time: \(String(format: "%.2f", elapsed * 1000))ms
        """)

        return ClusterResult(clusters: self.clusters, noise: noise)
    }
}
