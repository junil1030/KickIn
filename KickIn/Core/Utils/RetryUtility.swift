//
//  RetryUtility.swift
//  KickIn
//
//  Created by 서준일 on 01/15/26.
//

import Foundation
import OSLog

// MARK: - RetryConfiguration

struct RetryConfiguration {
    let maxAttempts: Int
    let initialDelay: Double
    let multiplier: Double
    let maxDelay: Double

    static let `default` = RetryConfiguration(
        maxAttempts: 3,
        initialDelay: 1.0,
        multiplier: 2.0,
        maxDelay: 8.0
    )

    func delayForAttempt(_ attempt: Int) -> Double {
        let delay = initialDelay * pow(multiplier, Double(attempt - 1))
        return min(delay, maxDelay)
    }
}

// MARK: - RetryError

enum RetryError: Error {
    case maxRetriesExceeded(lastError: Error?)
}

// MARK: - withExponentialBackoff

func withExponentialBackoff<T>(
    config: RetryConfiguration = .default,
    operation: @escaping () async throws -> T
) async throws -> T {
    var lastError: Error?

    for attempt in 1...config.maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error
            Logger.network.warning("⚠️ [Retry] Attempt \(attempt)/\(config.maxAttempts) failed: \(error.localizedDescription)")

            if attempt < config.maxAttempts {
                let delay = config.delayForAttempt(attempt)
                Logger.network.info("⏳ [Retry] Waiting \(delay)s before next attempt...")

                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    Logger.network.error("❌ [Retry] All \(config.maxAttempts) attempts failed")
    throw RetryError.maxRetriesExceeded(lastError: lastError)
}
