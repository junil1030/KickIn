//
//  AuthenticationInterceptor.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation
import Alamofire
import OSLog

final class AuthenticationInterceptor: RequestInterceptor {
    private let tokenStorage: any TokenStorageProtocol
    private let refreshManager = TokenRefreshManager()

    init(tokenStorage: any TokenStorageProtocol) {
        self.tokenStorage = tokenStorage
    }

    // MARK: - RequestAdapter

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        Task {
            var urlRequest = urlRequest

            // Get access token from storage
            if let accessToken = await tokenStorage.getAccessToken() {
                urlRequest.headers.add(.authorization(accessToken))
            }

            completion(.success(urlRequest))
        }
    }

    // MARK: - RequestRetrier

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        Task {
            await Logger.network.debug("Retry flow started")
            guard let response = request.task?.response as? HTTPURLResponse else {
                await Logger.network.debug("Retry check: missing HTTPURLResponse")
                completion(.doNotRetry)
                return
            }

            await Logger.network.debug("Retry check status: \(response.statusCode)")

            // Check if error is 401 Unauthorized or 419 Token Expired
            guard response.statusCode == 401 || response.statusCode == 419 else {
                completion(.doNotRetry)
                return
            }

            await Logger.network.info("Token expired detected")
            await Logger.network.debug("Token refresh triggered")

            // Get refresh token
            guard let refreshToken = await tokenStorage.getRefreshToken() else {
                // No refresh token available, logout
                await Logger.network.error("Token refresh failed: missing refresh token")
                await handleLogout()
                completion(.doNotRetry)
                return
            }

            do {
                // Attempt to refresh token (synchronized via actor)
                await Logger.network.debug("Token refresh request started")
                let refreshResponse = try await refreshManager.refreshToken(
                    using: refreshToken,
                    refreshHandler: { [weak self] refreshToken in
                        guard let self = self else {
                            throw NetworkError.unknown
                        }
                        return try await self.performTokenRefresh(refreshToken: refreshToken)
                    }
                )

                guard let newAccessToken = refreshResponse.accessToken else {
                    await Logger.network.error("Token refresh failed: missing access token")
                    await handleLogout()
                    completion(.doNotRetry)
                    return
                }

                // Save new access and refresh tokens
                await tokenStorage.setAccessToken(newAccessToken)
                if let newRefreshToken = refreshResponse.refreshToken {
                    await tokenStorage.setRefreshToken(newRefreshToken)
                }

                await Logger.network.info("Token refresh succeeded: accessToken=\(newAccessToken)")
                await Logger.network.info("Token refresh succeeded: refreshToken=\(refreshResponse.refreshToken ?? "nil")")

                // Retry the original request
                completion(.retry)
            } catch {
                // Refresh failed, logout
                await Logger.network.error("Token refresh failed: \(error.localizedDescription)")
                await handleLogout()
                completion(.doNotRetry)
            }
        }
    }

    // MARK: - Private Methods

    private func performTokenRefresh(refreshToken: String) async throws -> RefreshTokenResponseDTO {
        // Create refresh token request
        let router = UserRouter.refreshToken(token: refreshToken)

        guard var urlRequest = try? await router.asURLRequest() else {
            throw NetworkError.invalidURL
        }

        if let accessToken = await tokenStorage.getAccessToken() {
            urlRequest.setValue(accessToken, forHTTPHeaderField: "Authorization")
        }

        await Logger.network.debug("Token refresh request URL: \(urlRequest.url?.absoluteString ?? "nil")")
        await Logger.network.debug("Token refresh request headers: \(urlRequest.headers.dictionary)")

        // Perform network request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        if let bodyString = String(data: data, encoding: .utf8) {
            await Logger.network.debug("Token refresh response data: \(bodyString)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }

        guard httpResponse.statusCode == 200 else {
            await Logger.network.error("Token refresh response status: \(httpResponse.statusCode)")
            throw NetworkError.unauthorized
        }

        // Decode response
        let decoder = JSONDecoder()
        let refreshResponse = try decoder.decode(RefreshTokenResponseDTO.self, from: data)

        await Logger.network.info("Token refresh response decoded")
        return refreshResponse
    }

    private func handleLogout() async {
        await tokenStorage.clearTokens()

        // Post logout notification
        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("UserDidLogout"),
                object: nil
            )
        }
    }
}
