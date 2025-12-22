//
//  AuthenticationInterceptor.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation
import Alamofire

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
            // Check if error is 401 Unauthorized
            guard let response = request.task?.response as? HTTPURLResponse,
                  response.statusCode == 401 else {
                completion(.doNotRetry)
                return
            }

            // Get refresh token
            guard let refreshToken = await tokenStorage.getRefreshToken() else {
                // No refresh token available, logout
                await handleLogout()
                completion(.doNotRetry)
                return
            }

            do {
                // Attempt to refresh token (synchronized via actor)
                let newAccessToken = try await refreshManager.refreshToken(
                    using: refreshToken,
                    refreshHandler: { [weak self] refreshToken in
                        guard let self = self else {
                            throw NetworkError.unknown
                        }
                        return try await self.performTokenRefresh(refreshToken: refreshToken)
                    }
                )

                // Save new access token
                await tokenStorage.setAccessToken(newAccessToken)

                // Retry the original request
                completion(.retry)
            } catch {
                // Refresh failed, logout
                await handleLogout()
                completion(.doNotRetry)
            }
        }
    }

    // MARK: - Private Methods

    private func performTokenRefresh(refreshToken: String) async throws -> String {
        // Create refresh token request
        let router = UserRouter.refreshToken(token: refreshToken)

        guard let urlRequest = try? await router.asURLRequest() else {
            throw NetworkError.invalidURL
        }

        // Perform network request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }

        guard httpResponse.statusCode == 200 else {
            throw NetworkError.unauthorized
        }

        // Decode response
        let decoder = JSONDecoder()
        let refreshResponse = try decoder.decode(RefreshTokenResponseDTO.self, from: data)

        guard let newAccessToken = refreshResponse.accessToken else {
            throw NetworkError.decodingError
        }

        return newAccessToken
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
