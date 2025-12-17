//
//  MockTokenStorage.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

#if DEBUG
import Foundation

actor MockTokenStorage: TokenStorageProtocol {
    private var accessToken: String?
    private var refreshToken: String?

    init(accessToken: String? = nil, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func getAccessToken() async -> String? {
        accessToken
    }

    func getRefreshToken() async -> String? {
        refreshToken
    }

    func setAccessToken(_ token: String) async {
        accessToken = token
    }

    func setRefreshToken(_ token: String) async {
        refreshToken = token
    }

    func clearTokens() async {
        accessToken = nil
        refreshToken = nil
    }
}
#endif
