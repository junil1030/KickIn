//
//  MessageDisplayConfig.swift
//  KickIn
//
//  Created by 서준일 on 01/06/26.
//

import Foundation

/// 채팅 메시지의 UI 표시 설정을 관리하는 모델
/// 카카오톡 스타일 연속 메시지 처리: 프로필 숨김, 시간 최적화
struct MessageDisplayConfig: Identifiable, Hashable {
    let id: String
    let message: ChatMessageUIModel
    let showProfile: Bool    // 프로필 이미지 표시 여부
    let showNickname: Bool   // 닉네임 표시 여부
    let showTime: Bool       // 시간 표시 여부
    let roomId: String?      // 채팅방 ID (미디어 파일 로드용)

    /// MessageDisplayConfig 생성
    /// - Parameters:
    ///   - message: 현재 메시지
    ///   - previous: 이전 메시지 (없으면 nil)
    ///   - next: 다음 메시지 (없으면 nil)
    ///   - roomId: 채팅방 ID
    /// - Returns: 계산된 MessageDisplayConfig
    static func create(
        message: ChatMessageUIModel,
        previous: ChatMessageUIModel?,
        next: ChatMessageUIModel?,
        roomId: String? = nil
    ) -> MessageDisplayConfig {
        let showProfile = shouldShowProfile(message: message, previous: previous)
        let showNickname = showProfile // 프로필과 닉네임은 동일한 조건
        let showTime = shouldShowTime(message: message, next: next)

        return MessageDisplayConfig(
            id: message.id,
            message: message,
            showProfile: showProfile,
            showNickname: showNickname,
            showTime: showTime,
            roomId: roomId
        )
    }

    // MARK: - Private Helper Methods

    /// 프로필 이미지를 표시할지 결정
    /// - Parameters:
    ///   - message: 현재 메시지
    ///   - previous: 이전 메시지
    /// - Returns: 프로필 표시 여부
    private static func shouldShowProfile(
        message: ChatMessageUIModel,
        previous: ChatMessageUIModel?
    ) -> Bool {
        // 내 메시지는 프로필 안 보여줌
        if message.isSentByMe {
            return false
        }

        // 이전 메시지가 없으면 무조건 표시
        guard let previous = previous else {
            return true
        }

        // 이전 메시지가 내 메시지면 표시
        if previous.isSentByMe {
            return true
        }

        // 이전 메시지와 발신자가 다르면 표시
        if previous.senderNickname != message.senderNickname {
            return true
        }

        // 이전 메시지와 날짜가 다르면 표시 (날짜 구분선 기준)
        if !isSameDate(previous.createdAt, message.createdAt) {
            return true
        }

        // 이전 메시지와 발신자가 같고 날짜도 같으면 숨김
        return false
    }

    /// 시간을 표시할지 결정
    /// - Parameters:
    ///   - message: 현재 메시지
    ///   - next: 다음 메시지
    /// - Returns: 시간 표시 여부
    private static func shouldShowTime(
        message: ChatMessageUIModel,
        next: ChatMessageUIModel?
    ) -> Bool {
        // 다음 메시지가 없으면 무조건 표시
        guard let next = next else {
            return true
        }

        // 다음 메시지가 상대방 메시지면 표시
        if message.isSentByMe != next.isSentByMe {
            return true
        }

        // 다음 메시지와 발신자가 다르면 표시
        if message.senderNickname != next.senderNickname {
            return true
        }

        // 다음 메시지와 같은 분이 아니면 표시
        if !isSameMinute(message.createdAt, next.createdAt) {
            return true
        }

        // 다음 메시지와 발신자가 같고 같은 분이면 숨김
        return false
    }

    /// 두 날짜가 같은 날인지 확인
    /// - Parameters:
    ///   - date1: 첫 번째 날짜 문자열 (ISO8601)
    ///   - date2: 두 번째 날짜 문자열 (ISO8601)
    /// - Returns: 같은 날이면 true
    private static func isSameDate(_ date1: String, _ date2: String) -> Bool {
        guard let dateKey1 = date1.toDateKey(),
              let dateKey2 = date2.toDateKey() else {
            return false
        }
        return dateKey1 == dateKey2
    }

    /// 두 시간이 같은 분인지 확인 (KST 기준)
    /// - Parameters:
    ///   - time1: 첫 번째 시간 문자열 (ISO8601)
    ///   - time2: 두 번째 시간 문자열 (ISO8601)
    /// - Returns: 같은 분이면 true
    private static func isSameMinute(_ time1: String, _ time2: String) -> Bool {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date1 = formatter.date(from: time1),
              let date2 = formatter.date(from: time2) else {
            return false
        }

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")! // KST 기준
        let components1 = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date1)
        let components2 = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date2)

        return components1.year == components2.year &&
               components1.month == components2.month &&
               components1.day == components2.day &&
               components1.hour == components2.hour &&
               components1.minute == components2.minute
    }
}
