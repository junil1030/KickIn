//
//  NetworkMonitor.swift
//  KickIn
//
//  Created by 서준일 on 01/15/26.
//

import Foundation
import Network
import Combine
import OSLog

/// Network connectivity states
enum NetworkStatus: Equatable {
    case connected(interface: NWInterface.InterfaceType)
    case disconnected
    case unknown

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

/// Monitors network connectivity using NWPathMonitor
final class NetworkMonitor: ObservableObject {

    // MARK: - Singleton

    static let shared = NetworkMonitor()

    // MARK: - Published Properties

    @Published private(set) var status: NetworkStatus = .unknown
    @Published private(set) var isConnected: Bool = false

    // MARK: - Combine Publishers

    /// Emits when network transitions from disconnected to connected
    var networkRecoveryPublisher: AnyPublisher<Void, Never> {
        $status
            .removeDuplicates()
            .scan((previous: NetworkStatus.unknown, current: NetworkStatus.unknown)) { state, newStatus in
                (previous: state.current, current: newStatus)
            }
            .filter { state in
                !state.previous.isConnected && state.current.isConnected
            }
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.junil.KickIn.NetworkMonitor", qos: .utility)

    // MARK: - Initialization

    private init() {
        self.monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handlePathUpdate(path)
            }
        }
        monitor.start(queue: queue)
        Logger.network.info("📡 [NetworkMonitor] Started monitoring")
    }

    func stopMonitoring() {
        monitor.cancel()
        Logger.network.info("📡 [NetworkMonitor] Stopped monitoring")
    }

    // MARK: - Private Methods

    private func handlePathUpdate(_ path: NWPath) {
        let previousStatus = status

        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                status = .connected(interface: .wifi)
            } else if path.usesInterfaceType(.cellular) {
                status = .connected(interface: .cellular)
            } else if path.usesInterfaceType(.wiredEthernet) {
                status = .connected(interface: .wiredEthernet)
            } else {
                status = .connected(interface: .other)
            }
            isConnected = true
        } else {
            status = .disconnected
            isConnected = false
        }

        if previousStatus != status {
            Logger.network.info("📡 [NetworkMonitor] Status changed: \(String(describing: previousStatus)) → \(String(describing: self.status))")
        }
    }
}
