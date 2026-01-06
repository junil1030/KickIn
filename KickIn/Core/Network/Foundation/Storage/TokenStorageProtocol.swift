//
//  TokenStorageProtocol.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

protocol TokenStorageProtocol: Actor {
    func getAccessToken() async -> String?
    func getRefreshToken() async -> String?
    func getUserId() async -> String?
    func setAccessToken(_ token: String) async
    func setRefreshToken(_ token: String) async
    func setUserId(_ userId: String) async
    func clearTokens() async
}
