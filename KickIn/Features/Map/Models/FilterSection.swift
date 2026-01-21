//
//  FilterSection.swift
//  KickIn
//
//  Created by 서준일 on 01/20/26.
//

import Foundation

// MARK: - FilterSection

/// 필터 섹션 구분
enum FilterSection: String, CaseIterable, Identifiable {
    case transactionType = "거래 유형"
    case price = "가격"
    case area = "면적"
    case floor = "층수"
    case amenity = "옵션"

    var id: String { rawValue }

    /// 섹션별 서브타이틀
    var subtitle: String? {
        switch self {
        case .floor, .amenity:
            return "중복 선택 가능"
        default:
            return nil
        }
    }
}
