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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase

    private let cachingKit = NetworkServiceFactory.shared.getCachingKit()
    private let lifecycleManager = ChatLifecycleManager.shared

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
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }

    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            if oldPhase == .background || oldPhase == .inactive {
                Logger.default.info("[KickInApp] App entered foreground")
                Task { @MainActor in
                    lifecycleManager.handleEnterForeground()
                }
            }
        case .background:
            Logger.default.info("[KickInApp] App entered background")
            Task { @MainActor in
                lifecycleManager.handleEnterBackground()
            }
        case .inactive:
            // Transitional state, no action needed
            break
        @unknown default:
            break
        }
    }
}
