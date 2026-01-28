//
//  AppDelegate.swift
//  KickIn
//
//  Created by 서준일 on 1/7/26.
//

import UIKit
import OSLog
import Firebase
import FirebaseMessaging
import iamport_ios
import RealmSwift

class AppDelegate: NSObject, UIApplicationDelegate {

    private let tokenStorage = NetworkServiceFactory.shared.getTokenStorage()
    private let paymentViewModel = PaymentViewModel()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Realm 초기화
        configureRealm()

        // Firebase 초기화
        FirebaseApp.configure()
        
        // 원격 알림 시스템에 앱을 등록
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNs)
            UNUserNotificationCenter.current().delegate = self

            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
              options: authOptions,
              completionHandler: { _, _ in }
            )
        } else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        // 메시지 대리자 설정
        Messaging.messaging().delegate = self

        paymentViewModel.retryPendingValidations()
        
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        paymentViewModel.retryPendingValidations()
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return OrientationManager.shared.lockedOrientation
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // 포그라운드에서 알림을 받았을 때 (앱이 실행 중일 때)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo


        Task { @MainActor in
            // 현재 활성화된 채팅방인지 확인
            if let roomId = userInfo["roomId"] as? String {
                let isActiveChatRoom = ChatStateManager.shared.isActiveChatRoom(roomId)

                if isActiveChatRoom {
                    completionHandler([])
                } else {
                    completionHandler([.banner, .sound, .badge])
                }
            } else {
                // roomId가 없으면 일반 알림으로 표시
                completionHandler([.banner, .sound, .badge])
            }
        }
    }

    // 알림을 탭했을 때 (백그라운드/종료 상태에서)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        Task { @MainActor in
            // DeepLinkManager를 통해 채팅방으로 이동
            DeepLinkManager.shared.handlePushNotification(userInfo: userInfo)
        }

        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {

        guard let fcmToken = fcmToken else { return }

        Logger.auth.info("Firebase registration token: \(String(describing: fcmToken))")

        Task {
            // Keychain에 저장 (로그인 시 서버에 전송됨)
            await tokenStorage.setFCMToken(fcmToken)
        }
    }
}

// MARK: - Realm Configuration
extension AppDelegate {
    private func configureRealm() {
        let schemaVersion: UInt64 = 1

        let config = Realm.Configuration(
            schemaVersion: schemaVersion,
            migrationBlock: { _, _ in }
        )

        Realm.Configuration.defaultConfiguration = config

        // Realm 파일 저장 위치 로그
        if let realmURL = config.fileURL {
            Logger.database.info("📁 Realm 저장 위치: \(realmURL.path)")
        }
    }
}

// MARK: - PG
extension AppDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Iamport.shared.receivedURL(url)
        return true
    }
}
