//
//  FilterViewModel.swift
//  KickIn
//
//  Created by 서준일 on 01/20/26.
//

import Foundation
import Combine

final class FilterViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedTransactionType: TransactionType?
    @Published var depositRange: ClosedRange<Int>
    @Published var monthlyRentRange: ClosedRange<Int>
    @Published var areaRange: ClosedRange<Double>
    @Published var selectedFloors: Set<FloorOption> = []
    @Published var selectedAmenities: Set<AmenityOption> = []

    // MARK: - Initialization

    init(currentFilter: EstateFilter? = nil) {
        if let filter = currentFilter {
            self.selectedTransactionType = filter.transactionType
            self.depositRange = filter.depositRange ?? DepositRange.min...DepositRange.max
            self.monthlyRentRange = filter.monthlyRentRange ?? MonthlyRentRange.min...MonthlyRentRange.max
            self.areaRange = filter.areaRange ?? AreaRange.min...AreaRange.max
            self.selectedFloors = filter.selectedFloors
            self.selectedAmenities = filter.selectedAmenities
        } else {
            self.selectedTransactionType = nil
            self.depositRange = DepositRange.min...DepositRange.max
            self.monthlyRentRange = MonthlyRentRange.min...MonthlyRentRange.max
            self.areaRange = AreaRange.min...AreaRange.max
            self.selectedFloors = []
            self.selectedAmenities = []
        }
    }

    // MARK: - Public Methods

    /// 거래 유형 토글
    func toggleTransactionType(_ type: TransactionType) {
        if selectedTransactionType == type {
            selectedTransactionType = nil
        } else {
            selectedTransactionType = type
        }
    }

    /// 층수 토글 (전체 선택 시 타 항목 해제 로직)
    func toggleFloor(_ floor: FloorOption) {
        if floor == .all {
            // 전체 선택 시 다른 항목 모두 해제
            selectedFloors = [.all]
        } else {
            // 전체 해제
            selectedFloors.remove(.all)

            // 해당 층수 토글
            if selectedFloors.contains(floor) {
                selectedFloors.remove(floor)
            } else {
                selectedFloors.insert(floor)
            }
        }
    }

    /// 옵션 토글
    func toggleAmenity(_ amenity: AmenityOption) {
        if selectedAmenities.contains(amenity) {
            selectedAmenities.remove(amenity)
        } else {
            selectedAmenities.insert(amenity)
        }
    }

    /// EstateFilter 빌드
    func buildFilter() -> EstateFilter {
        var filter = EstateFilter()

        filter.transactionType = selectedTransactionType

        // 보증금 범위 (전체가 아닐 때만)
        if depositRange != (DepositRange.min...DepositRange.max) {
            filter.depositRange = depositRange
        }

        // 월세 범위 (전체가 아닐 때만)
        if monthlyRentRange != (MonthlyRentRange.min...MonthlyRentRange.max) {
            filter.monthlyRentRange = monthlyRentRange
        }

        // 면적 범위 (전체가 아닐 때만)
        if areaRange != (AreaRange.min...AreaRange.max) {
            filter.areaRange = areaRange
        }

        // 층수 (전체가 아닐 때만)
        if !selectedFloors.isEmpty && !selectedFloors.contains(.all) {
            filter.selectedFloors = selectedFloors
        }

        filter.selectedAmenities = selectedAmenities

        return filter
    }

    /// 전체 초기화
    func resetAll() {
        selectedTransactionType = nil
        depositRange = DepositRange.min...DepositRange.max
        monthlyRentRange = MonthlyRentRange.min...MonthlyRentRange.max
        areaRange = AreaRange.min...AreaRange.max
        selectedFloors = []
        selectedAmenities = []
    }
}
