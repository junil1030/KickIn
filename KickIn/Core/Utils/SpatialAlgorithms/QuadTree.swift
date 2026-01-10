//
//  QuadTree.swift
//  KickIn
//
//  Created by 서준일 on 01/09/26.
//

import Foundation
import CoreLocation
import OSLog

/// QuadTree 공간 인덱스 - O(log n) 속도로 특정 영역 내 점들을 검색
///
/// 수천 개의 매물 좌표를 효율적으로 관리하기 위한 공간 분할 자료구조입니다.
/// - capacity 초과 시 자동으로 4등분 (subdivide)
/// - maxDepth로 무한 subdivision 방지
/// - Optional children으로 메모리 최적화
final class QuadTree {
    // MARK: - Configuration

    private let capacity: Int
    private let maxDepth: Int
    private let currentDepth: Int

    // MARK: - Data Storage

    let boundary: QuadBox  // DBSCAN에서 접근 가능하도록 internal로 변경
    private var points: [QuadPoint] = []

    // MARK: - Children (Optional for memory efficiency)

    private var northWest: QuadTree?
    private var northEast: QuadTree?
    private var southWest: QuadTree?
    private var southEast: QuadTree?

    // MARK: - State

    private var isDivided: Bool = false

    // MARK: - Initialization

    /// QuadTree 초기화
    /// - Parameters:
    ///   - boundary: 이 노드가 관리하는 공간 영역
    ///   - capacity: 노드당 최대 점 개수 (기본값 32)
    ///   - maxDepth: 최대 트리 깊이 (기본값 15, 무한 루프 방지)
    ///   - currentDepth: 현재 노드의 깊이 (기본값 0)
    init(boundary: QuadBox, capacity: Int = 32, maxDepth: Int = 15, currentDepth: Int = 0) {
        self.boundary = boundary
        self.capacity = capacity
        self.maxDepth = maxDepth
        self.currentDepth = currentDepth
    }

    /// QuadPoint 배열로부터 QuadTree 생성 (편의 초기화)
    /// - Parameters:
    ///   - points: 삽입할 점들
    ///   - capacity: 노드당 최대 점 개수
    ///   - maxDepth: 최대 트리 깊이
    convenience init(points: [QuadPoint], capacity: Int = 32, maxDepth: Int = 15) {
        guard !points.isEmpty else {
            // 빈 배열인 경우 한국 전체를 기본 경계로 사용
            let defaultBoundary = QuadBox(xMin: 124.0, yMin: 33.0, xMax: 132.0, yMax: 39.0)
            self.init(boundary: defaultBoundary, capacity: capacity, maxDepth: maxDepth)
            return
        }

        // 점들의 좌표로부터 경계 박스 계산
        let lons = points.map { $0.longitude }
        let lats = points.map { $0.latitude }

        // 약간의 패딩 추가하여 경계선 점 처리
        let boundary = QuadBox(
            xMin: lons.min()! - 0.01,
            yMin: lats.min()! - 0.01,
            xMax: lons.max()! + 0.01,
            yMax: lats.max()! + 0.01
        )

        self.init(boundary: boundary, capacity: capacity, maxDepth: maxDepth)

        // 모든 점 삽입
        for point in points {
            insert(point)
        }
    }

    // MARK: - Insert

    /// 점을 QuadTree에 삽입
    /// - Parameter point: 삽입할 QuadPoint
    /// - Returns: 삽입 성공 여부
    @discardableResult
    func insert(_ point: QuadPoint) -> Bool {
        // 1. 경계 체크 - 이 노드의 영역 밖이면 거부
        guard boundary.contains(coordinate: point.coordinate) else {
            return false
        }

        // 2. 용량이 남아있고 분할되지 않았으면 바로 추가
        if points.count < capacity && !isDivided {
            points.append(point)
            return true
        }

        // 3. 최대 깊이 도달 시 용량 무시하고 추가 (무한 루프 방지)
        if currentDepth >= maxDepth {
            points.append(point)
            return true
        }

        // 4. 분할이 필요하면 subdivide
        if !isDivided {
            subdivide()

            // 기존 점들을 자식 노드로 재분배
            let pointsToRedistribute = points
            points.removeAll()

            for existingPoint in pointsToRedistribute {
                insertIntoChild(existingPoint)
            }
        }

        // 5. 적절한 자식 노드에 삽입
        return insertIntoChild(point)
    }

    /// 자식 노드에 점 삽입
    @discardableResult
    private func insertIntoChild(_ point: QuadPoint) -> Bool {
        if let child = quadrant(for: point) {
            return child.insert(point)
        }

        // 사분면을 찾을 수 없는 경우 (경계선 상) 현재 노드에 추가
        points.append(point)
        return true
    }

    // MARK: - Subdivide

    /// 현재 노드를 4등분하여 자식 노드 생성
    private func subdivide() {
        // 이미 분할되었거나 최대 깊이 도달 시 중단
        guard !isDivided else { return }
        guard currentDepth < maxDepth else { return }

        // 중심점 계산
        let midX = (boundary.xMin + boundary.xMax) / 2.0
        let midY = (boundary.yMin + boundary.yMax) / 2.0

        // 4개의 자식 노드 생성
        // NorthWest (북서): 왼쪽 위
        northWest = QuadTree(
            boundary: QuadBox(
                xMin: boundary.xMin,
                yMin: midY,
                xMax: midX,
                yMax: boundary.yMax
            ),
            capacity: capacity,
            maxDepth: maxDepth,
            currentDepth: currentDepth + 1
        )

        // NorthEast (북동): 오른쪽 위
        northEast = QuadTree(
            boundary: QuadBox(
                xMin: midX,
                yMin: midY,
                xMax: boundary.xMax,
                yMax: boundary.yMax
            ),
            capacity: capacity,
            maxDepth: maxDepth,
            currentDepth: currentDepth + 1
        )

        // SouthWest (남서): 왼쪽 아래
        southWest = QuadTree(
            boundary: QuadBox(
                xMin: boundary.xMin,
                yMin: boundary.yMin,
                xMax: midX,
                yMax: midY
            ),
            capacity: capacity,
            maxDepth: maxDepth,
            currentDepth: currentDepth + 1
        )

        // SouthEast (남동): 오른쪽 아래
        southEast = QuadTree(
            boundary: QuadBox(
                xMin: midX,
                yMin: boundary.yMin,
                xMax: boundary.xMax,
                yMax: midY
            ),
            capacity: capacity,
            maxDepth: maxDepth,
            currentDepth: currentDepth + 1
        )

        isDivided = true
    }

    /// 점이 속하는 사분면 반환
    /// - Parameter point: 검사할 점
    /// - Returns: 해당 사분면의 QuadTree, 없으면 nil
    private func quadrant(for point: QuadPoint) -> QuadTree? {
        let midX = (boundary.xMin + boundary.xMax) / 2.0
        let midY = (boundary.yMin + boundary.yMax) / 2.0

        // West/South는 >=, East/North는 < 사용 (경계 점 누락 방지)
        let isWest = point.longitude >= boundary.xMin && point.longitude < midX
        let isEast = point.longitude >= midX && point.longitude < boundary.xMax
        let isSouth = point.latitude >= boundary.yMin && point.latitude < midY
        let isNorth = point.latitude >= midY && point.latitude < boundary.yMax

        if isWest && isNorth { return northWest }
        if isEast && isNorth { return northEast }
        if isWest && isSouth { return southWest }
        if isEast && isSouth { return southEast }

        return nil
    }

    // MARK: - Query

    /// 주어진 사각형 영역 내의 모든 점 검색
    /// - Parameter range: 검색할 영역 (QuadBox)
    /// - Returns: 영역 내 모든 QuadPoint 배열
    func query(range: QuadBox) -> [QuadPoint] {
        var found: [QuadPoint] = []

        // 1. 조기 종료 - 영역이 겹치지 않으면 검색 불필요
        guard boundary.intersects(range) else {
            return found
        }

        // 2. 현재 노드의 점들 중 범위 내에 있는 점 추가
        for point in points {
            if range.contains(coordinate: point.coordinate) {
                found.append(point)
            }
        }

        // 3. 분할되어 있으면 자식 노드도 재귀 검색
        if isDivided {
            found.append(contentsOf: northWest?.query(range: range) ?? [])
            found.append(contentsOf: northEast?.query(range: range) ?? [])
            found.append(contentsOf: southWest?.query(range: range) ?? [])
            found.append(contentsOf: southEast?.query(range: range) ?? [])
        }

        return found
    }

    /// 중심점으로부터 반경 내의 모든 점 검색 (DBSCAN용)
    /// - Parameters:
    ///   - center: 중심 좌표
    ///   - radius: 반경 (미터)
    /// - Returns: 반경 내 모든 QuadPoint 배열
    func queryRadius(center: CLLocationCoordinate2D, radius: Double) -> [QuadPoint] {
        // 1. 반경을 경위도 델타로 변환하여 검색 박스 생성
        // 위도 1도 ≈ 111.32 km
        let latDelta = radius / 111320.0
        // 경도는 위도에 따라 달라짐
        let lonDelta = radius / (111320.0 * cos(center.latitude * .pi / 180))

        let searchBox = QuadBox(
            xMin: center.longitude - lonDelta,
            yMin: center.latitude - latDelta,
            xMax: center.longitude + lonDelta,
            yMax: center.latitude + latDelta
        )

        // 2. 박스 내 후보 점들 가져오기 (QuadTree 쿼리)
        let candidates = query(range: searchBox)

        // 3. Haversine 거리로 정확히 필터링
        return candidates.filter { point in
            haversineDistance(from: center, to: point.coordinate) <= radius
        }
    }

    // MARK: - Utility Methods

    /// 트리에 저장된 전체 점 개수
    /// - Returns: 전체 점 개수
    func count() -> Int {
        var total = points.count

        if isDivided {
            total += (northWest?.count() ?? 0)
            total += (northEast?.count() ?? 0)
            total += (southWest?.count() ?? 0)
            total += (southEast?.count() ?? 0)
        }

        return total
    }

    /// 트리의 최대 깊이
    /// - Returns: 최대 깊이
    func depth() -> Int {
        guard isDivided else { return currentDepth }

        let maxChildDepth = max(
            northWest?.depth() ?? currentDepth,
            northEast?.depth() ?? currentDepth,
            southWest?.depth() ?? currentDepth,
            southEast?.depth() ?? currentDepth
        )

        return maxChildDepth
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
