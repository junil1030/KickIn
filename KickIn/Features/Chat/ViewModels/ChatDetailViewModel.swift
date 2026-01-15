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

    /// @ObservedResults 기반 메시지 Observer (자동 UI 업데이트)
    @Published private(set) var messagesObserver: ChatMessagesObserver?

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

    // Sync Coordinator
    @Published private(set) var syncState: SyncState = .idle
    private var syncCoordinator: MessageSyncCoordinator?

    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    private let tokenStorage = NetworkServiceFactory.shared.getTokenStorage()
    private let repository: ChatMessageRepositoryProtocol
    private let socketService: SocketServiceProtocol
    private let videoUploadService: VideoUploadService

    private var connectionTask: Task<Void, Never>?
    private var messageTask: Task<Void, Never>?
    private var observerCancellable: AnyCancellable?

    // MARK: - Computed Properties

    /// View에서 사용할 chatItems (@ObservedResults 기반)
    var displayedChatItems: [ChatItem] {
        messagesObserver?.chatItems ?? []
    }

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
        observerCancellable?.cancel()
    }

    // MARK: - Public Methods

    func loadInitialMessages() async {
        isLoading = true
        errorMessage = nil

        // 내 정보 조회
        myUserId = await tokenStorage.getUserId() ?? ""

        // @ObservedResults 기반 Observer 초기화 (자동으로 로컬 메시지 로드)
        messagesObserver = ChatMessagesObserver(roomId: roomId)
        setupObserverSubscription()
        Logger.chat.info("📡 [ChatDetailViewModel] ChatMessagesObserver initialized for room: \(self.roomId)")

        do {
            // Coordinator 초기화
            syncCoordinator = MessageSyncCoordinator(
                repository: repository,
                networkService: networkService,
                roomId: roomId,
                myUserId: myUserId,
                opponentUserId: opponentUserId
            )
            setupCoordinatorCallbacks()

            // 3. 기존 Task 취소
            connectionTask?.cancel()
            messageTask?.cancel()

            // 4. AsyncStream 구독 시작
            setupStreamListeners()

            Logger.chat.info("✅ Stream subscription started")

            // 5. Socket 연결
            await socketService.connect(roomID: roomId)

            Logger.chat.info("✅ Socket connected, starting sync via Coordinator")

            // 동기화 시작 (Exponential Backoff 포함)
            // @ObservedResults가 Realm 변경을 자동 감지하여 UI 업데이트
            try await syncCoordinator?.startSync()

            Logger.chat.info("✅ Initial load complete for room \(self.roomId)")

        } catch let error as NetworkError {
            Logger.chat.error("❌ Failed to load messages: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch let error as SyncError {
            Logger.chat.error("❌ Sync error: \(error.localizedDescription)")
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

        // Observer의 chatItems에서 가장 오래된 메시지의 cursor 추출
        let cursor = displayedChatItems
            .compactMap { item -> String? in
                guard case .message(let config) = item else { return nil }
                return config.message.createdAt
            }
            .last  // displayedChatItems는 최신순이므로 last가 가장 오래된 메시지

        do {
            let response: ChatMessagesResponseDTO = try await networkService.request(
                ChatRouter.getChatMessages(roomId: roomId, next: cursor)
            )

            guard let newMessages = response.data, !newMessages.isEmpty else {
                hasMoreData = false
                isLoadingMore = false
                return
            }

            // Realm에 저장 → @ObservedResults가 자동으로 UI 업데이트
            for messageDTO in newMessages {
                try await repository.saveMessageFromDTO(messageDTO, myUserId: myUserId)
            }

            hasMoreData = newMessages.count >= 50

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

    /// Called from ChatLifecycleManager for reconnection after network recovery or foreground return
    func performReconnectionWithGapFill() async {
        Logger.chat.info("🔄 [ChatDetailViewModel] Starting reconnection with gap fill for room: \(self.roomId)")

        // 1. Reset Coordinator
        await syncCoordinator?.reset()

        // 2. Cancel existing tasks
        connectionTask?.cancel()
        messageTask?.cancel()

        // 3. Prepare new streams
        socketService.prepareNewConnection()

        // 4. Setup stream listeners BEFORE connecting
        setupStreamListeners()

        // 5. Connect socket
        await socketService.connect(roomID: roomId)

        // Start sync via Coordinator
        // @ObservedResults가 Realm 변경을 자동 감지하여 UI 업데이트
        do {
            try await syncCoordinator?.startSync()
        } catch {
            Logger.chat.error("❌ [ChatDetailViewModel] Reconnection sync failed: \(error)")
        }

        Logger.chat.info("✅ [ChatDetailViewModel] Reconnection with gap fill complete")
    }

    // MARK: - Private Methods

    /// 실시간으로 수신한 메시지 처리 (Realm 저장만, UI는 @ObservedResults가 처리)
    private func handleReceivedMessage(_ messageDTO: ChatMessageItemDTO) async {
        let chatId = messageDTO.chatId ?? ""
        Logger.chat.info("📬 [ChatDetailViewModel] Handling received message: \(chatId)")

        // 중복 체크 (displayedChatItems에서 확인)
        let messageExists = displayedChatItems.contains { item in
            guard case .message(let config) = item else { return false }
            return config.message.id == chatId
        }

        if messageExists {
            Logger.chat.info("⚠️ [ChatDetailViewModel] Message already exists, skipping: \(chatId)")
            return
        }

        // 내 메시지는 제외 (이미 Optimistic UI로 추가됨)
        if messageDTO.sender?.userId == myUserId {
            Logger.chat.info("⚠️ [ChatDetailViewModel] My own message, skipping: \(chatId)")
            return
        }

        // Realm에 저장 → @ObservedResults가 자동으로 UI 업데이트
        try? await repository.saveMessageFromDTO(messageDTO, myUserId: myUserId)

        Logger.chat.info("✅ [ChatDetailViewModel] Saved message to Realm: \(chatId)")
    }

    /// Setup Coordinator callbacks (onMessagesUpdated 제거됨 - @ObservedResults가 UI 업데이트 처리)
    private func setupCoordinatorCallbacks() {
        Task { [weak self] in
            guard let self = self else { return }

            await self.syncCoordinator?.setOnStateChange { [weak self] newState in
                Task { @MainActor in
                    self?.syncState = newState
                }
            }
        }
    }

    /// Observer의 chatItems 변경을 구독하여 미디어 추출
    private func setupObserverSubscription() {
        observerCancellable = messagesObserver?.$chatItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                self.extractMediaFromObservedItems(items)
                Logger.chat.info("📡 [ChatDetailViewModel] Observer chatItems updated: \(items.count) items")
            }
    }

    /// Observer의 chatItems에서 미디어 아이템 추출
    private func extractMediaFromObservedItems(_ items: [ChatItem]) {
        let mediaItems = items.compactMap { item -> [MediaItem]? in
            guard case .message(let config) = item else { return nil }
            return config.message.mediaItems(roomId: roomId)
        }.flatMap { $0 }

        allMediaItems = mediaItems.sorted { $0.createdAt > $1.createdAt }
    }

    /// Setup AsyncStream listeners for socket events (extracted for reuse in reconnection)
    private func setupStreamListeners() {
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

            for await messageDTO in socketService.messages {
                Logger.chat.info("📬 [ChatDetailViewModel] Received message in Task: \(messageDTO.chatId ?? "unknown")")

                // Coordinator가 처리 여부 결정
                let shouldProcess = await self.syncCoordinator?.processStreamMessage(messageDTO) ?? false

                if shouldProcess {
                    await self.handleReceivedMessage(messageDTO)
                }
                // shouldProcess가 false면 Coordinator 내부에서 buffer에 저장됨
            }

            Logger.chat.info("📬 [ChatDetailViewModel] messageTask loop ended")
        }

        Logger.chat.info("✅ [ChatDetailViewModel] AsyncStream listeners setup complete")
        Logger.chat.info("✅ [ChatDetailViewModel] connectionTask status: \(self.connectionTask?.isCancelled ?? true ? "cancelled" : "running")")
        Logger.chat.info("✅ [ChatDetailViewModel] messageTask status: \(self.messageTask?.isCancelled ?? true ? "cancelled" : "running")")
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

        // Realm에 임시 메시지 저장 → @ObservedResults가 자동으로 UI 표시
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

        do {
            // HTTP API로 메시지 전송
            let requestDTO = SendMessageRequestDTO(content: content, files: filePaths)
            let response: ChatMessageResponseDTO = try await networkService.request(
                ChatRouter.sendMessage(roomId: roomId, requestDTO)
            )

            // 서버 응답의 실제 chatId로 교체 → @ObservedResults가 자동으로 UI 업데이트
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

                Logger.chat.info("✅ Message sent successfully: \(serverChatId)")
            }

        } catch {
            Logger.chat.error("❌ Failed to send message: \(error)")
            // 실패 상태로 업데이트 → @ObservedResults가 자동으로 UI 반영
            try? await repository.updateMessageStatus(
                chatId: tempChatId,
                isTemporary: true,
                failReason: error.localizedDescription
            )
        }
    }
}
