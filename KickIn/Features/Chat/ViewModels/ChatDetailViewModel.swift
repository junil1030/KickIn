//
//  ChatDetailViewModel.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation
import Combine
import OSLog
import UIKit

@MainActor
final class ChatDetailViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var chatItems: [ChatItem] = []  // UI 렌더링용 (날짜 헤더 + 메시지)
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMoreData = true
    @Published var errorMessage: String?

    // MARK: - Private Properties

    let roomId: String
    private(set) var myUserId: String = ""
    private var myNickname: String = ""
    private var myProfileImage: String?

    private var messages: [ChatMessageUIModel] = []  // 내부 데이터용

    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    private let tokenStorage = NetworkServiceFactory.shared.getTokenStorage()
    private let repository: ChatMessageRepositoryProtocol
    private let socketService: SocketServiceProtocol

    private var connectionTask: Task<Void, Never>?
    private var messageTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        roomId: String,
        repository: ChatMessageRepositoryProtocol = ChatMessageRepository(),
        socketService: SocketServiceProtocol = SocketService.shared
    ) {
        self.roomId = roomId
        self.repository = repository
        self.socketService = socketService
    }

    deinit {
        connectionTask?.cancel()
        messageTask?.cancel()
    }

    // MARK: - Public Methods

    func loadInitialMessages() async {
        isLoading = true
        errorMessage = nil

        // 내 정보 조회
        myUserId = await tokenStorage.getUserId() ?? ""

        do {
            // 1. Realm에서 로컬 메시지 로드 (즉시 표시)
            messages = try await repository.fetchMessagesAsUIModels(roomId: roomId, limit: 50, beforeDate: nil)
            updateChatItems()

            // 2. AsyncStream 준비 및 구독 시작
            socketService.prepareNewConnection()
            connectWebSocket()

            // 3. Socket 연결
            await socketService.connect(roomID: roomId)

            Logger.chat.info("✅ Loaded \(self.messages.count) messages for room \(self.roomId)")

        } catch let error as NetworkError {
            Logger.chat.error("❌ Failed to load messages: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            Logger.chat.error("❌ Unknown error: \(error.localizedDescription)")
            errorMessage = "메시지를 불러오는데 실패했습니다."
        }

        isLoading = false
    }

    func loadMoreMessages() async {
        guard hasMoreData, !isLoadingMore else { return }

        isLoadingMore = true

        let oldestMessage = messages.last
        let cursor = oldestMessage?.createdAt

        do {
            let response: ChatMessagesResponseDTO = try await networkService.request(
                ChatRouter.getChatMessages(roomId: roomId, next: cursor)
            )

            guard let newMessages = response.data, !newMessages.isEmpty else {
                hasMoreData = false
                isLoadingMore = false
                return
            }

            // Realm에 저장 (DTO를 직접 Repository에 전달)
            for messageDTO in newMessages {
                try await repository.saveMessageFromDTO(messageDTO, myUserId: myUserId)
            }

            // UI 업데이트 - Repository에서 UIModel로 변환해서 가져오기
            let newUIModels = try await repository.fetchMessagesAsUIModels(
                roomId: roomId,
                limit: newMessages.count,
                beforeDate: cursor
            )
            messages.append(contentsOf: newUIModels)
            hasMoreData = newMessages.count >= 50

            // chatItems 업데이트
            updateChatItems()

            Logger.chat.info("📥 Loaded \(newMessages.count) more messages")

        } catch {
            Logger.chat.error("❌ Failed to load more messages: \(error)")
        }

        isLoadingMore = false
    }

    func sendMessage(content: String?, images: [UIImage]) async {
        var filePaths: [String] = []

        // 1. 이미지 업로드
        if !images.isEmpty {
            do {
                filePaths = try await uploadImages(images)
            } catch {
                Logger.chat.error("❌ Failed to upload images: \(error)")
                errorMessage = "이미지 업로드에 실패했습니다."
                return
            }
        }

        // 2. 메시지 전송
        await sendMessageWithFiles(content: content, filePaths: filePaths)
    }

    func disconnect() {
        socketService.disconnect()
    }

    // MARK: - Private Methods

    /// messages 배열을 chatItems로 변환 (날짜 헤더 자동 삽입 + displayConfig 계산)
    private func updateChatItems() {
        var items: [ChatItem] = []

        // messages는 최신순 (index 0 = 최신, index n = 오래된)
        for (index, message) in messages.enumerated() {
            let currentDateKey = message.createdAt.toDateKey()
            let nextMessage = index < messages.count - 1 ? messages[index + 1] : nil
            let nextDateKey = nextMessage?.createdAt.toDateKey()

            // MessageDisplayConfig 계산
            // previous = 시간상 이전 메시지 (더 오래된 메시지, index + 1)
            // next = 시간상 다음 메시지 (더 최신 메시지, index - 1)
            let previous = index < messages.count - 1 ? messages[index + 1] : nil
            let next = index > 0 ? messages[index - 1] : nil
            let config = MessageDisplayConfig.create(message: message, previous: previous, next: next)

            // 메시지 먼저 추가
            items.append(.message(config: config))

            // 다음 메시지와 날짜가 다르면 (현재 메시지가 이 날짜의 첫 메시지)
            // 또는 마지막 메시지인 경우 (가장 오래된 메시지)
            if let currentDateKey = currentDateKey {
                if nextDateKey != currentDateKey || index == messages.count - 1 {
                    // 날짜 헤더 추가 (reversed 후 메시지 위에 표시됨)
                    if let header = message.createdAt.toChatSectionHeader() {
                        items.append(.dateHeader(date: currentDateKey, dateFormatted: header))
                    }
                }
            }
        }

        chatItems = items
    }

    private func connectWebSocket() {
        Logger.chat.info("🎧 [ChatDetailViewModel] Setting up AsyncStream listeners for room: \(self.roomId)")

        // 메시지 수신 스트림 구독
        messageTask = Task { [weak self] in
            guard let self = self else { return }

            for await messageDTO in socketService.messages {
                Logger.chat.info("📬 [ChatDetailViewModel] Received message: \(messageDTO.chatId ?? "unknown")")

                // Socket으로 받은 메시지를 Realm에 저장 (DTO 그대로 전달)
                try? await self.repository.saveMessageFromDTO(messageDTO, myUserId: self.myUserId)

                // UI 업데이트 (중복 방지)
                let chatId = messageDTO.chatId ?? ""
                if !self.messages.contains(where: { $0.id == chatId }) {
                    let uiModel = ChatMessageUIModel(
                        id: chatId,
                        content: messageDTO.content,
                        createdAt: messageDTO.createdAt ?? ISO8601DateFormatter().string(from: Date()),
                        senderNickname: messageDTO.sender?.nick ?? "알 수 없음",
                        senderProfileImage: messageDTO.sender?.profileImage,
                        files: messageDTO.files ?? [],
                        isSentByMe: messageDTO.sender?.userId == self.myUserId,
                        isTemporary: false,
                        sendFailed: false
                    )
                    self.messages.insert(uiModel, at: 0)

                    // chatItems 업데이트
                    self.updateChatItems()

                    Logger.chat.info("✅ [ChatDetailViewModel] Added new message to UI: \(chatId)")
                } else {
                    Logger.chat.info("⚠️ [ChatDetailViewModel] Message already exists, skipping: \(chatId)")
                }
            }
        }

        Logger.chat.info("✅ [ChatDetailViewModel] AsyncStream listeners setup complete")
    }

    private func syncMessagesWithAPI(
        apiMessages: [ChatMessageItemDTO]
    ) async throws {
        // Realm에서 chatId Set만 가져오기 (Thread-safe)
        let localChatIds = try await repository.fetchChatIds(roomId: roomId)
        let apiChatIds = Set(apiMessages.compactMap { $0.chatId })

        // API에는 있지만 Realm에 없는 메시지 (유실 메시지)
        let missingChatIds = apiChatIds.subtracting(localChatIds)

        if !missingChatIds.isEmpty {
            Logger.chat.info("⚠️ Found \(missingChatIds.count) missing messages")

            // 유실된 메시지를 DTO로 Repository에 저장
            let missingMessages = apiMessages.filter { missingChatIds.contains($0.chatId ?? "") }
            for messageDTO in missingMessages {
                try await repository.saveMessageFromDTO(messageDTO, myUserId: myUserId)
            }
        }

        // Realm의 temporary 메시지 중 API에 있는 것들을 확인 처리
        // (Repository에서 직접 처리하도록 메서드 추가 필요 시 추가)
        for apiChatId in apiChatIds {
            try? await repository.updateMessageStatus(
                chatId: apiChatId,
                isTemporary: false,
                failReason: nil
            )
        }
    }

    private func uploadImages(_ images: [UIImage]) async throws -> [String] {
        let files = images.compactMap { image -> (data: Data, name: String, fileName: String, mimeType: String)? in
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
            let fileName = "chat_\(UUID().uuidString).jpg"
            return (data: imageData, name: "files", fileName: fileName, mimeType: "image/jpeg")
        }

        let response: ChatFilesResponseDTO = try await networkService.upload(
            ChatRouter.uploadFiles(roomId: roomId),
            files: files
        )

        return response.files ?? []
    }

    private func sendMessageWithFiles(content: String?, filePaths: [String]) async {
        // Optimistic UI: 임시 메시지 생성
        let tempChatId = UUID().uuidString
        let createdAt = ISO8601DateFormatter().string(from: Date())

        // Realm Actor 내부에서 객체 생성
        try? await repository.createAndSaveMessage(
            chatId: tempChatId,
            roomId: roomId,
            content: content,
            createdAt: createdAt,
            updatedAt: nil,
            senderUserId: myUserId,
            senderNickname: myNickname.isEmpty ? "나" : myNickname,
            senderProfileImage: myProfileImage,
            senderIntroduction: nil,
            files: filePaths,
            isSentByMe: true,
            isTemporary: true
        )

        // UI 업데이트용 모델
        let tempUIModel = ChatMessageUIModel(
            id: tempChatId,
            content: content,
            createdAt: createdAt,
            senderNickname: myNickname.isEmpty ? "나" : myNickname,
            senderProfileImage: myProfileImage,
            files: filePaths,
            isSentByMe: true,
            isTemporary: true,
            sendFailed: false
        )
        messages.insert(tempUIModel, at: 0)

        // chatItems 업데이트
        updateChatItems()

        do {
            // HTTP API로 메시지 전송
            let requestDTO = SendMessageRequestDTO(content: content, files: filePaths)
            let response: ChatMessageResponseDTO = try await networkService.request(
                ChatRouter.sendMessage(roomId: roomId, requestDTO)
            )

            // 서버 응답의 실제 chatId로 교체
            if let serverChatId = response.chatId {
                try await repository.deleteMessage(chatId: tempChatId)

                try await repository.createAndSaveMessage(
                    chatId: serverChatId,
                    roomId: roomId,
                    content: content,
                    createdAt: response.createdAt ?? createdAt,
                    updatedAt: response.updatedAt,
                    senderUserId: myUserId,
                    senderNickname: myNickname.isEmpty ? "나" : myNickname,
                    senderProfileImage: myProfileImage,
                    senderIntroduction: nil,
                    files: filePaths,
                    isSentByMe: true,
                    isTemporary: false
                )

                // UI 업데이트
                let realUIModel = ChatMessageUIModel(
                    id: serverChatId,
                    content: content,
                    createdAt: response.createdAt ?? createdAt,
                    senderNickname: myNickname.isEmpty ? "나" : myNickname,
                    senderProfileImage: myProfileImage,
                    files: filePaths,
                    isSentByMe: true,
                    isTemporary: false,
                    sendFailed: false
                )

                if let index = messages.firstIndex(where: { $0.id == tempChatId }) {
                    messages[index] = realUIModel
                }

                // chatItems 업데이트
                updateChatItems()

                Logger.chat.info("✅ Message sent successfully: \(serverChatId)")
            }

        } catch {
            Logger.chat.error("❌ Failed to send message: \(error)")
            try? await repository.updateMessageStatus(
                chatId: tempChatId,
                isTemporary: true,
                failReason: error.localizedDescription
            )

            if let index = messages.firstIndex(where: { $0.id == tempChatId }) {
                messages[index] = ChatMessageUIModel(
                    id: tempChatId,
                    content: content,
                    createdAt: createdAt,
                    senderNickname: myNickname.isEmpty ? "나" : myNickname,
                    senderProfileImage: myProfileImage,
                    files: filePaths,
                    isSentByMe: true,
                    isTemporary: true,
                    sendFailed: true
                )
            }

            // chatItems 업데이트
            updateChatItems()
        }
    }
}
