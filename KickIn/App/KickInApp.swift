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

    init() {
        KakaoSDK.initSDK(appKey: Config.kakaoNativeAppKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        let _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}
