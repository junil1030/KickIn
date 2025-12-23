//
//  KickInApp.swift
//  KickIn
//
//  Created by 서준일 on 12/10/25.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth
import OSLog

@main
struct KickInApp: App {
    private let cachingKit = NetworkServiceFactory.shared.getCachingKit()

    init() {
        KakaoSDK.initSDK(appKey: Config.kakaoNativeAppKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.cachingKit, cachingKit)
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        let _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}
