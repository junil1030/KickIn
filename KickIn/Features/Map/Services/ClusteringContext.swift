//
//  ClusteringContext.swift
//  KickIn
//
//  Created by 서준일 on 01/13/26.
//

import Foundation

// MARK: - EstateFilter (Placeholder)

/// 매물 필터 (향후 구현 예정)
///
/// TODO: 필터 기능 구현 시 다음 프로퍼티들 추가 예정:
/// - category: EstateCategory? (원룸, 투룸, 오피스텔 등)
/// - priceRange: ClosedRange<Int>? (가격 범위)
/// - areaRange: ClosedRange<Int>? (면적 범위)
/// - transactionType: TransactionType? (월세, 전세, 매매)
struct EstateFilter {
    // Empty placeholder - 향후 확장 예정
}

// MARK: - ClusteringContext

/// 클러스터링 실행 컨텍스트
///
/// 적응형 파라미터(epsilon, minPoints, gridDepth)를 자동 계산하고
/// 전략 선택에 필요한 정보(filterState, dataSize)를 담고 있습니다.
struct ClusteringContext {
    // MARK: - Properties

    /// 활성화된 필터 상태 (없으면 nil)
    let filterState: EstateFilter?

    /// 클러스터링할 데이터 크기
    let dataSize: Int

    /// 지도 반경 (미터)
    let maxDistance: Int

    // MARK: - Adaptive Parameters

    /// DBSCAN epsilon (이웃 검색 반경, 미터)
    /// - 지도 반경에 따라 자동 계산
    let epsilon: Double

    /// DBSCAN minPoints (클러스터 형성 최소 점 개수)
    /// - 지도 반경에 따라 자동 계산
    let minPoints: Int

    /// Grid-based clustering depth
    /// - 지도 반경에 따라 자동 계산
    let gridDepth: Int

    // MARK: - Initialization

    /// ClusteringContext 초기화
    /// - Parameters:
    ///   - maxDistance: 지도 반경 (미터)
    ///   - dataSize: 클러스터링할 점의 개수
    ///   - filterState: 활성화된 필터 (없으면 nil)
    init(
        maxDistance: Int,
        dataSize: Int,
        filterState: EstateFilter? = nil
    ) {
        self.maxDistance = maxDistance
        self.dataSize = dataSize
        self.filterState = filterState

        // Adaptive parameters 자동 계산
        self.epsilon = SpatialConstants.epsilon(forMaxDistance: maxDistance)
        self.minPoints = SpatialConstants.minPoints(forMaxDistance: maxDistance)
        self.gridDepth = SpatialConstants.gridDepth(forMaxDistance: maxDistance)
    }
}
