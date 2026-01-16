//
//  ChatLifecycleManager.swift
//  KickIn
//
//  Created by 서준일 on 01/15/26.
//

import Foundation
import Combine
import SwiftUI
import OSLog

/// Manages chat socket lifecycle across app states and network changes
@MainActor
final class ChatLifecycleManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ChatLifecycleManager()

    // MARK: - Published Properties

    @Published private(set) var activeChatRoom: ActiveChatRoom?

    // MARK: - Reconnection Event Publisher

    /// Emits roomId when reconnection with gap fill is needed
    let reconnectionNeededPublisher = PassthroughSubject<String, Never>()

    // MARK: - Private Properties

    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private var wasConnectedBeforeBackground: Bool = false
    private var backgroundDisconnectTime: Date?

    // MARK: - Configuration

    /// Delay before disconnecting socket when app enters background (handles quick app switches)
    private let backgroundDisconnectDelay: TimeInterval = 3.0
    private var backgroundTask: Task<Void, Never>?

    // MARK: - Initialization

    private init() {
        setupNetworkRecoveryObserver()
    }

    // MARK: - Public Methods

    /// Register the active chat room when entering
    func registerActiveChatRoom(roomId: String, opponentUserId: String, viewModel: ChatDetailViewModel) {
        activeChatRoom = ActiveChatRoom(
            roomId: roomId,
            opponentUserId: opponentUserId,
            viewModel: viewModel
        )
        Logger.chat.info("📋 [ChatLifecycleManager] Registered active chat room: \(roomId)")
    }

    /// Unregister when leaving chat room
    func unregisterActiveChatRoom() {
        if let roomId = activeChatRoom?.roomId {
            Logger.chat.info("📋 [ChatLifecycleManager] Unregistered chat room: \(roomId)")
        }
        activeChatRoom = nil
        backgroundTask?.cancel()
        backgroundTask = nil
    }

    /// Handle app entering background
    func handleEnterBackground() {
        guard let activeRoom = activeChatRoom else { return }

        wasConnectedBeforeBackground = SocketService.shared.isConnected

        // Delay disconnect to handle quick app switches
        backgroundTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(backgroundDisconnectDelay * 1_000_000_000))

            guard !Task.isCancelled else { return }

            if SocketService.shared.isConnected {
                backgroundDisconnectTime = Date()
                SocketService.shared.disconnect()
                Logger.chat.info("🌙 [ChatLifecycleManager] Disconnected socket for background (room: \(activeRoom.roomId))")
            }
        }
    }

    /// Handle app returning to foreground
    func handleEnterForeground() {
        backgroundTask?.cancel()
        backgroundTask = nil

        guard let activeRoom = activeChatRoom else { return }

        // Only reconnect if we were connected before background
        if wasConnectedBeforeBackground {
            Logger.chat.info("☀️ [ChatLifecycleManager] Returning to foreground, triggering reconnection for room: \(activeRoom.roomId)")
            reconnectionNeededPublisher.send(activeRoom.roomId)
        }

        wasConnectedBeforeBackground = false
        backgroundDisconnectTime = nil
    }

    // MARK: - Private Methods

    private func setupNetworkRecoveryObserver() {
        networkMonitor.networkRecoveryPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleNetworkRecovery()
                }
            }
            .store(in: &cancellables)
    }

    private func handleNetworkRecovery() {
        guard let activeRoom = activeChatRoom else {
            Logger.chat.info("📡 [ChatLifecycleManager] Network recovered but no active chat room")
            return
        }

        Logger.chat.info("📡 [ChatLifecycleManager] Network recovered, triggering reconnection for room: \(activeRoom.roomId)")
        reconnectionNeededPublisher.send(activeRoom.roomId)
    }
}

// MARK: - Supporting Types

struct ActiveChatRoom {
    let roomId: String
    let opponentUserId: String
    weak var viewModel: ChatDetailViewModel?
}
