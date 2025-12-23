//
//  AuthHeaderProvider.swift
//  KickIn
//
//  Created by 서준일 on 12/23/25.
//

import Foundation
import CachingKit

/// Header provider that automatically injects authentication tokens and API keys
final class AuthHeaderProvider: HeaderProvider {
    // MARK: - Properties

    private let tokenStorage: any TokenStorageProtocol

    // MARK: - Initialization

    init(tokenStorage: any TokenStorageProtocol) {
        self.tokenStorage = tokenStorage
    }

    // MARK: - HeaderProvider

    func headers() async -> [String: String] {
        var headers: [String: String] = [:]

        // Add API key
        headers["SeSACKey"] = await APIConfig.apikey

        // Add access token if available
        if let accessToken = await tokenStorage.getAccessToken() {
            headers["Authorization"] = accessToken
        }

        return headers
    }
}
