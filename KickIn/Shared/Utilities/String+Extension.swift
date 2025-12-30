//
//  String+Extension.swift
//  KickIn
//
//  Created by 서준일 on 12/22/25.
//

import Foundation

extension String {
    var thumbnailURL: URL? {
        let urlString = APIConfig.baseURL + self
        return URL(string: urlString)
    }

    var timeAgoFromNow: String? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: self) else {
            return nil
        }

        let now = Date()
        let calendar = Calendar.current

        // 날짜가 같은지 확인
        if calendar.isDate(date, inSameDayAs: now) {
            // 같은 날이면 시간 차이 계산
            let components = calendar.dateComponents([.hour], from: date, to: now)
            let hours = components.hour ?? 0
            return "\(hours)시간 전"
        } else {
            // 다른 날이면 일 차이 계산
            let components = calendar.dateComponents([.day], from: date, to: now)
            let days = components.day ?? 0
            return "\(days)일 전"
        }
    }
}
