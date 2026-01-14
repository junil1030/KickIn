//
//  KickInAuthenticator.swift
//  KickIn
//
//  Created by 서준일 on 1/14/26.
//

import Foundation
import Alamofire
import OSLog

final class KickInAuthenticator: Authenticator {
    typealias Credential = KickInAuthenticationCredential

    private let tokenStorage: any TokenStorageProtocol

    init(tokenStorage: any TokenStorageProtocol) {
        self.tokenStorage = tokenStorage
    }

    func apply(_ credential: Credential, to urlRequest: inout URLRequest) {
        guard !credential.accessToken.isEmpty else { return }
        urlRequest.headers.add(.authorization(credential.accessToken))
        urlRequest.addValue(credential.refreshToken, forHTTPHeaderField: "refreshToken")
    }

    func refresh(_ credential: Credential, for session: Alamofire.Session, completion: @escaping (Result<Credential, any Error>) -> Void) {
        Task {
            do {
                let router = UserRouter.refreshToken(token: credential.refreshToken)
                var urlRequest = try router.asURLRequest()
                urlRequest.setValue(credential.accessToken, forHTTPHeaderField: "Authorization")

                Logger.network.debug("Token refresh request started")

                let (data, response) = try await URLSession.shared.data(for: urlRequest)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.unknown
                }

                guard httpResponse.statusCode == 200 else {
                    Logger.network.error("Token refresh failed: status \(httpResponse.statusCode)")
                    throw NetworkError.unauthorized
                }

                let refreshResponse = try JSONDecoder().decode(RefreshTokenResponseDTO.self, from: data)

                guard let newAccessToken = refreshResponse.accessToken else {
                    Logger.network.error("Token refresh failed: missing access token")
                    throw NetworkError.unauthorized
                }

                await tokenStorage.setAccessToken(newAccessToken)
                if let newRefreshToken = refreshResponse.refreshToken {
                    await tokenStorage.setRefreshToken(newRefreshToken)
                }

                let newCredential = KickInAuthenticationCredential(
                    accessToken: newAccessToken,
                    refreshToken: refreshResponse.refreshToken ?? credential.refreshToken,
                    expiration: Date.distantFuture
                )

                Logger.network.info("Token refresh succeeded")
                completion(.success(newCredential))
            } catch {
                Logger.network.error("Token refresh failed: \(error.localizedDescription)")
                await handleLogout()
                completion(.failure(error))
            }
        }
    }

    func didRequest(_ urlRequest: URLRequest, with response: HTTPURLResponse, failDueToAuthenticationError error: any Error) -> Bool {
        return response.statusCode == 401 || response.statusCode == 419
    }

    /// 이 요청이 현재 Credential로 인증된 요청이 아니라면, 이전 토큰으로 보낸 요청이라고 판단함. 굳이 refresh 하지 않고 넘김
    /// 요청 A -> AccessToken = token 1
    /// 서버에서 401, 419 응답
    /// Alamofire가 refresh 시도 -> AccessToken = token2
    /// 이미 token1로 보낸 요청이 다시 401, 419를 받음
    /// 다시 refresh 시도 (무한 루프) 이걸 방지
    func isRequest(_ urlRequest: URLRequest, authenticatedWith credential: Credential) -> Bool {
        guard let authorizationHeader = urlRequest.value(forHTTPHeaderField: "Authorization") else { return false }
        return authorizationHeader == "\(credential.accessToken)"
    }

    // MARK: - Private Methods

    private func handleLogout() async {
        await tokenStorage.clearTokens()

        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("UserDidLogout"),
                object: nil
            )
        }
    }
}
