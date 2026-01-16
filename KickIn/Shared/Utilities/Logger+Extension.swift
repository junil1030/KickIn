//
//  Logger+Extension.swift
//  KickIn
//
//  Created by 서준일 on 12/17/25.
//

import OSLog

extension Logger {
    nonisolated private static let subsystem = Bundle.main.bundleIdentifier ?? "com.junil.KickIn"

    // MARK: - Categories

    /// 네트워크 관련 로그 (API 호출, 응답, 에러)
    nonisolated static let network = Logger(subsystem: subsystem, category: "Network")

    /// 인증 관련 로그 (로그인, 토큰 갱신)
    nonisolated static let auth = Logger(subsystem: subsystem, category: "Auth")

    /// UI 관련 로그 (화면 전환, 사용자 인터랙션)
    nonisolated static let ui = Logger(subsystem: subsystem, category: "UI")

    /// 데이터베이스 관련 로그
    nonisolated static let database = Logger(subsystem: subsystem, category: "Database")

    /// 채팅 관련 로그 (메시지, SocketIO)
    nonisolated static let chat = Logger(subsystem: subsystem, category: "Chat")

    /// 프로필 관련 로그 (프로필 조회, 수정, 이미지 업로드)
    nonisolated static let profile = Logger(subsystem: subsystem, category: "Profile")

    /// 일반 로그
    nonisolated static let `default` = Logger(subsystem: subsystem, category: "Default")
}
