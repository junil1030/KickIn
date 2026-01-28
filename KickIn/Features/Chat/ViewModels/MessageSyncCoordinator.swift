//
//  MessageSyncCoordinator.swift
//  KickIn
//
//  Created by 서준일 on 01/15/26.
//

import Foundation
import UIKit
import OSLog


actor MessageSyncCoordinator {
    // MARK: - Properties

    private(set) var state: SyncState = .idle
    private var messageBuffer: [ChatMessageItemDTO] = []
    private var processedChatIds: Set<String> = []
    private var syncLock: Bool = false

    // Dependencies
    private let repository: ChatMessageRepositoryProtocol
    private let networkService: NetworkServiceProtocol
    private let roomId: String
    private let myUserId: String
    private let opponentUserId: String

    // Callbacks
    private var onStateChange: ((SyncState) -> Void)?
    private var onMessagesUpdated: (() async -> Void)?

    // MARK: - Initialization

    init(
        repository: ChatMessageRepositoryProtocol,
        networkService: NetworkServiceProtocol,
        roomId: String,
        myUserId: String,
        opponentUserId: String
    ) {
        self.repository = repository
        self.networkService = networkService
        self.roomId = roomId
        self.myUserId = myUserId
        self.opponentUserId = opponentUserId
    }

    // MARK: - Callback Setters

    func setOnStateChange(_ callback: @escaping (SyncState) -> Void) {
        self.onStateChange = callback
    }

    func setOnMessagesUpdated(_ callback: @escaping () async -> Void) {
        self.onMessagesUpdated = callback
    }

    // MARK: - Public Methods

    func startSync() async throws {
        guard !syncLock else {
            Logger.chat.warning("⚠️ [MessageSyncCoordinator] Sync already in progress, skipping")
            return
        }

        syncLock = true
        defer { syncLock = false }

        updateState(.syncing(progress: .initial()))

        do {
            try await withExponentialBackoff { [self] in
                try await performSync()
            }

            await processBufferedMessages()
            updateState(.streaming)

            Logger.chat.info("✅ [MessageSyncCoordinator] Sync completed, now streaming")

        } catch let error as RetryError {
            Logger.chat.error("❌ [MessageSyncCoordinator] Sync failed after retries: \(error.localizedDescription)")
            updateState(.error(.maxRetriesExceeded))
            throw SyncError.maxRetriesExceeded

        } catch {
            Logger.chat.error("❌ [MessageSyncCoordinator] Sync failed: \(error.localizedDescription)")
            updateState(.error(.networkError(error.localizedDescription)))
            throw SyncError.networkError(error.localizedDescription)
        }
    }

    func bufferMessage(_ message: ChatMessageItemDTO) {
        guard let chatId = message.chatId else { return }

        if processedChatIds.contains(chatId) {
            Logger.chat.info("⏭️ [MessageSyncCoordinator] Skipping already processed message: \(chatId)")
            return
        }

        messageBuffer.append(message)
        Logger.chat.info("📦 [MessageSyncCoordinator] Buffered message: \(chatId)")
    }

    func processStreamMessage(_ message: ChatMessageItemDTO) -> Bool {
        guard let chatId = message.chatId else { return false }

        if processedChatIds.contains(chatId) {
            Logger.chat.info("⏭️ [MessageSyncCoordinator] Skipping duplicate stream message: \(chatId)")
            return false
        }

        switch state {
        case .streaming:
            processedChatIds.insert(chatId)
            Logger.chat.info("✅ [MessageSyncCoordinator] Processing stream message: \(chatId)")
            return true

        case .syncing:
            bufferMessage(message)
            return false

        default:
            bufferMessage(message)
            return false
        }
    }

    func reset() {
        state = .idle
        messageBuffer.removeAll()
        processedChatIds.removeAll()
        syncLock = false
        Logger.chat.info("🔄 [MessageSyncCoordinator] Reset completed")
    }

    func getState() -> SyncState {
        return state
    }

    // MARK: - Private Methods

    private func updateState(_ newState: SyncState) {
        state = newState
        Logger.chat.info("🔄 [MessageSyncCoordinator] State changed to: \(String(describing: newState))")
        onStateChange?(newState)
    }

    private func performSync() async throws {
        updateState(.syncing(progress: SyncProgress(phase: .checkingGap, fetchedCount: 0, totalEstimate: nil)))

        // 1. Get local last message's createdAt (non-temporary)
        let localMessages = try await repository.fetchMessagesAsUIModels(roomId: roomId, limit: 1, beforeDate: nil)
        let localLastMessage = localMessages.first(where: { !$0.isTemporary })
        let localLastCreatedAt = localLastMessage?.createdAt

        // 2. Check server's latest message via createOrGetChatRoom
        let requestDTO = CreateChatRoomRequestDTO(opponentId: opponentUserId)
        let chatRoomResponse: ChatRoomResponseDTO = try await networkService.request(
            ChatRouter.createOrGetChatRoom(requestDTO)
        )

        // 참가자 정보로 UserObject 업데이트 (프로필 변경 반영)
        if let participants = chatRoomResponse.participants {
            for participant in participants {
                if let userId = participant.userId {
                    _ = try await repository.getOrCreateUser(
                        userId: userId,
                        nickname: participant.nick ?? "알 수 없는 사용자",
                        profileImage: participant.profileImage,
                        introduction: participant.introduction
                    )
                }
            }
            Logger.chat.info("👤 [MessageSyncCoordinator] Updated \(participants.count) participants' profiles")
        }

        let serverLastChatId = chatRoomResponse.lastChat?.chatId
        Logger.chat.info("📊 [MessageSyncCoordinator] Gap check - Local: \(localLastMessage?.id ?? "nil"), Server: \(serverLastChatId ?? "nil")")

        // 3. Compare and determine action
        if localLastMessage?.id == serverLastChatId, serverLastChatId != nil {
            Logger.chat.info("✅ [MessageSyncCoordinator] No gap detected, already synced")
            return
        }

        if localLastCreatedAt == nil {
            Logger.chat.info("📥 [MessageSyncCoordinator] No local messages, performing full sync")
            try await fetchFullMessageHistory()
        } else {
            Logger.chat.info("⚠️ [MessageSyncCoordinator] Gap detected, fetching missing messages")
            try await fetchMissingMessagesWithPagination(afterCreatedAt: localLastCreatedAt!)
        }
    }

    private func fetchMissingMessagesWithPagination(afterCreatedAt: String) async throws {
        var allFetchedMessages: [ChatMessageItemDTO] = []
        var currentCursor: String? = afterCreatedAt  // 로컬 마지막 메시지 시간부터 시작
        var hasMore = true
        var page = 1

        while hasMore {
            updateState(.syncing(progress: SyncProgress(
                phase: .fetchingMessages(page: page),
                fetchedCount: allFetchedMessages.count,
                totalEstimate: nil
            )))

            Logger.chat.info("📥 [MessageSyncCoordinator] Fetching messages with cursor: \(currentCursor ?? "nil")")

            let response: ChatMessagesResponseDTO = try await networkService.request(
                ChatRouter.getChatMessages(roomId: roomId, next: currentCursor)
            )

            guard let messages = response.data, !messages.isEmpty else {
                hasMore = false
                break
            }

            for message in messages {
                if let chatId = message.chatId {
                    processedChatIds.insert(chatId)
                }
                allFetchedMessages.append(message)
            }

            if messages.count >= 50 {
                currentCursor = messages.last?.createdAt
                page += 1
            } else {
                hasMore = false
            }

            Logger.chat.info("📥 [MessageSyncCoordinator] Page \(page - 1): Fetched \(messages.count) messages, total collected: \(allFetchedMessages.count)")
        }

        if !allFetchedMessages.isEmpty {
            updateState(.syncing(progress: SyncProgress(
                phase: .savingToRealm,
                fetchedCount: allFetchedMessages.count,
                totalEstimate: allFetchedMessages.count
            )))

            try await repository.saveMessagesFromDTOs(allFetchedMessages, roomId: roomId, myUserId: myUserId)
            await onMessagesUpdated?()

            Logger.chat.info("💾 [MessageSyncCoordinator] Saved \(allFetchedMessages.count) missing messages")
        }
    }

    private func fetchFullMessageHistory() async throws {
        var allFetchedMessages: [ChatMessageItemDTO] = []
        var currentCursor: String? = nil
        var hasMore = true
        var page = 1

        while hasMore {
            updateState(.syncing(progress: SyncProgress(
                phase: .fetchingMessages(page: page),
                fetchedCount: allFetchedMessages.count,
                totalEstimate: nil
            )))

            let response: ChatMessagesResponseDTO = try await networkService.request(
                ChatRouter.getChatMessages(roomId: roomId, next: currentCursor)
            )

            guard let messages = response.data, !messages.isEmpty else {
                hasMore = false
                break
            }

            for message in messages {
                if let chatId = message.chatId {
                    processedChatIds.insert(chatId)
                }
            }
            allFetchedMessages.append(contentsOf: messages)

            if messages.count >= 50 {
                currentCursor = messages.last?.createdAt
                page += 1
            } else {
                hasMore = false
            }

            Logger.chat.info("📥 [MessageSyncCoordinator] Full sync page \(page - 1): Fetched \(messages.count) messages")
        }

        if !allFetchedMessages.isEmpty {
            updateState(.syncing(progress: SyncProgress(
                phase: .savingToRealm,
                fetchedCount: allFetchedMessages.count,
                totalEstimate: allFetchedMessages.count
            )))

            try await repository.saveMessagesFromDTOs(allFetchedMessages, roomId: roomId, myUserId: myUserId)
            await onMessagesUpdated?()

            Logger.chat.info("💾 [MessageSyncCoordinator] Full sync saved \(allFetchedMessages.count) messages")
        }
    }

    private func processBufferedMessages() async {
        guard !messageBuffer.isEmpty else { return }

        updateState(.syncing(progress: SyncProgress(
            phase: .processingQueue,
            fetchedCount: messageBuffer.count,
            totalEstimate: messageBuffer.count
        )))

        let sortedBuffer = messageBuffer.sorted {
            ($0.createdAt ?? "") < ($1.createdAt ?? "")
        }

        var uniqueMessages: [ChatMessageItemDTO] = []
        for message in sortedBuffer {
            guard let chatId = message.chatId,
                  !processedChatIds.contains(chatId) else { continue }
            uniqueMessages.append(message)
            processedChatIds.insert(chatId)
        }

        if !uniqueMessages.isEmpty {
            try? await repository.saveMessagesFromDTOs(uniqueMessages, roomId: roomId, myUserId: myUserId)
            await onMessagesUpdated?()

            Logger.chat.info("📦 [MessageSyncCoordinator] Processed \(uniqueMessages.count) buffered messages")
        }

        messageBuffer.removeAll()
    }
}
