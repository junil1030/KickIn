//
//  Int+Extension.swift
//  KickIn
//
//  Created by 서준일 on 02/04/26.
//

import Foundation

extension Int {
    /// 만원 단위 숫자를 표시용 문자열로 변환
    /// - 10,000만원 미만: 콤마 구분 (예: 5000 → "5,000")
    /// - 10,000만원 이상: 억 단위로 변환 (예: 50000 → "5억", 12345 → "1억2,345만")
    var formattedManwon: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        if self >= 10000 {
            let eok = self / 10000
            let remainder = self % 10000
            if remainder == 0 {
                return "\(eok)억"
            }
            let remainderStr = formatter.string(from: NSNumber(value: remainder)) ?? "\(remainder)"
            return "\(eok)억\(remainderStr)만"
        }
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
