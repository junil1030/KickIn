//
//  BannerWebView.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import SwiftUI
import WebKit

struct BannerWebView: UIViewRepresentable {
    let url: URL
    var onCompleteAttendance: ((Int?) -> Void)?

    private let tokenStorage = NetworkServiceFactory.shared.getTokenStorage()

    func makeUIView(context: Context) -> WKWebView {
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "click_attendance_button")
        userContentController.add(context.coordinator, name: "complete_attendance")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        context.coordinator.webView = webView

        var request = URLRequest(url: url)
        request.setValue(APIConfig.apikey, forHTTPHeaderField: "SeSACKey")
        webView.load(request)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No update needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(tokenStorage: tokenStorage, onCompleteAttendance: onCompleteAttendance)
    }
}

extension BannerWebView {
    final class Coordinator: NSObject, WKScriptMessageHandler {
        private let tokenStorage: any TokenStorageProtocol
        private let onCompleteAttendance: ((Int?) -> Void)?
        weak var webView: WKWebView?

        init(
            tokenStorage: any TokenStorageProtocol,
            onCompleteAttendance: ((Int?) -> Void)?
        ) {
            self.tokenStorage = tokenStorage
            self.onCompleteAttendance = onCompleteAttendance
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "click_attendance_button":
                Task { [weak webView] in
                    guard let accessToken = await tokenStorage.getAccessToken() else { return }
                    let escapedToken = accessToken.replacingOccurrences(of: "'", with: "\\'")
                    let script = "requestAttendance('\(escapedToken)')"
                    await MainActor.run {
                        webView?.evaluateJavaScript(script)
                    }
                }

            case "complete_attendance":
                let attendanceCount: Int?
                if let count = message.body as? Int {
                    attendanceCount = count
                } else if let countString = message.body as? String {
                    attendanceCount = Int(countString)
                } else {
                    attendanceCount = nil
                }
                onCompleteAttendance?(attendanceCount)

            default:
                break
            }
        }

        deinit {
            webView?.configuration.userContentController.removeScriptMessageHandler(forName: "click_attendance_button")
            webView?.configuration.userContentController.removeScriptMessageHandler(forName: "complete_attendance")
        }
    }
}
