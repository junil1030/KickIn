//
//  KeychainTokenStorage.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation
import Security

actor KeychainTokenStorage: TokenStorageProtocol {
    private let accessTokenKey = "com.KickIn.accessToken"
    private let refreshTokenKey = "com.KickIn.refreshToken"
    private let service = "com.KickIn.app"

    func getAccessToken() async -> String? {
        return await getToken(for: accessTokenKey)
    }

    func getRefreshToken() async -> String? {
        return await getToken(for: refreshTokenKey)
    }

    func setAccessToken(_ token: String) async {
        await setToken(token, for: accessTokenKey)
    }

    func setRefreshToken(_ token: String) async {
        await setToken(token, for: refreshTokenKey)
    }

    func clearTokens() async {
        await deleteToken(for: accessTokenKey)
        await deleteToken(for: refreshTokenKey)
    }

    // MARK: - Private Keychain Operations

    private func getToken(for key: String) async -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    private func setToken(_ token: String, for key: String) async {
        guard let data = token.data(using: .utf8) else { return }

        // Try to update first
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        // If update failed because item doesn't exist, add new item
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private func deleteToken(for key: String) async {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
