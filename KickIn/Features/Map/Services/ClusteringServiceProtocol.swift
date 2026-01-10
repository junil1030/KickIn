//
//  ClusteringServiceProtocol.swift
//  KickIn
//
//  Created by 서준일 on 01/09/26.
//

import Foundation

/// 클러스터링 서비스 프로토콜
protocol ClusteringServiceProtocol {
    /// QuadPoint 배열을 DBSCAN 알고리즘으로 클러스터링
    /// - Parameters:
    ///   - points: 클러스터링할 점들
    ///   - epsilon: 이웃 검색 반경 (미터)
    ///   - minPoints: 클러스터 형성에 필요한 최소 점 개수
    /// - Returns: ClusterResult (비동기)
    func cluster(points: [QuadPoint],
                epsilon: Double,
                minPoints: Int) async -> ClusterResult

    /// QuadTree 인덱스 구축
    /// - Parameter points: 인덱싱할 점들
    /// - Returns: QuadTree 인스턴스
    func buildQuadTree(points: [QuadPoint]) -> QuadTree
}
