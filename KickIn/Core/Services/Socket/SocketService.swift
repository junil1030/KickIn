//
//  SocketService.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation
import SocketIO
import OSLog

final class SocketService: SocketServiceProtocol {

    // MARK: - Singleton

    static let shared = SocketService()

    // MARK: - Properties

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private let tokenStorage = NetworkServiceFactory.shared.getTokenStorage()

    private var messageContinuation: AsyncStream<ChatMessageItemDTO>.Continuation?
    private var connectionContinuation: AsyncStream<Bool>.Continuation?

    lazy var messages: AsyncStream<ChatMessageItemDTO> = {
        Logger.chat.info("🔧 [SocketService] Creating messages AsyncStream (lazy init)")
        return AsyncStream { [weak self] continuation in
            Logger.chat.info("🔧 [SocketService] messages AsyncStream continuation initialized")
            self?.messageContinuation = continuation
        }
    }()

    lazy var connectionStates: AsyncStream<Bool> = {
        Logger.chat.info("🔧 [SocketService] Creating connectionStates AsyncStream (lazy init)")
        return AsyncStream { [weak self] continuation in
            Logger.chat.info("🔧 [SocketService] connectionStates AsyncStream continuation initialized")
            self?.connectionContinuation = continuation
        }
    }()

    var isConnected: Bool {
        socket?.status == .connected
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    func prepareNewConnection() {
        Logger.chat.info("🔄 [SocketService] prepareNewConnection called")

        // 기존 스트림 종료
        Logger.chat.info("🔄 [SocketService] Finishing existing continuations")
        messageContinuation?.finish()
        connectionContinuation?.finish()

        // 새 스트림 생성
        Logger.chat.info("🔄 [SocketService] Creating new AsyncStreams")
        messages = AsyncStream { [weak self] continuation in
            Logger.chat.info("🔄 [SocketService] New messages continuation initialized")
            self?.messageContinuation = continuation
        }
        connectionStates = AsyncStream { [weak self] continuation in
            Logger.chat.info("🔄 [SocketService] New connectionStates continuation initialized")
            self?.connectionContinuation = continuation
        }

        Logger.chat.info("🔄 [SocketService] New AsyncStreams prepared")
    }

    func connect(roomID: String) async {
        if let socket, isConnected, socket.nsp == "/chats-\(roomID)" {
            Logger.chat.info("Already connected to room \(roomID)")
            return
        }

        disconnect()

        // 1. configue
        await configure(roomID: roomID)

        // 2. connect
        await connectInternal()
    }

    func disconnect() {
        socket?.disconnect()
        messageContinuation?.finish()
        connectionContinuation?.finish()
        Logger.chat.info("🔌 Socket disconnected")
    }

    // MARK: - Private Methods
    
    private func configure(roomID: String) async {
        guard let accessToken = await tokenStorage.getAccessToken() else {
            await tokenStorage.clearTokens()
            return
        }
        
        guard let url = URL(string: APIConfig.socketURL) else { return }
        
        let config: SocketIOClientConfiguration = [
            .log(false),
            .compress,
            .extraHeaders([
                "Authorization": accessToken,
                "SeSACKey": APIConfig.apikey
            ]),
            .reconnects(true),
            .reconnectAttempts(3),
            .reconnectWait(1),
            .reconnectWaitMax(16)
        ]
        
        manager = SocketManager(socketURL: url, config: config)
        socket = manager?.socket(forNamespace: "/chats-\(roomID)")
        
        setupEventHandlers()
    }
    
    private func connectInternal() async {
        guard let socket else { return }
        // ⚠️ 버그 수정: guard !isConnected → 이미 연결되어 있으면 return (위에서 체크함)

        await withCheckedContinuation { continuation in
            socket.once(clientEvent: .connect) { _, _ in
                Logger.chat.info("✅ Socket connected")
                continuation.resume()
            }

            socket.connect()
        }
    }

    private func setupEventHandlers() {
        // 연결 성공
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            Logger.chat.info("🔗 Socket connected")
            self?.connectionContinuation?.yield(true)
        }

        // 연결 끊김
        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            Logger.chat.warning("⚠️ Socket disconnected")
            self?.connectionContinuation?.yield(false)
        }

        // 재연결
        socket?.on(clientEvent: .reconnect) { [weak self] _, _ in
            Logger.chat.info("🔄 Socket reconnected")
            self?.connectionContinuation?.yield(true)
        }

        // 메시지 수신
        socket?.on(SocketEvent.chat.rawValue) { [weak self] data, _ in
            Logger.chat.info("📩 [SocketService] Received raw data: \(data)")

            guard let self = self else {
                Logger.chat.error("❌ [SocketService] self is nil")
                return
            }

            guard let dict = data.first as? [String: Any] else {
                Logger.chat.error("❌ [SocketService] Failed to cast to dict: \(data)")
                return
            }

            guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else {
                Logger.chat.error("❌ [SocketService] Failed to serialize JSON")
                return
            }

            guard let message = try? JSONDecoder().decode(ChatMessageItemDTO.self, from: jsonData) else {
                Logger.chat.error("❌ [SocketService] Failed to decode ChatMessageItemDTO")
                return
            }

            Logger.chat.info("✅ [SocketService] Decoded message, yielding to AsyncStream: \(message.chatId ?? "unknown")")

            if self.messageContinuation == nil {
                Logger.chat.error("❌ [SocketService] messageContinuation is nil! Cannot yield message.")
            } else {
                Logger.chat.info("✅ [SocketService] messageContinuation exists, yielding...")
                self.messageContinuation?.yield(message)
                Logger.chat.info("✅ [SocketService] Message yielded to AsyncStream")
            }
        }

        // 에러
        socket?.on(clientEvent: .error) { data, _ in
            Logger.chat.error("❌ Socket error: \(data)")
        }
    }
}

// MARK: - Error

enum SocketError: LocalizedError {
    case notConnected

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "소켓이 연결되지 않았습니다."
        }
    }
}
