//
//  ContentView.swift
//  KickIn
//
//  Created by 서준일 on 12/10/25.
//

import SwiftUI
import OSLog

struct ContentView: View {
    @State private var isLoading = true
    @State private var isAuthenticated = false

    private let tokenStorage = NetworkServiceFactory.shared.getTokenStorage()

    var body: some View {
        Group {
            if isLoading {
                // 자동 로그인 체크 중
                ProgressView()
                    .scaleEffect(1.5)
            } else if isAuthenticated {
                // 로그인 됨 → HomeView
                HomeView()
            } else {
                // 로그인 안됨 → LoginView
                LoginView(onLoginSuccess: {
                    isAuthenticated = true
                })
            }
        }
        .task {
            await checkAutoLogin()
        }
    }

    private func checkAutoLogin() async {
        guard let refreshToken = await tokenStorage.getRefreshToken() else {
            isLoading = false
            return
        }

        // accessToken도 필요
        guard let accessToken = await tokenStorage.getAccessToken() else {
            await tokenStorage.clearTokens()
            isLoading = false
            return
        }

        do {
            let router = UserRouter.refreshToken(token: refreshToken)
            var urlRequest = try router.asURLRequest()

            // Authorization 헤더 추가
            urlRequest.setValue(accessToken, forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: urlRequest)

            let decoder = JSONDecoder()
            let refreshResponse = try decoder.decode(RefreshTokenResponseDTO.self, from: data)

            if let accessToken = refreshResponse.accessToken,
               let newRefreshToken = refreshResponse.refreshToken {
                await tokenStorage.setAccessToken(accessToken)
                await tokenStorage.setRefreshToken(newRefreshToken)

                isAuthenticated = true
            }
        } catch {
            Logger.auth.error("🔐 Auto login failed: \(error.localizedDescription)")
            await tokenStorage.clearTokens()
        }

        isLoading = false
    }
}

#Preview {
    ContentView()
}
