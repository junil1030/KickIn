//
//  Logger+Extension.swift
//  KickIn
//
//  Created by 서준일 on 12/17/25.
//

import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.junil.KickIn"

    // MARK: - Categories

    /// 네트워크 관련 로그 (API 호출, 응답, 에러)
    static let network = Logger(subsystem: subsystem, category: "Network")

    /// 인증 관련 로그 (로그인, 토큰 갱신)
    static let auth = Logger(subsystem: subsystem, category: "Auth")

    /// UI 관련 로그 (화면 전환, 사용자 인터랙션)
    static let ui = Logger(subsystem: subsystem, category: "UI")

    /// 데이터베이스 관련 로그
    static let database = Logger(subsystem: subsystem, category: "Database")

    /// 채팅 관련 로그 (메시지, SocketIO)
    static let chat = Logger(subsystem: subsystem, category: "Chat")

    /// 일반 로그
    static let `default` = Logger(subsystem: subsystem, category: "Default")
}
