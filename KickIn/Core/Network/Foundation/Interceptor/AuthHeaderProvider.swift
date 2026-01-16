//
//  AuthHeaderProvider.swift
//  KickIn
//
//  Created by 서준일 on 12/23/25.
//

import Foundation
import CachingKit

/// Header provider that injects API key and Authorization for CachingKit
final class AuthHeaderProvider: HeaderProvider {
    private let tokenStorage: any TokenStorageProtocol

    init(tokenStorage: any TokenStorageProtocol) {
        self.tokenStorage = tokenStorage
    }

    func headers() async -> [String: String] {
        var headers = ["SeSACKey": APIConfig.apikey]

        // Add Authorization header if access token exists
        if let accessToken = await tokenStorage.getAccessToken(), !accessToken.isEmpty {
            headers["Authorization"] = accessToken
        }

        return headers
    }
}
