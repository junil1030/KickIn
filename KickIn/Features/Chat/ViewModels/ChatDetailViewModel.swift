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
    @Published var allMediaItems: [MediaItem] = []  // 채팅방 내 모든 미디어
    @Published var videoUploadProgress: [String: VideoUploadProgress] = [:]  // 비디오 업로드 진행률

    // MARK: - Private Properties

    let roomId: String
    let opponentUserId: String
    private(set) var myUserId: String = ""
    private var myNickname: String = ""
    private var myProfileImage: String?

    private var messages: [ChatMessageUIModel] = []  // 내부 데이터용
    private var messageQueue: [ChatMessageItemDTO] = []  // 동기화 전 수신 메시지 큐
    private var isRealmSynced = false  // API 동기화 완료 플래그

    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    private let tokenStorage = NetworkServiceFactory.shared.getTokenStorage()
    private let repository: ChatMessageRepositoryProtocol
    private let socketService: SocketServiceProtocol
    private let videoUploadService: VideoUploadService

    private var connectionTask: Task<Void, Never>?
    private var messageTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        roomId: String,
        opponentUserId: String,
        repository: ChatMessageRepositoryProtocol = ChatMessageRepository(),
        socketService: SocketServiceProtocol = SocketService.shared,
        networkService: NetworkServiceProtocol = NetworkServiceFactory.shared.makeNetworkService()
    ) {
        self.roomId = roomId
        self.opponentUserId = opponentUserId
        self.repository = repository
        self.socketService = socketService
        self.videoUploadService = VideoUploadService(networkService: networkService)
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

            // 2. 기존 Task 취소
            connectionTask?.cancel()
            messageTask?.cancel()

            // 3. AsyncStream 구독 시작
            connectWebSocket()

            Logger.chat.info("✅ Stream subscription started")

            // 4. Socket 연결
            await socketService.connect(roomID: roomId)

            Logger.chat.info("✅ Socket connected, starting API sync")

            // 5. API 동기화
            await fetchAndSync()

            Logger.chat.info("✅ Initial load complete: \(self.messages.count) messages for room \(self.roomId)")

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

    func sendMessage(content: String?, images: [UIImage], videos: [URL]) async {
        var filePaths: [String] = []
        var localThumbnailURLs: [URL] = []  // Optimistic UI용 로컬 URL 저장

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

        // 2. 비디오 업로드
        for videoURL in videos {
            do {
                let result = try await uploadVideo(videoURL)

                // 서버 응답 순서: [thumbnailURL, videoURL]
                filePaths.append(result.thumbnailURL)
                filePaths.append(result.videoURL)

                // Optimistic UI용 로컬 썸네일 URL 저장
                localThumbnailURLs.append(result.localThumbnailURL)

            } catch {
                Logger.chat.error("❌ Failed to upload video: \(error)")
                errorMessage = "비디오 업로드에 실패했습니다."
                return
            }
        }

        // 3. 메시지 전송 (Optimistic UI와 함께)
        await sendMessageWithFiles(
            content: content,
            filePaths: filePaths,
            localThumbnailURLs: localThumbnailURLs
        )
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
            let config = MessageDisplayConfig.create(message: message, previous: previous, next: next, roomId: roomId)

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
        extractMediaFromMessages()
    }

    /// 메시지에서 미디어 아이템 추출 (톡서랍용)
    private func extractMediaFromMessages() {
        allMediaItems = messages
            .flatMap { $0.mediaItems(roomId: roomId) }
            .sorted { $0.createdAt > $1.createdAt }  // 최신순 정렬

        Logger.chat.info("📸 [ChatDetailViewModel] Extracted \(self.allMediaItems.count) media items from \(self.messages.count) messages")
    }

    /// API에서 최신 메시지를 가져와 Realm과 동기화 (최적화: lastChat 비교)
    private func fetchAndSync() async {
        Logger.chat.info("🔄 [ChatDetailViewModel] Starting optimized API sync for room: \(self.roomId)")

        do {
            // 1. createOrGetChatRoom으로 lastChat 확인
            let requestDTO = CreateChatRoomRequestDTO(opponentId: opponentUserId)
            let chatRoomResponse: ChatRoomResponseDTO = try await networkService.request(
                ChatRouter.createOrGetChatRoom(requestDTO)
            )

            let serverLastChatId = chatRoomResponse.lastChat?.chatId
            Logger.chat.info("📊 [ChatDetailViewModel] Server lastChatId: \(serverLastChatId ?? "nil")")

            // 2. Realm의 최신 메시지 확인 (temporary가 아닌 것 중)
            let realmLastMessage = messages.first(where: { !$0.isTemporary })
            Logger.chat.info("📊 [ChatDetailViewModel] Realm lastChatId: \(realmLastMessage?.id ?? "nil")")

            // 3. 비교 결과에 따라 동기화 전략 결정
            if serverLastChatId == realmLastMessage?.id, serverLastChatId != nil {
                // 같으면: 이미 동기화됨, 임시 메시지만 정리
                Logger.chat.info("✅ [ChatDetailViewModel] Already synced, cleaning up temporary messages only")
                await cleanupFailedTemporaryMessages()
            } else {
                // 다르면: 전체 동기화 수행
                Logger.chat.info("🔄 [ChatDetailViewModel] Sync needed, fetching full messages")
                await performFullSync()
            }

            isRealmSynced = true
            await processQueuedMessages()

        } catch {
            Logger.chat.error("❌ [ChatDetailViewModel] Failed to check lastChat: \(error)")
            // 실패 시 전체 동기화 시도
            await performFullSync()
            isRealmSynced = true
            await processQueuedMessages()
        }
    }

    /// 전체 메시지 동기화 수행
    private func performFullSync() async {
        do {
            // API에서 최신 메시지 가져오기
            let response: ChatMessagesResponseDTO = try await networkService.request(
                ChatRouter.getChatMessages(roomId: roomId, next: nil)
            )

            guard let apiMessages = response.data else {
                Logger.chat.info("⚠️ No messages from API")
                return
            }

            // Realm과 API 메시지 동기화
            try await syncMessagesWithAPI(apiMessages: apiMessages)

            // 동기화 완료 후 Realm에서 최신 데이터 다시 로드
            messages = try await repository.fetchMessagesAsUIModels(roomId: roomId, limit: 50, beforeDate: nil)
            updateChatItems()

            // 임시 메시지 정리
            await cleanupFailedTemporaryMessages()

            Logger.chat.info("✅ [ChatDetailViewModel] Full sync completed")

        } catch {
            Logger.chat.error("❌ [ChatDetailViewModel] Failed to perform full sync: \(error)")
        }
    }

    /// 서버에 없는 실패한 임시 메시지 정리
    private func cleanupFailedTemporaryMessages() async {
        let temporaryMessages = messages.filter { $0.isTemporary }

        guard !temporaryMessages.isEmpty else {
            Logger.chat.info("✅ [ChatDetailViewModel] No temporary messages to clean up")
            return
        }

        Logger.chat.info("🧹 [ChatDetailViewModel] Cleaning up \(temporaryMessages.count) temporary messages")

        for tempMessage in temporaryMessages {
            // Realm에서 삭제
            try? await repository.deleteMessage(chatId: tempMessage.id)

            // UI에서 제거
            if let index = messages.firstIndex(where: { $0.id == tempMessage.id }) {
                messages.remove(at: index)
            }
        }

        // UI 업데이트
        updateChatItems()

        Logger.chat.info("✅ [ChatDetailViewModel] Temporary messages cleaned up")
    }

    /// 실시간으로 수신한 메시지 처리 (중복 체크 포함)
    private func handleReceivedMessage(_ messageDTO: ChatMessageItemDTO) async {
        Logger.chat.info("📬 [ChatDetailViewModel] Handling received message: \(messageDTO.chatId ?? "unknown")")

        // 중복 체크
        let chatId = messageDTO.chatId ?? ""
        if messages.contains(where: { $0.id == chatId }) {
            Logger.chat.info("⚠️ [ChatDetailViewModel] Message already exists, skipping: \(chatId)")
            return
        }

        // 내 메시지는 제외 (이미 Optimistic UI로 추가됨)
        if messageDTO.sender?.userId == myUserId {
            Logger.chat.info("⚠️ [ChatDetailViewModel] My own message, skipping: \(chatId)")
            return
        }

        // Realm에 저장
        try? await repository.saveMessageFromDTO(messageDTO, myUserId: myUserId)

        // UI 업데이트
        let uiModel = ChatMessageUIModel(
            id: chatId,
            content: messageDTO.content,
            createdAt: messageDTO.createdAt ?? ISO8601DateFormatter().string(from: Date()),
            senderNickname: messageDTO.sender?.nick ?? "알 수 없음",
            senderProfileImage: messageDTO.sender?.profileImage,
            files: messageDTO.files ?? [],
            isSentByMe: false,
            isTemporary: false,
            sendFailed: false
        )
        messages.insert(uiModel, at: 0)
        updateChatItems()

        Logger.chat.info("✅ [ChatDetailViewModel] Added new message to UI: \(chatId)")
    }

    /// 큐에 쌓인 메시지들을 순차 처리
    private func processQueuedMessages() async {
        guard !self.messageQueue.isEmpty else { return }

        Logger.chat.info("📦 [ChatDetailViewModel] Processing \(self.messageQueue.count) queued messages")

        for messageDTO in self.messageQueue {
            await handleReceivedMessage(messageDTO)
        }

        // 큐 비우기
        self.messageQueue.removeAll()
        Logger.chat.info("✅ [ChatDetailViewModel] Queued messages processed")
    }

    private func connectWebSocket() {
        Logger.chat.info("🎧 [ChatDetailViewModel] Setting up AsyncStream listeners for room: \(self.roomId)")

        // 연결 상태 스트림 구독
        connectionTask = Task { [weak self] in
            guard let self = self else {
                Logger.chat.error("❌ [ChatDetailViewModel] connectionTask: self is nil")
                return
            }

            Logger.chat.info("🔌 [ChatDetailViewModel] connectionTask started, waiting for connection states...")

            for await isConnected in socketService.connectionStates {
                Logger.chat.info("🔌 [ChatDetailViewModel] Connection state changed: \(isConnected)")

                if isConnected {
                    Logger.chat.info("✅ [ChatDetailViewModel] WebSocket connected successfully")

                    // 연결 성공 시 API 동기화 (최초 1회만)
                    if !self.isRealmSynced {
                        await self.fetchAndSync()
                    }
                } else {
                    Logger.chat.warning("⚠️ [ChatDetailViewModel] WebSocket disconnected")
                }
            }

            Logger.chat.info("🔌 [ChatDetailViewModel] connectionTask loop ended")
        }

        // 메시지 수신 스트림 구독
        messageTask = Task { [weak self] in
            guard let self = self else {
                Logger.chat.error("❌ [ChatDetailViewModel] messageTask: self is nil")
                return
            }

            Logger.chat.info("📬 [ChatDetailViewModel] messageTask started, waiting for messages...")
            Logger.chat.info("📬 [ChatDetailViewModel] Current isRealmSynced: \(self.isRealmSynced)")

            for await messageDTO in socketService.messages {
                Logger.chat.info("📬 [ChatDetailViewModel] Received message in Task: \(messageDTO.chatId ?? "unknown")")

                // 동기화 전이면 큐에 저장, 동기화 후면 즉시 처리
                if !self.isRealmSynced {
                    Logger.chat.info("📥 [ChatDetailViewModel] Queueing message (not synced yet): \(messageDTO.chatId ?? "unknown")")
                    self.messageQueue.append(messageDTO)
                } else {
                    Logger.chat.info("📥 [ChatDetailViewModel] Processing message immediately: \(messageDTO.chatId ?? "unknown")")
                    await self.handleReceivedMessage(messageDTO)
                }
            }

            Logger.chat.info("📬 [ChatDetailViewModel] messageTask loop ended")
        }

        Logger.chat.info("✅ [ChatDetailViewModel] AsyncStream listeners setup complete")
        Logger.chat.info("✅ [ChatDetailViewModel] connectionTask status: \(self.connectionTask?.isCancelled ?? true ? "cancelled" : "running")")
        Logger.chat.info("✅ [ChatDetailViewModel] messageTask status: \(self.messageTask?.isCancelled ?? true ? "cancelled" : "running")")
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

    private func uploadVideo(_ videoURL: URL, retryCount: Int = 0) async throws -> VideoUploadResult {
        let videoUUID = UUID().uuidString

        // 임시 파일 정리를 보장 (성공/실패 무관)
        defer {
            videoUploadService.cleanupTemporaryFiles(videoUUID: videoUUID)
            videoUploadProgress.removeValue(forKey: videoUUID)
        }

        do {
            // Task cancellation 체크
            try Task.checkCancellation()

            // VideoUploadService를 사용한 전체 플로우
            let result = try await videoUploadService.uploadVideoWithThumbnail(
                videoURL: videoURL,
                roomId: roomId,
                quality: retryCount > 0 ? .low : .medium
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.videoUploadProgress[videoUUID] = progress
                }
            }

            return result

        } catch let error as VideoCompressionError {
            switch error {
            case .compressionFailed where retryCount == 0:
                // 압축 실패 시 낮은 품질로 1회 재시도
                Logger.chat.warning("⚠️ 압축 실패, 낮은 품질로 재시도")
                videoUploadProgress.removeValue(forKey: videoUUID)
                return try await uploadVideo(videoURL, retryCount: 1)

            case .fileSizeExceeded:
                // 파일 크기 초과 시 재시도 없이 즉시 에러 표시
                errorMessage = error.localizedDescription
                Logger.chat.error("❌ 파일 크기 초과: \(error.localizedDescription)")
                throw error

            default:
                errorMessage = error.localizedDescription
                throw error
            }
        } catch {
            // 기타 에러
            Logger.chat.error("❌ Video upload failed: \(error)")
            errorMessage = "비디오 업로드에 실패했습니다."
            throw error
        }
    }

    private func sendMessageWithFiles(
        content: String?,
        filePaths: [String],
        localThumbnailURLs: [URL] = []
    ) async {
        // Optimistic UI: 임시 메시지 생성
        let tempChatId = UUID().uuidString
        let createdAt = ISO8601DateFormatter().string(from: Date())

        // Optimistic UI용 파일 배열 (로컬 썸네일 사용)
        let optimisticFiles = localThumbnailURLs.isEmpty
            ? filePaths
            : localThumbnailURLs.map { $0.absoluteString } + filePaths.filter { !$0.contains("-thumb.") }

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
            files: optimisticFiles,
            isSentByMe: true,
            isTemporary: true
        )

        // UI 업데이트용 모델 (로컬 썸네일 즉시 표시)
        let tempUIModel = ChatMessageUIModel(
            id: tempChatId,
            content: content,
            createdAt: createdAt,
            senderNickname: myNickname.isEmpty ? "나" : myNickname,
            senderProfileImage: myProfileImage,
            files: optimisticFiles,
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
