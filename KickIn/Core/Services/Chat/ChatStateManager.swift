//
//  ChatStateManager.swift
//  KickIn
//
//  Created by 서준일 on 01/18/26.
//

import Foundation
import Combine
import OSLog

/// 현재 활성화된 채팅방 추적을 위한 매니저
@MainActor
final class ChatStateManager: ObservableObject {
    static let shared = ChatStateManager()

    /// 현재 사용자가 보고 있는 채팅방 ID (nil이면 채팅방에 없음)
    @Published private(set) var activeChatRoomId: String?

    private init() {}

    /// 채팅방 진입 시 호출
    func enterChatRoom(_ roomId: String) {
        Logger.chat.info("[ChatStateManager] Entering chat room: \(roomId)")
        activeChatRoomId = roomId
    }

    /// 채팅방 퇴장 시 호출
    func leaveChatRoom() {
        if let roomId = activeChatRoomId {
            Logger.chat.info("[ChatStateManager] Leaving chat room: \(roomId)")
        }
        activeChatRoomId = nil
    }

    /// 특정 채팅방이 현재 활성화되어 있는지 확인
    func isActiveChatRoom(_ roomId: String) -> Bool {
        return activeChatRoomId == roomId
    }
}
