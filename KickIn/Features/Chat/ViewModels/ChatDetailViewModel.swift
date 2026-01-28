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
    @Published private(set) var linkMetadataByMessage: [String: [LinkMetadata]] = [:]  // 메시지별 링크 메타데이터

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
    private let linkPreviewService: LinkPreviewServiceProtocol

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
        networkService: NetworkServiceProtocol = NetworkServiceFactory.shared.makeNetworkService(),
        linkPreviewService: LinkPreviewServiceProtocol = LinkPreviewService()
    ) {
        self.roomId = roomId
        self.opponentUserId = opponentUserId
        self.repository = repository
        self.socketService = socketService
        self.videoUploadService = VideoUploadService(networkService: networkService)
        self.linkPreviewService = linkPreviewService
    }

    deinit {
        // deinit은 nonisolated이므로 Task 취소만 수행
        connectionTask?.cancel()
        messageTask?.cancel()
        observerCancellable?.cancel()
    }

    // MARK: - Cleanup

    /// 리소스 정리 (View의 onDisappear에서 호출)
    func cleanup() {
        connectionTask?.cancel()
        messageTask?.cancel()
        observerCancellable?.cancel()
        messagesObserver?.invalidateObservation()
        socketService.disconnect()
        connectionTask = nil
        messageTask = nil
        observerCancellable = nil
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
                try await repository.saveMessageFromDTO(messageDTO, roomId: roomId, myUserId: myUserId)
            }

            hasMoreData = newMessages.count >= 50

            Logger.chat.info("📥 Loaded \(newMessages.count) more messages")

        } catch {
            Logger.chat.error("❌ Failed to load more messages: \(error)")
        }

        isLoadingMore = false
    }

    func sendMessage(content: String?, images: [UIImage], videos: [URL], pdfs: [URL]) async {
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

        // 3. PDF 업로드
        for pdfURL in pdfs {
            do {
                let serverURL = try await uploadPDF(pdfURL)
                filePaths.append(serverURL)
            } catch {
                Logger.chat.error("❌ Failed to upload PDF: \(error)")
                errorMessage = "PDF 업로드에 실패했습니다."
                return
            }
        }

        // 4. 메시지 전송 (Optimistic UI와 함께)
        await sendMessageWithFiles(
            content: content,
            filePaths: filePaths,
            localThumbnailURLs: localThumbnailURLs
        )
    }

    func disconnect() {
        socketService.disconnect()
    }

    /// 전송 실패한 메시지 재전송
    func retryFailedMessage(chatId: String) async {
        do {
            // Realm에서 실패한 메시지 조회
            let messages = try await repository.fetchMessages(roomId: roomId, limit: 1000, beforeDate: nil)
            guard let failedMessage = messages.first(where: { $0.chatId == chatId }) else {
                Logger.chat.error("❌ Failed message not found: \(chatId)")
                return
            }

            // 임시 상태로 변경 (UI에 전송 중 표시)
            try await repository.updateMessageStatus(
                chatId: chatId,
                isTemporary: true,
                failReason: nil
            )

            // 메시지 재전송
            let content = failedMessage.content
            let filePaths = Array(failedMessage.files)

            Logger.chat.info("🔄 Retrying message: \(chatId)")

            // 기존 메시지 삭제
            try await repository.deleteMessage(chatId: chatId)

            // 새로운 임시 ID로 재전송
            let tempChatId = UUID().uuidString
            let createdAt = ISO8601DateFormatter().string(from: Date())

            // Realm에 임시 메시지 저장
            try await repository.createAndSaveTemporaryMessage(
                chatId: tempChatId,
                roomId: roomId,
                content: content,
                createdAt: createdAt,
                senderUserId: myUserId,
                senderNickname: myNickname.isEmpty ? "나" : myNickname,
                senderProfileImage: myProfileImage,
                files: filePaths
            )

            // HTTP API로 메시지 전송
            let requestDTO = SendMessageRequestDTO(content: content, files: filePaths)
            let response: ChatMessageResponseDTO = try await networkService.request(
                ChatRouter.sendMessage(roomId: roomId, requestDTO)
            )

            // 서버 응답의 실제 chatId로 교체
            if let serverChatId = response.chatId {
                try await repository.deleteMessage(chatId: tempChatId)

                // 서버 응답을 DTO로 변환하여 저장
                try await repository.saveMessageFromDTO(
                    response.toMessageItemDTO(),
                    roomId: roomId,
                    myUserId: myUserId
                )

                Logger.chat.info("✅ Message retry successful: \(serverChatId)")
            }

        } catch {
            Logger.chat.error("❌ Failed to retry message: \(error)")
            // 실패 상태로 되돌림
            try? await repository.updateMessageStatus(
                chatId: chatId,
                isTemporary: false,
                failReason: error.localizedDescription
            )
        }
    }

    /// 전송 실패한 메시지 삭제
    func deleteFailedMessage(chatId: String) async {
        do {
            try await repository.deleteMessage(chatId: chatId)
            Logger.chat.info("🗑️ Deleted failed message: \(chatId)")
        } catch {
            Logger.chat.error("❌ Failed to delete message: \(error)")
        }
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

        // 내 메시지인 경우: 임시 메시지 찾아서 삭제 후 실제 메시지 저장
        if messageDTO.sender?.userId == myUserId {
            // Optimistic UI의 임시 메시지 찾기 (isTemporary=true인 내 메시지)
            let tempMessage = displayedChatItems.first { item in
                guard case .message(let config) = item else { return false }
                return config.message.isSentByMe && config.message.isTemporary
            }

            if let tempMessage = tempMessage,
               case .message(let config) = tempMessage {
                // 임시 메시지 삭제
                try? await repository.deleteMessage(chatId: config.message.id)
                Logger.chat.info("🗑️ [ChatDetailViewModel] Deleted temporary message: \(config.message.id)")
            }
        }

        // Realm에 저장 → @ObservedResults가 자동으로 UI 업데이트
        try? await repository.saveMessageFromDTO(messageDTO, roomId: roomId, myUserId: myUserId)

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

    /// Observer의 chatItems에서 미디어 아이템 추출 및 링크 프리뷰 fetch
    private func extractMediaFromObservedItems(_ items: [ChatItem]) {
        let mediaItems = items.compactMap { item -> [MediaItem]? in
            guard case .message(let config) = item else { return nil }
            return config.message.mediaItems(roomId: roomId)
        }.flatMap { $0 }

        allMediaItems = mediaItems.sorted { $0.createdAt > $1.createdAt }

        // 링크 프리뷰 fetch (새 메시지에 대해서만)
        for item in items {
            guard case .message(let config) = item else { continue }
            let message = config.message

            // 이미 프리뷰를 fetch한 메시지는 스킵
            guard linkMetadataByMessage[message.id] == nil else { continue }

            // URL이 있는 메시지만 처리
            let detectedLinks = message.detectedURLs
            guard !detectedLinks.isEmpty else { continue }

            // 백그라운드에서 프리뷰 fetch
            fetchLinkPreviews(for: message)
        }
    }

    // MARK: - Link Preview Methods

    /// 메시지의 링크 프리뷰 메타데이터 가져오기
    /// - Parameter message: 링크를 포함한 메시지
    func fetchLinkPreviews(for message: ChatMessageUIModel) {
        let detectedLinks = message.detectedURLs
        guard !detectedLinks.isEmpty else { return }

        Task(priority: .background) {
            var metadata: [LinkMetadata] = []

            // 최대 3개의 링크만 병렬 처리
            let linksToProcess = Array(detectedLinks.prefix(3))

            await withTaskGroup(of: LinkMetadata?.self) { group in
                for link in linksToProcess {
                    group.addTask {
                        do {
                            let meta = try await self.linkPreviewService.fetchMetadata(for: link.url)
                            Logger.chat.debug("📎 Metadata fetched - title: \(meta.title ?? "nil"), image: \(meta.imageURL ?? "nil"), isValid: \(meta.isValid)")
                            return meta.isValid ? meta : nil
                        } catch {
                            Logger.chat.debug("Link preview fetch failed for \(link.url): \(error)")
                            return nil
                        }
                    }
                }

                for await result in group {
                    if let result = result {
                        metadata.append(result)
                    }
                }
            }

            Logger.chat.debug("📎 Total metadata collected: \(metadata.count) for message: \(message.id)")

            if !metadata.isEmpty {
                await MainActor.run {
                    self.linkMetadataByMessage[message.id] = metadata
                }
            }
        }
    }

    /// 메시지 ID로 링크 메타데이터 조회
    /// - Parameter messageId: 메시지 ID
    /// - Returns: 링크 메타데이터 배열
    func getLinkMetadata(for messageId: String) -> [LinkMetadata] {
        linkMetadataByMessage[messageId] ?? []
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

    private func uploadPDF(_ pdfURL: URL) async throws -> String {
        // 임시 파일 정리를 보장 (성공/실패 무관)
        defer {
            // 임시 디렉토리의 PDF 파일 삭제
            if pdfURL.path.contains(FileManager.default.temporaryDirectory.path) {
                try? FileManager.default.removeItem(at: pdfURL)
                Logger.chat.info("🗑️ Deleted temporary PDF: \(pdfURL.lastPathComponent)")
            }
        }

        // 1. 파일 크기 체크 (5MB)
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: pdfURL.path)
        let fileSize = fileAttributes[.size] as? Int64 ?? 0

        guard fileSize <= 5_242_880 else {
            throw NetworkError.badRequest(message: "PDF 크기는 5MB를 초과할 수 없습니다.")
        }

        // 2. Data 변환
        let pdfData = try Data(contentsOf: pdfURL)
        let fileName = pdfURL.lastPathComponent.isEmpty
            ? "document_\(UUID().uuidString).pdf"
            : pdfURL.lastPathComponent

        // 3. 업로드
        let response: ChatFilesResponseDTO = try await networkService.upload(
            ChatRouter.uploadFiles(roomId: roomId),
            files: [(data: pdfData, name: "files", fileName: fileName, mimeType: "application/pdf")]
        )

        guard let serverURL = response.files?.first else {
            throw NetworkError.serverError(message: "No PDF path from server")
        }

        Logger.chat.info("✅ PDF uploaded successfully: \(fileName)")
        return serverURL
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
        try? await repository.createAndSaveTemporaryMessage(
            chatId: tempChatId,
            roomId: roomId,
            content: content,
            createdAt: createdAt,
            senderUserId: myUserId,
            senderNickname: myNickname.isEmpty ? "나" : myNickname,
            senderProfileImage: myProfileImage,
            files: optimisticFiles
        )

        do {
            // HTTP API로 메시지 전송
            let requestDTO = SendMessageRequestDTO(content: content, files: filePaths)
            let response: ChatMessageResponseDTO = try await networkService.request(
                ChatRouter.sendMessage(roomId: roomId, requestDTO)
            )

            // 서버 응답의 실제 chatId로 교체 → @ObservedResults가 자동으로 UI 업데이트
            if response.chatId != nil {
                try await repository.deleteMessage(chatId: tempChatId)

                // 서버 응답을 DTO로 변환하여 저장
                try await repository.saveMessageFromDTO(
                    response.toMessageItemDTO(),
                    roomId: roomId,
                    myUserId: myUserId
                )

                Logger.chat.info("✅ Message sent successfully: \(response.chatId ?? "")")
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
