//
//  ClusteringStrategy.swift
//  KickIn
//
//  Created by 서준일 on 01/13/26.
//

import Foundation

/// 클러스터링 전략 프로토콜 (Strategy Pattern)
///
/// Grid-based와 DBSCAN 등 다양한 클러스터링 알고리즘을
/// 일관된 인터페이스로 사용할 수 있도록 합니다.
protocol ClusteringStrategy {
    /// 클러스터링 모드
    var mode: ClusteringMode { get }

    /// QuadPoint 배열을 클러스터링
    /// - Parameters:
    ///   - points: 클러스터링할 점들
    ///   - context: 클러스터링 컨텍스트 (적응형 파라미터 포함)
    /// - Returns: ClusterResult (비동기)
    func cluster(points: [QuadPoint], context: ClusteringContext) async -> ClusterResult
}
