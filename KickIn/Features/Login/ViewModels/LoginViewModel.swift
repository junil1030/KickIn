//
//  LoginViewModel.swift
//  KickIn
//
//  Created by 서준일 on 12/17/25.
//

import Foundation
import Combine
import AuthenticationServices
import OSLog
import KakaoSDKAuth
import KakaoSDKUser
import UIKit

// MARK: - LoginViewModel

final class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var toastMessage: String?
    @Published var email = ""
    @Published var password = ""
    @Published var emailErrorMessage: String?
    @Published var passwordErrorMessage: String?
    
    private let networkService: NetworkServiceProtocol
    private let tokenStorage: TokenStorageProtocol

    var onLoginSuccess: (() -> Void)?
    
    // MARK: - Initialization
    init(
        networkService: NetworkServiceProtocol = NetworkServiceFactory.shared.makeNetworkService(),
        tokenStorage: TokenStorageProtocol = NetworkServiceFactory.shared.getTokenStorage()
    ) {
        self.networkService = networkService
        self.tokenStorage = tokenStorage
    }

    // MARK: - Apple Sign In

    func handleAppleLogin() {
        Task {
            await MainActor.run {
                isLoading = true
            }

            do {
                let credential = try await performAppleAuthentication()
                await performAppleLogin(credential: credential)
            } catch let error as ASAuthorizationError {
                await MainActor.run {
                    // 사용자가 취소한 경우 에러 메시지 표시 안함
                    if error.code != .canceled {
                        toastMessage = "Apple 로그인에 실패했습니다."
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    toastMessage = "Apple 로그인에 실패했습니다."
                    isLoading = false
                }
            }
        }
    }

    private func performAppleAuthentication() async throws -> AppleLoginCredential {
        return try await withCheckedThrowingContinuation { continuation in
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate(continuation: continuation)

            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            controller.performRequests()

            // Delegate를 강하게 유지하기 위해 저장
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Kakao Sign In

    func handleKakaoLogin() {
        Task {
            do {
                let oauthToken = try await performKakaoAuthentication()

                await performKakaoLogin(oauthToken: oauthToken)
            } catch {
                await MainActor.run {
                    toastMessage = "카카오 로그인에 실패했습니다."
                    isLoading = false
                }
            }
        }
    }

    private func performKakaoAuthentication() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            // 카카오톡 설치 여부 확인
            if UserApi.isKakaoTalkLoginAvailable() {
                // 카카오톡으로 로그인
                UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                    if let error = error {
                        Logger.auth.error("loginWithKakaoTalk error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else if let token = oauthToken?.accessToken {
                        Logger.auth.info("loginWithKakaoTalk success, token: \(token)")
                        continuation.resume(returning: token)
                    } else {
                        Logger.auth.error("loginWithKakaoTalk: token is nil")
                        continuation.resume(throwing: NSError(domain: "KakaoLogin", code: -1, userInfo: [NSLocalizedDescriptionKey: "토큰을 가져올 수 없습니다."]))
                    }
                }
            } else {
                // 카카오 계정으로 로그인
                UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                    if let error = error {
                        Logger.auth.error("loginWithKakaoAccount error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else if let token = oauthToken?.accessToken {
                        Logger.auth.info("loginWithKakaoAccount success, token: \(token)")
                        continuation.resume(returning: token)
                    } else {
                        Logger.auth.error("loginWithKakaoAccount: token is nil")
                        continuation.resume(throwing: NSError(domain: "KakaoLogin", code: -1, userInfo: [NSLocalizedDescriptionKey: "토큰을 가져올 수 없습니다."]))
                    }
                }
            }
        }
    }

    // MARK: - Common Login

    private func performSocialLogin(_ router: any APIRouter) async {
        await MainActor.run {
            isLoading = true
        }

        do {
            let response: LoginResponseDTO = try await networkService.request(router)

            // 토큰 및 사용자 정보 저장
            if let accessToken = response.accessToken,
               let refreshToken = response.refreshToken,
               let userId = response.userId {

                Logger.auth.info("🔑 Saving tokens and userId to Keychain...")
                Logger.auth.info("📝 User ID to save: \(userId)")

                await tokenStorage.setAccessToken(accessToken)
                await tokenStorage.setRefreshToken(refreshToken)
                await tokenStorage.setUserId(userId)
                // 저장 확인
                if let savedUserId = await tokenStorage.getUserId() {
                    Logger.auth.info("✅ User ID successfully saved to Keychain: \(savedUserId)")
                } else {
                    Logger.auth.error("❌ Failed to save User ID to Keychain")
                }

#if DEBUG
                Logger.auth.info("Access Token: \(accessToken)")
                Logger.auth.info("Refresh Token: \(refreshToken)")
                Logger.auth.info("User ID: \(userId)")
#endif

                await MainActor.run {
                    isLoading = false
                    onLoginSuccess?()
                }
            } else {
                Logger.auth.error("❌ Missing required fields in login response - accessToken: \(response.accessToken != nil), refreshToken: \(response.refreshToken != nil), userId: \(response.userId != nil)")
            }
        } catch let error as NetworkError {
            Logger.auth.error("NetworkError: \(error.localizedDescription)")
            await MainActor.run {
                toastMessage = error.localizedDescription
                isLoading = false
            }
        } catch {
            Logger.auth.error("Unknown error: \(error.localizedDescription)")
            await MainActor.run {
                toastMessage = "로그인에 실패했습니다."
                isLoading = false
            }
        }
    }

    private func performKakaoLogin(oauthToken: String) async {
        
        let fcmToken = await tokenStorage.getFCMToken()
        Logger.auth.info("FCM Token: \(fcmToken ?? "FCM 토큰을 가져올 수 없음")")
        
        let requestDTO = KakaoLoginRequestDTO(
            oauthToken: oauthToken,
            deviceToken: fcmToken
        )

        await performSocialLogin(UserRouter.kakaoLogin(requestDTO))
    }

    private func performAppleLogin(credential: AppleLoginCredential) async {
        
        let fcmToken = await tokenStorage.getFCMToken()
        Logger.auth.info("FCM Token: \(fcmToken ?? "FCM 토큰을 가져올 수 없음")")
        
        let requestDTO = AppleLoginRequestDTO(
            idToken: credential.identityToken,
            deviceToken: fcmToken
        )

        await performSocialLogin(UserRouter.appleLogin(requestDTO))
    }

    // MARK: - Email Login

    func handleEmailLogin() {
        if !validateCredentials() {
            return
        }

        Task {
            let fcmToken = await tokenStorage.getFCMToken()
            let requestDTO = LoginRequestDTO(
                email: email,
                password: password,
                deviceToken: fcmToken
            )
            await performSocialLogin(UserRouter.login(requestDTO))
        }
    }

    @discardableResult
    private func validateCredentials() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty {
            emailErrorMessage = "이메일을 입력해주세요."
        } else if !isEmailValid {
            emailErrorMessage = "이메일 형식을 확인해주세요."
        } else {
            emailErrorMessage = nil
        }

        if trimmedPassword.isEmpty {
            passwordErrorMessage = "비밀번호를 입력해주세요."
        } else if !isPasswordValid {
            passwordErrorMessage = "비밀번호는 8자 이상, 영문/숫자/특수문자(@$!%*#?&)를 포함해주세요."
        } else {
            passwordErrorMessage = nil
        }

        return emailErrorMessage == nil && passwordErrorMessage == nil
    }
}

// MARK: - Validation

extension LoginViewModel {
    var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let atIndex = trimmed.firstIndex(of: "@") else { return false }
        let domainPart = trimmed[trimmed.index(after: atIndex)...]
        return !trimmed.isEmpty && domainPart.contains(".")
    }

    var isPasswordValid: Bool {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*#?&]).{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: trimmed)
    }

    var canSubmitCredentials: Bool {
        isEmailValid && isPasswordValid
    }
}

// MARK: - Apple Sign In Delegate

private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<AppleLoginCredential, Error>

    init(continuation: CheckedContinuation<AppleLoginCredential, Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let credential = AppleLoginCredential(from: appleIDCredential) else {
            continuation.resume(throwing: NSError(domain: "AppleLogin", code: -1, userInfo: [NSLocalizedDescriptionKey: "인증 정보를 가져올 수 없습니다."]))
            return
        }

        continuation.resume(returning: credential)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}
