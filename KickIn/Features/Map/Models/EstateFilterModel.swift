//
//  EstateFilterModel.swift
//  KickIn
//
//  Created by 서준일 on 01/20/26.
//

import Foundation

// MARK: - TransactionType

/// 거래 유형
enum TransactionType: String, CaseIterable, Equatable {
    case jeonse = "전세"
    case monthly = "월세"
}

// MARK: - DepositRange

/// 보증금 범위 (단위: 원)
struct DepositRange {
    static let min = 0
    static let max = 1_000_000_000 // 10억

    /// 보증금 steps (0원, 1천만, 3천만, 5천만, 1억, 1.5억, 2억, 3억, 5억, 10억)
    static let steps: [Int] = [
        0,
        10_000_000,   // 1천만
        30_000_000,   // 3천만
        50_000_000,   // 5천만
        100_000_000,  // 1억
        150_000_000,  // 1.5억
        200_000_000,  // 2억
        300_000_000,  // 3억
        500_000_000,  // 5억
        1_000_000_000 // 10억
    ]
}

// MARK: - MonthlyRentRange

/// 월세 범위 (단위: 원)
struct MonthlyRentRange {
    static let min = 0
    static let max = 300_0000 // 300만원

    /// 월세 steps (0원, 10만, 20만, 30만, 40만, 50만, 60만, 80만, 100만, 150만, 200만, 300만)
    static let steps: [Int] = [
        0,
        100_000,     // 10만
        200_000,     // 20만
        300_000,     // 30만
        400_000,     // 40만
        500_000,     // 50만
        600_000,     // 60만
        800_000,     // 80만
        1_000_000,   // 100만
        1_500_000,   // 150만
        2_000_000,   // 200만
        3_000_000    // 300만
    ]
}

// MARK: - AreaRange

/// 면적 범위 (단위: m²)
struct AreaRange {
    static let min: Double = 0
    static let max: Double = 200

    /// 면적 steps (전체, 33m², 66m², 99m², 최대)
    static let steps: [Double] = [
        0,    // 전체
        33,   // 33m²
        66,   // 66m²
        99,   // 99m²
        200   // 최대
    ]
}

// MARK: - FloorOption

/// 층수 옵션
enum FloorOption: String, CaseIterable, Equatable, Hashable {
    case all = "전체"
    case semiBasement = "반지하"
    case firstFloor = "1층"
    case aboveGround = "지상층"
    case rooftop = "옥탑"
}

// MARK: - AmenityOption

/// 옵션 (편의시설)
enum AmenityOption: String, CaseIterable, Equatable, Hashable {
    case refrigerator = "냉장고"
    case washingMachine = "세탁기"
    case airConditioner = "에어컨"
    case closet = "옷장"
    case shoeCabinet = "신발장"
    case microwave = "전자레인지"
    case sink = "싱크대"
    case television = "TV"

    /// 아이콘 이름 (Assets에서 사용)
    var iconName: String {
        switch self {
        case .refrigerator: return "Refrigerator"
        case .washingMachine: return "WashingMachine"
        case .airConditioner: return "AirConditioner"
        case .closet: return "Closet"
        case .shoeCabinet: return "ShoeCabinet"
        case .microwave: return "Microwave"
        case .sink: return "Sink"
        case .television: return "Television"
        }
    }
}
