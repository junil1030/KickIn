//
//  ChatMessagesObserver.swift
//  KickIn
//
//  Created by 서준일 on 01/15/26.
//

import Foundation
import SwiftUI
import Combine
import Realm
import RealmSwift
import OSLog

/// @ObservedResults를 사용하여 Realm 메시지를 자동으로 관찰하고
/// UI 렌더링용 ChatItem 배열로 변환하는 Observer 클래스
@MainActor
final class ChatMessagesObserver: ObservableObject {
    // MARK: - @ObservedResults

    @ObservedResults(
        ChatMessageObject.self,
        sortDescriptor: SortDescriptor(keyPath: "createdAt", ascending: false)
    ) private var allMessages

    // MARK: - Published Properties

    @Published private(set) var chatItems: [ChatItem] = []

    // MARK: - Private Properties

    private let roomId: String
    private var observationToken: NotificationToken?

    // MARK: - Computed Properties

    /// roomId로 필터링된 메시지 결과
    var filteredMessages: Results<ChatMessageObject> {
        allMessages.where { $0.roomId == self.roomId }
    }

    // MARK: - Initialization

    init(roomId: String) {
        self.roomId = roomId
        setupObservation()
        Logger.chat.info("📡 [ChatMessagesObserver] Initialized for room: \(roomId)")
    }

    deinit {
        observationToken?.invalidate()
        Logger.chat.info("📡 [ChatMessagesObserver] Deinit - observation token invalidated")
    }

    // MARK: - Private Methods

    /// Realm 변경 사항 관찰 설정
    private func setupObservation() {
        // 초기 변환 수행
        transformToChatItems()

        // NotificationToken을 사용하여 변경 사항 관찰
        observationToken = filteredMessages.observe { [weak self] changes in
            guard let self = self else { return }

            switch changes {
            case .initial:
                // 초기 데이터 로드 완료
                Logger.chat.info("📡 [ChatMessagesObserver] Initial data loaded: \(self.filteredMessages.count) messages")
                self.transformToChatItems()

            case .update(_, let deletions, let insertions, let modifications):
                // 데이터 변경 감지
                Logger.chat.info("📡 [ChatMessagesObserver] Update - deletions: \(deletions.count), insertions: \(insertions.count), modifications: \(modifications.count)")
                self.transformToChatItems()

            case .error(let error):
                Logger.chat.error("📡 [ChatMessagesObserver] Observation error: \(error.localizedDescription)")
            }
        }
    }

    /// Realm 객체를 ChatItem 배열로 변환
    /// MessageDisplayConfig 계산 및 날짜 헤더 삽입 포함
    private func transformToChatItems() {
        let messagesArray = Array(filteredMessages)
        var items: [ChatItem] = []

        // messages는 최신순 (index 0 = 최신, index n = 오래된)
        for (index, realmObject) in messagesArray.enumerated() {
            let uiModel = realmObject.toUIModel()
            let currentDateKey = uiModel.createdAt.toDateKey()
            let nextMessage = index < messagesArray.count - 1 ? messagesArray[index + 1] : nil
            let nextDateKey = nextMessage?.createdAt.toDateKey()

            // MessageDisplayConfig 계산
            // previous = 시간상 이전 메시지 (더 오래된 메시지, index + 1)
            // next = 시간상 다음 메시지 (더 최신 메시지, index - 1)
            let previous = index < messagesArray.count - 1 ? messagesArray[index + 1].toUIModel() : nil
            let next = index > 0 ? messagesArray[index - 1].toUIModel() : nil
            let config = MessageDisplayConfig.create(
                message: uiModel,
                previous: previous,
                next: next,
                roomId: roomId
            )

            // 메시지 먼저 추가
            items.append(.message(config: config))

            // 다음 메시지와 날짜가 다르면 (현재 메시지가 이 날짜의 첫 메시지)
            // 또는 마지막 메시지인 경우 (가장 오래된 메시지)
            if let currentDateKey = currentDateKey {
                if nextDateKey != currentDateKey || index == messagesArray.count - 1 {
                    // 날짜 헤더 추가 (reversed 후 메시지 위에 표시됨)
                    if let header = uiModel.createdAt.toChatSectionHeader() {
                        items.append(.dateHeader(date: currentDateKey, dateFormatted: header))
                    }
                }
            }
        }

        chatItems = items

        Logger.chat.info("📡 [ChatMessagesObserver] Transformed \(messagesArray.count) messages to \(items.count) chat items")
    }
}
