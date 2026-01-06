//
//  ChatItem.swift
//  KickIn
//
//  Created by 서준일 on 01/06/26.
//

import Foundation

/// 채팅 화면에 표시되는 항목 (날짜 헤더 + 메시지)
enum ChatItem: Identifiable, Hashable {
    case dateHeader(date: String, dateFormatted: String)
    case message(config: MessageDisplayConfig)

    var id: String {
        switch self {
        case .dateHeader(let date, _):
            return "header_\(date)"
        case .message(let config):
            return config.id
        }
    }
}
