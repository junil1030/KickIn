//
//  Font+Extension.swift
//  KickIn
//
//  Created by 서준일 on 12/20/25.
//

import SwiftUI

enum FontFamily {
    case pretendardRegular
    case pretendardMedium
    case pretendardBold
    case yeongdeok
    case system
}

extension Font {
    // MARK: - Custom Font Names
    private static let pretendardRegular = "Pretendard-Regular"
    private static let pretendardMedium = "Pretendard-Medium"
    private static let pretendardBold = "Pretendard-Bold"
    private static let yeongdeokHaeparang = "Yeongdeok-Haeparang"

    // MARK: - Title
    static func title1(_ family: FontFamily = .pretendardRegular) -> Font {
        switch family {
        case .pretendardBold:
            return .custom(pretendardBold, size: 22)
        case .pretendardMedium:
            return .custom(pretendardMedium, size: 22)
        case .pretendardRegular:
            return .custom(pretendardRegular, size: 22)
        case .yeongdeok:
            return .custom(yeongdeokHaeparang, size: 22)
        case .system:
            return .system(size: 22)
        }
    }

    // MARK: - Body
    static func body1(_ family: FontFamily = .pretendardRegular) -> Font {
        switch family {
        case .pretendardBold:
            return .custom(pretendardBold, size: 16)
        case .pretendardMedium:
            return .custom(pretendardMedium, size: 16)
        case .pretendardRegular:
            return .custom(pretendardRegular, size: 16)
        case .yeongdeok:
            return .custom(yeongdeokHaeparang, size: 16)
        case .system:
            return .system(size: 16)
        }
    }

    static func body2(_ family: FontFamily = .pretendardRegular) -> Font {
        switch family {
        case .pretendardBold:
            return .custom(pretendardBold, size: 14)
        case .pretendardMedium:
            return .custom(pretendardMedium, size: 14)
        case .pretendardRegular:
            return .custom(pretendardRegular, size: 14)
        case .yeongdeok:
            return .custom(yeongdeokHaeparang, size: 14)
        case .system:
            return .system(size: 14)
        }
    }

    static func body3(_ family: FontFamily = .pretendardRegular) -> Font {
        switch family {
        case .pretendardBold:
            return .custom(pretendardBold, size: 13)
        case .pretendardMedium:
            return .custom(pretendardMedium, size: 13)
        case .pretendardRegular:
            return .custom(pretendardRegular, size: 13)
        case .yeongdeok:
            return .custom(yeongdeokHaeparang, size: 13)
        case .system:
            return .system(size: 13)
        }
    }

    // MARK: - Caption
    static func caption1(_ family: FontFamily = .pretendardRegular) -> Font {
        switch family {
        case .pretendardBold:
            return .custom(pretendardBold, size: 12)
        case .pretendardMedium:
            return .custom(pretendardMedium, size: 12)
        case .pretendardRegular:
            return .custom(pretendardRegular, size: 12)
        case .yeongdeok:
            return .custom(yeongdeokHaeparang, size: 12)
        case .system:
            return .system(size: 12)
        }
    }

    static func caption2(_ family: FontFamily = .pretendardRegular) -> Font {
        switch family {
        case .pretendardBold:
            return .custom(pretendardBold, size: 10)
        case .pretendardMedium:
            return .custom(pretendardMedium, size: 10)
        case .pretendardRegular:
            return .custom(pretendardRegular, size: 10)
        case .yeongdeok:
            return .custom(yeongdeokHaeparang, size: 10)
        case .system:
            return .system(size: 10)
        }
    }

    static func caption3(_ family: FontFamily = .pretendardRegular) -> Font {
        switch family {
        case .pretendardBold:
            return .custom(pretendardBold, size: 8)
        case .pretendardMedium:
            return .custom(pretendardMedium, size: 8)
        case .pretendardRegular:
            return .custom(pretendardRegular, size: 8)
        case .yeongdeok:
            return .custom(yeongdeokHaeparang, size: 8)
        case .system:
            return .system(size: 8)
        }
    }
}
