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

class AppDelegate: NSObject, UIApplicationDelegate {
    
    private let tokenStorage = NetworkServiceFactory.shared.getTokenStorage()
    private let paymentViewModel = PaymentViewModel()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
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
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        
        guard let fcmToken = fcmToken else { return }
        
        Logger.auth.info("Firebase registration token: \(String(describing: fcmToken))")
        
        Task {
            await tokenStorage.setFCMToken(fcmToken)
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
