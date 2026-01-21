//
//  PriceFormatter.swift
//  KickIn
//
//  Created by 서준일 on 01/13/26.
//

import Foundation

enum PriceFormatter {
    /// Formats estate price for marker display
    /// - Parameters:
    ///   - deposit: Deposit amount (원 단위)
    ///   - monthlyRent: Monthly rent (원 단위)
    /// - Returns: Formatted price string (e.g., "1000/60" or "전세 5억")
    static func formatForMarker(deposit: Int, monthlyRent: Int) -> String {
        // If monthly rent exists, show "보증금/월세" format
        if monthlyRent > 0 {
            let depositInMan = Double(deposit) / 10_000.0
            let monthlyInMan = Double(monthlyRent) / 10_000.0
            return "\(Int(depositInMan))/\(Int(monthlyInMan))"
        }

        // Otherwise, show "전세 X억" format
        let depositInEok = Double(deposit) / 100_000_000.0

        if depositInEok >= 1.0 {
            // 1억 이상: "전세 X억" or "전세 X.Y억"
            if depositInEok.truncatingRemainder(dividingBy: 1.0) == 0 {
                return "전세 \(Int(depositInEok))억"
            } else {
                return String(format: "전세 %.1f억", depositInEok)
            }
        } else {
            // 1억 미만: "전세 X천"
            let cheonman = Double(deposit) / 10_000_000.0
            return "전세 \(Int(cheonman))천"
        }
    }

    /// 금액을 한글 형식으로 변환 (필터용)
    /// - Parameter amount: 금액 (원 단위)
    /// - Returns: 포맷된 문자열 (예: "3천만", "1.5억")
    static func format(_ amount: Int) -> String {
        if amount == 0 {
            return "최소"
        }

        if amount >= 1_000_000_000 {
            // 10억 이상
            let billions = Double(amount) / 100_000_000.0
            if billions.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(billions))억"
            } else {
                return String(format: "%.1f억", billions)
            }
        } else if amount >= 100_000_000 {
            // 1억 이상
            let billions = Double(amount) / 100_000_000.0
            if billions.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(billions))억"
            } else {
                return String(format: "%.1f억", billions)
            }
        } else if amount >= 10_000_000 {
            // 1천만 이상
            let tenMillions = Double(amount) / 10_000_000.0
            if tenMillions.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(tenMillions))천만"
            } else {
                return String(format: "%.1f천만", tenMillions)
            }
        } else if amount >= 1_000_000 {
            // 100만 이상
            let millions = Double(amount) / 1_000_000.0
            if millions.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(millions))백만"
            } else {
                return String(format: "%.1f백만", millions)
            }
        } else if amount >= 10_000 {
            // 1만 이상
            let tenThousands = Double(amount) / 10_000.0
            if tenThousands.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(tenThousands))만"
            } else {
                return String(format: "%.1f만", tenThousands)
            }
        } else {
            return "\(amount)원"
        }
    }

    /// 면적을 포맷 (m²)
    static func formatArea(_ area: Double) -> String {
        if area == 0 {
            return "최소"
        } else if area >= 200 {
            return "최대"
        } else {
            return "\(Int(area))m²"
        }
    }
}
