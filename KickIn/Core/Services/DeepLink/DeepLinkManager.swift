//
//  DeepLinkManager.swift
//  KickIn
//
//  Created by 서준일 on 01/18/26.
//

import Foundation
import Combine
import OSLog

@MainActor
final class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()

    @Published var pendingChatRoomId: String?
    @Published var shouldNavigateToChat: Bool = false

    private init() {}

    /// 푸시 알림 페이로드에서 채팅방 ID 추출 및 네비게이션 트리거
    func handlePushNotification(userInfo: [AnyHashable: Any]) {
        Logger.default.info("[DeepLinkManager] Handling push notification: \(userInfo)")

        // FCM 페이로드 파싱
        // 서버에서 room_id (언더스코어) 형식으로 전송
        if let roomId = userInfo["room_id"] as? String {
            Logger.default.info("[DeepLinkManager] Extracted room_id: \(roomId)")
            navigateToChatRoom(roomId: roomId)
        } else {
            Logger.default.warning("[DeepLinkManager] No room_id or roomId found in push notification payload")
        }
    }

    /// 채팅방으로 이동 트리거
    func navigateToChatRoom(roomId: String) {
        pendingChatRoomId = roomId
        shouldNavigateToChat = true
    }

    /// 네비게이션 완료 후 상태 리셋
    func resetNavigation() {
        Logger.default.info("[DeepLinkManager] Resetting navigation state")
        pendingChatRoomId = nil
        shouldNavigateToChat = false
    }
}
