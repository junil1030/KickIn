//
//  SignUpViewModel.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import Foundation
import Combine

final class SignUpViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var toastMessage: String?
    @Published var email = "" {
        didSet {
            if email != oldValue {
                isEmailVerified = false
                emailErrorMessage = nil
                password = ""
                nick = ""
                phoneNumber = ""
                introduction = ""
                passwordErrorMessage = nil
                nickErrorMessage = nil
                phoneNumberErrorMessage = nil
                introductionErrorMessage = nil
            }
        }
    }
    @Published var password = ""
    @Published var nick = ""
    @Published var phoneNumber = ""
    @Published var introduction = ""
    @Published var isEmailVerified = false
    @Published var emailErrorMessage: String?
    @Published var passwordErrorMessage: String?
    @Published var nickErrorMessage: String?
    @Published var phoneNumberErrorMessage: String?
    @Published var introductionErrorMessage: String?

    var onSignUpSuccess: (() -> Void)?

    private let networkService: NetworkServiceProtocol
    private let tokenStorage: TokenStorageProtocol

    init(
        networkService: NetworkServiceProtocol = NetworkServiceFactory.shared.makeNetworkService(),
        tokenStorage: TokenStorageProtocol = NetworkServiceFactory.shared.getTokenStorage()
    ) {
        self.networkService = networkService
        self.tokenStorage = tokenStorage
    }

    func handleEmailDuplicationCheck() {
        if !validateEmail() {
            return
        }

        Task {
            await MainActor.run {
                isLoading = true
            }

            do {
                let _: EmailValidationResponseDTO = try await networkService.request(
                    UserRouter.emailValidation(email: email)
                )
                await MainActor.run {
                    isEmailVerified = true
                    isLoading = false
                }
            } catch let error as NetworkError {
                await MainActor.run {
                    toastMessage = error.localizedDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    toastMessage = "이메일 중복 확인에 실패했습니다."
                    isLoading = false
                }
            }
        }
    }

    func handleSignUp() {
        guard isEmailVerified else { return }
        if !validateSignUpInfo() {
            return
        }

        Task {
            await MainActor.run {
                isLoading = true
            }

            let fcmToken = await tokenStorage.getFCMToken()
            let requestDTO = JoinRequestDTO(
                email: email,
                password: password,
                nick: nick,
                phoneNum: phoneNumber,
                introduction: introduction,
                deviceToken: fcmToken
            )

            do {
                let _: JoinResponseDTO = try await networkService.request(
                    UserRouter.join(requestDTO)
                )
                await MainActor.run {
                    isLoading = false
                    onSignUpSuccess?()
                }
            } catch let error as NetworkError {
                await MainActor.run {
                    toastMessage = error.localizedDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    toastMessage = "회원가입에 실패했습니다."
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Validation

private extension SignUpViewModel {
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

    var isNickValid: Bool {
        let trimmed = nick.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^[^\\-.,?*@@+\\^\\$\\{\\}\\(\\)\\|\\[\\]\\\\]+$"
        return !trimmed.isEmpty && NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: trimmed)
    }

    @discardableResult
    func validateEmail() -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            emailErrorMessage = "이메일을 입력해주세요."
        } else if !isEmailValid {
            emailErrorMessage = "이메일 형식을 확인해주세요."
        } else {
            emailErrorMessage = nil
        }

        return emailErrorMessage == nil
    }

    @discardableResult
    func validatePassword() -> Bool {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            passwordErrorMessage = "비밀번호를 입력해주세요."
        } else if !isPasswordValid {
            passwordErrorMessage = "비밀번호는 8자 이상, 영문/숫자/특수문자(@$!%*#?&)를 포함해주세요."
        } else {
            passwordErrorMessage = nil
        }

        return passwordErrorMessage == nil
    }

    func validateSignUpInfo() -> Bool {
        let isEmailValid = validateEmail()
        let isPasswordValid = validatePassword()

        let trimmedNick = nick.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedNick.isEmpty {
            nickErrorMessage = "닉네임을 입력해주세요."
        } else if !isNickValid {
            nickErrorMessage = "닉네임에는 - . , ? * - @ + ^ $ { } ( ) | [ ] \\ 를 사용할 수 없습니다."
        } else {
            nickErrorMessage = nil
        }

        let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPhone.isEmpty {
            phoneNumberErrorMessage = "전화번호를 입력해주세요."
        } else {
            phoneNumberErrorMessage = nil
        }

        let trimmedIntro = introduction.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedIntro.isEmpty {
            introductionErrorMessage = "소개를 입력해주세요."
        } else {
            introductionErrorMessage = nil
        }

        return isEmailValid
            && isPasswordValid
            && nickErrorMessage == nil
            && phoneNumberErrorMessage == nil
            && introductionErrorMessage == nil
    }
}
