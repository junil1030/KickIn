//
//  SyncState.swift
//  KickIn
//
//  Created by 서준일 on 01/15/26.
//

import Foundation

// MARK: - SyncState

enum SyncState: Equatable {
    case idle
    case syncing(progress: SyncProgress)
    case streaming
    case error(SyncError)

    var canReceiveMessages: Bool {
        if case .streaming = self { return true }
        return false
    }

    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    var isSyncing: Bool {
        if case .syncing = self { return true }
        return false
    }
}

// MARK: - SyncProgress

struct SyncProgress: Equatable {
    let phase: SyncPhase
    let fetchedCount: Int
    let totalEstimate: Int?

    static func initial() -> SyncProgress {
        SyncProgress(phase: .checkingGap, fetchedCount: 0, totalEstimate: nil)
    }
}

// MARK: - SyncPhase

enum SyncPhase: Equatable {
    case checkingGap
    case fetchingMessages(page: Int)
    case savingToRealm
    case processingQueue
}

// MARK: - SyncError

enum SyncError: Error, Equatable {
    case networkError(String)
    case realmError(String)
    case maxRetriesExceeded

    var localizedDescription: String {
        switch self {
        case .networkError(let message):
            return "네트워크 오류: \(message)"
        case .realmError(let message):
            return "데이터베이스 오류: \(message)"
        case .maxRetriesExceeded:
            return "최대 재시도 횟수를 초과했습니다."
        }
    }
}
