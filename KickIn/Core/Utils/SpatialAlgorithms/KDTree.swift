//
//  KDTree.swift
//  KickIn
//
//  Created by 서준일 on 01/24/26.
//

import Foundation
import CoreLocation
import OSLog

/// KD-Tree 공간 인덱스 - O(log n) 속도로 특정 영역 내 점들을 검색
///
/// k=2 (2차원, 위도/경도) KD-Tree로 매물 좌표를 효율적으로 관리합니다.
/// - 중위값 기반 분할로 균형 잡힌 트리 구성
/// - queryRadius로 반경 검색 지원
/// - DBSCAN 클러스터링에 최적화
final class KDTree {
    // MARK: - Node

    private class Node {
        let point: QuadPoint
        var left: Node?
        var right: Node?

        init(point: QuadPoint) {
            self.point = point
        }
    }

    // MARK: - Properties

    private var root: Node?
    private let allPoints: [QuadPoint]  // 전체 boundary 조회용

    // MARK: - Initialization

    /// KDTree 초기화 및 구축
    /// - Parameter points: 삽입할 점들
    init(points: [QuadPoint]) {
        self.allPoints = points

        guard !points.isEmpty else {
            self.root = nil
            return
        }

        // 트리 구축
        self.root = buildTree(points: points, depth: 0)
    }

    // MARK: - Tree Construction

    /// 재귀적으로 KD-Tree 구축
    /// - Parameters:
    ///   - points: 현재 노드에 포함될 점들
    ///   - depth: 현재 깊이 (축 결정에 사용)
    /// - Returns: 구축된 노드
    private func buildTree(points: [QuadPoint], depth: Int) -> Node? {
        guard !points.isEmpty else { return nil }

        // 단일 점이면 리프 노드 생성
        if points.count == 1 {
            return Node(point: points[0])
        }

        // 축 결정: depth % 2 (0 = longitude, 1 = latitude)
        let axis = depth % 2

        // 중위값으로 정렬
        let sortedPoints = points.sorted { p1, p2 in
            if axis == 0 {
                return p1.longitude < p2.longitude
            } else {
                return p1.latitude < p2.latitude
            }
        }

        // 중간 점을 분할 기준으로 선택
        let medianIndex = sortedPoints.count / 2
        let medianPoint = sortedPoints[medianIndex]

        // 노드 생성
        let node = Node(point: medianPoint)

        // 왼쪽 서브트리 (중위값보다 작은 값들)
        let leftPoints = Array(sortedPoints[0..<medianIndex])
        node.left = buildTree(points: leftPoints, depth: depth + 1)

        // 오른쪽 서브트리 (중위값보다 큰 값들)
        let rightPoints = Array(sortedPoints[(medianIndex + 1)...])
        node.right = buildTree(points: rightPoints, depth: depth + 1)

        return node
    }

    // MARK: - Query

    /// 중심점으로부터 반경 내의 모든 점 검색 (DBSCAN용)
    /// - Parameters:
    ///   - center: 중심 좌표
    ///   - radius: 반경 (미터)
    /// - Returns: 반경 내 모든 QuadPoint 배열
    func queryRadius(center: CLLocationCoordinate2D, radius: Double) -> [QuadPoint] {
        var result: [QuadPoint] = []
        queryRadiusRecursive(
            node: root,
            center: center,
            radius: radius,
            depth: 0,
            result: &result
        )
        return result
    }

    /// 재귀적으로 반경 내 점 검색
    /// - Parameters:
    ///   - node: 현재 노드
    ///   - center: 중심 좌표
    ///   - radius: 반경 (미터)
    ///   - depth: 현재 깊이
    ///   - result: 결과 배열 (in-out)
    private func queryRadiusRecursive(
        node: Node?,
        center: CLLocationCoordinate2D,
        radius: Double,
        depth: Int,
        result: inout [QuadPoint]
    ) {
        guard let node = node else { return }

        // 1. 현재 노드의 점이 반경 내에 있는지 확인
        let distance = haversineDistance(from: center, to: node.point.coordinate)
        if distance <= radius {
            result.append(node.point)
        }

        // 2. 축 결정
        let axis = depth % 2

        // 3. 분할 축에서의 거리 계산
        let axisDistance: Double
        if axis == 0 {
            // Longitude 축
            // 경도 차이를 미터로 변환
            let lonDelta = abs(center.longitude - node.point.longitude)
            axisDistance = lonDelta * 111320.0 * cos(center.latitude * .pi / 180)
        } else {
            // Latitude 축
            let latDelta = abs(center.latitude - node.point.latitude)
            axisDistance = latDelta * 111320.0
        }

        // 4. 자식 노드 탐색 결정
        let currentValue = axis == 0 ? node.point.longitude : node.point.latitude
        let centerValue = axis == 0 ? center.longitude : center.latitude

        // 현재 점보다 center가 작으면 왼쪽이 주 탐색 방향
        if centerValue < currentValue {
            // 왼쪽 먼저 탐색
            queryRadiusRecursive(
                node: node.left,
                center: center,
                radius: radius,
                depth: depth + 1,
                result: &result
            )

            // 축 거리가 반경보다 작으면 오른쪽도 탐색 (교차 가능)
            if axisDistance <= radius {
                queryRadiusRecursive(
                    node: node.right,
                    center: center,
                    radius: radius,
                    depth: depth + 1,
                    result: &result
                )
            }
        } else {
            // 오른쪽 먼저 탐색
            queryRadiusRecursive(
                node: node.right,
                center: center,
                radius: radius,
                depth: depth + 1,
                result: &result
            )

            // 축 거리가 반경보다 작으면 왼쪽도 탐색 (교차 가능)
            if axisDistance <= radius {
                queryRadiusRecursive(
                    node: node.left,
                    center: center,
                    radius: radius,
                    depth: depth + 1,
                    result: &result
                )
            }
        }
    }

    // MARK: - Utility Methods

    /// 트리에 저장된 전체 점 개수
    /// - Returns: 전체 점 개수
    func count() -> Int {
        return allPoints.count
    }

    /// 트리의 최대 깊이
    /// - Returns: 최대 깊이
    func depth() -> Int {
        return calculateDepth(node: root)
    }

    private func calculateDepth(node: Node?) -> Int {
        guard let node = node else { return 0 }
        let leftDepth = calculateDepth(node: node.left)
        let rightDepth = calculateDepth(node: node.right)
        return 1 + max(leftDepth, rightDepth)
    }

    // MARK: - Haversine Distance

    /// Haversine 공식으로 두 좌표 사이의 거리 계산
    /// - Parameters:
    ///   - from: 시작 좌표
    ///   - to: 끝 좌표
    /// - Returns: 거리 (미터)
    private func haversineDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let earthRadius = 6371000.0 // 지구 반지름 (미터)

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
}
