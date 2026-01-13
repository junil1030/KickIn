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
}
