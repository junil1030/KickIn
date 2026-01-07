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
    private var fcmToken: String?
    private var userId: String?

    init(accessToken: String? = nil, refreshToken: String? = nil, fcmToken: String? = nil, userId: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.fcmToken = fcmToken
        self.userId = userId
    }

    func getAccessToken() async -> String? {
        accessToken
    }

    func getRefreshToken() async -> String? {
        refreshToken
    }
    
    func getFCMToken() async -> String? {
        fcmToken
    }

    func getUserId() async -> String? {
        userId
    }

    func setAccessToken(_ token: String) async {
        accessToken = token
    }

    func setRefreshToken(_ token: String) async {
        refreshToken = token
    }
    
    func setFCMToken(_ token: String) async {
        fcmToken = token
    }

    func setUserId(_ userId: String) async {
        self.userId = userId
    }

    func clearTokens() async {
        accessToken = nil
        refreshToken = nil
        fcmToken = nil
        userId = nil
    }
}
#endif
