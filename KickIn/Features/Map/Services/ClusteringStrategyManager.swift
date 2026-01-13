//
//  ClusteringStrategyManager.swift
//  KickIn
//
//  Created by 서준일 on 01/13/26.
//

import Foundation
import OSLog

/// 클러스터링 전략 관리자
///
/// 데이터 크기와 필터 상태에 따라 최적의 클러스터링 전략을 선택합니다.
/// - Grid-based: 대규모 데이터셋 (5,000+ points) 또는 필터 미활성화
/// - DBSCAN: 소규모 필터링 데이터셋 (< 5,000 points) + 필터 활성화
final class ClusteringStrategyManager {
    // MARK: - Properties

    /// Grid-based 클러스터링 전략
    private let gridStrategy: GridClusteringStrategy

    /// DBSCAN 클러스터링 전략
    private let dbscanStrategy: DBSCANClusteringStrategy

    /// 전략 선택 임계값 (데이터 크기 기준)
    private let strategyThreshold: Int

    // MARK: - Initialization

    /// ClusteringStrategyManager 초기화
    /// - Parameter strategyThreshold: 전략 선택 임계값 (기본값: 5,000)
    init(strategyThreshold: Int = SpatialConstants.strategyThreshold) {
        self.gridStrategy = GridClusteringStrategy()
        self.dbscanStrategy = DBSCANClusteringStrategy()
        self.strategyThreshold = strategyThreshold
    }

    // MARK: - Public Methods

    /// 최적의 전략을 선택하여 클러스터링 수행
    /// - Parameters:
    ///   - points: 클러스터링할 점들
    ///   - context: 클러스터링 컨텍스트
    /// - Returns: ClusterResult
    func cluster(points: [QuadPoint], context: ClusteringContext) async -> ClusterResult {
        // 1. 전략 선택
        let selectedStrategy = selectStrategy(context: context)

        // 2. 선택 이유 로깅
        logStrategySelection(
            strategy: selectedStrategy,
            context: context
        )

        // 3. 선택된 전략으로 클러스터링 수행
        return await selectedStrategy.cluster(points: points, context: context)
    }

    // MARK: - Private Methods

    /// 전략 선택 로직
    /// - Parameter context: 클러스터링 컨텍스트
    /// - Returns: 선택된 ClusteringStrategy
    private func selectStrategy(context: ClusteringContext) -> ClusteringStrategy {
        // 필터가 활성화되고 데이터가 임계값보다 작으면 DBSCAN 사용
        if context.filterState != nil && context.dataSize < strategyThreshold {
            return dbscanStrategy
        }

        // 그 외의 경우 Grid-based 사용 (빠른 렌더링)
        return gridStrategy
    }

    /// 전략 선택 로깅
    /// - Parameters:
    ///   - strategy: 선택된 전략
    ///   - context: 클러스터링 컨텍스트
    private func logStrategySelection(
        strategy: ClusteringStrategy,
        context: ClusteringContext
    ) {
        let strategyName = strategy.mode == .gridBased
            ? "Grid-based (QuadTree)"
            : "Density-based (DBSCAN)"

        Logger.default.info("""
        📊 Strategy Selection:
           Data Size: \(context.dataSize)
           Threshold: \(self.strategyThreshold)
           Filter Active: \(context.filterState != nil)
           Selected: \(strategyName)
        """)
    }
}
