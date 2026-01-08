//
//  TokenRefreshManager.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

actor TokenRefreshManager {
    private var isRefreshing = false
    private var refreshTask: Task<RefreshTokenResponseDTO, Error>?

    func refreshToken(
        using refreshToken: String,
        refreshHandler: @escaping (String) async throws -> RefreshTokenResponseDTO
    ) async throws -> RefreshTokenResponseDTO {
        // If already refreshing, wait for the existing task
        if let existingTask = refreshTask {
            return try await existingTask.value
        }

        // Create new refresh task
        let task = Task<RefreshTokenResponseDTO, Error> {
            isRefreshing = true
            defer {
                isRefreshing = false
                refreshTask = nil
            }

            return try await refreshHandler(refreshToken)
        }

        refreshTask = task
        return try await task.value
    }
}
