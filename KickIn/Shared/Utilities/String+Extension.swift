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

    var commentTimeAgo: String? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: self) else {
            return nil
        }

        let now = Date()
        let calendar = Calendar.current

        // 날짜가 같은지 확인
        if calendar.isDate(date, inSameDayAs: now) {
            // 같은 날이면 분/시간 차이 계산
            let components = calendar.dateComponents([.hour, .minute], from: date, to: now)
            let hours = components.hour ?? 0
            let minutes = components.minute ?? 0

            if hours == 0 {
                // 1시간 미만이면 분으로 표시
                return "\(minutes)분 전"
            } else {
                // 1시간 이상이면 시간으로 표시
                return "\(hours)시간 전"
            }
        } else {
            // 다른 날이면 일 차이 계산
            let components = calendar.dateComponents([.day], from: date, to: now)
            let days = components.day ?? 0
            return "\(days)일 전"
        }
    }

    /// ISO8601 날짜 문자열을 24시간 형식 시간으로 변환 (e.g., "14:30")
    /// - Returns: 시간 문자열 (HH:mm 형식), 변환 실패 시 nil
    func toChatTime() -> String? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: self) else {
            return nil
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul") // KST
        return timeFormatter.string(from: date)
    }

    /// ISO8601 날짜 문자열을 날짜 키로 변환 (e.g., "2025-01-06T10:30:00Z" → "2025-01-06")
    /// KST 기준으로 변환
    /// - Returns: 날짜 키 문자열 (YYYY-MM-DD 형식), 변환 실패 시 nil
    func toDateKey() -> String? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: self) else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul") // KST
        return dateFormatter.string(from: date)
    }

    /// ISO8601 날짜 문자열을 채팅 섹션 헤더로 변환 (e.g., "오늘", "어제", "2024년 1월 5일")
    /// KST 기준으로 변환
    /// - Returns: 채팅 섹션 헤더 문자열, 변환 실패 시 nil
    func toChatSectionHeader() -> String? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: self) else {
            return nil
        }

        let kstTimeZone = TimeZone(identifier: "Asia/Seoul")!
        var calendar = Calendar.current
        calendar.timeZone = kstTimeZone

        let now = Date()

        // 오늘인지 확인 (KST 기준)
        if calendar.isDate(date, inSameDayAs: now) {
            return "오늘"
        }

        // 어제인지 확인 (KST 기준)
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "어제"
        }

        // 그 외의 경우 "YYYY년 M월 d일" 형식으로 반환
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월 d일"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = kstTimeZone
        return dateFormatter.string(from: date)
    }
}
