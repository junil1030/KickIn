//
//  SignUpView.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @State private var isPasswordVisible = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 12) {
                TextField("이메일 입력", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)

                Divider()
                    .background(viewModel.emailErrorMessage == nil ? Color.gray75 : Color.red)

                if let emailErrorMessage = viewModel.emailErrorMessage {
                    Text(emailErrorMessage)
                        .foregroundColor(.red)
                        .font(.caption1())
                }

                Button {
                    viewModel.handleEmailDuplicationCheck()
                } label: {
                    Text("중복 확인")
                        .font(.body1(.pretendardMedium))
                        .foregroundStyle(Color.gray0)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.deepCream)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            if viewModel.isEmailVerified {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Group {
                            if isPasswordVisible {
                                TextField("비밀번호 입력", text: $viewModel.password)
                            } else {
                                SecureField("비밀번호 입력", text: $viewModel.password)
                            }
                        }
                        .textContentType(.newPassword)

                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundStyle(Color.gray75)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()
                        .background(viewModel.passwordErrorMessage == nil ? Color.gray75 : Color.red)

                    if let passwordErrorMessage = viewModel.passwordErrorMessage {
                        Text(passwordErrorMessage)
                            .foregroundColor(.red)
                            .font(.caption1())
                    }

                    TextField("닉네임 입력", text: $viewModel.nick)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Divider()
                        .background(viewModel.nickErrorMessage == nil ? Color.gray75 : Color.red)

                    if let nickErrorMessage = viewModel.nickErrorMessage {
                        Text(nickErrorMessage)
                            .foregroundColor(.red)
                            .font(.caption1())
                    }

                    TextField("전화번호 입력", text: $viewModel.phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)

                    Divider()
                        .background(viewModel.phoneNumberErrorMessage == nil ? Color.gray75 : Color.red)

                    if let phoneNumberErrorMessage = viewModel.phoneNumberErrorMessage {
                        Text(phoneNumberErrorMessage)
                            .foregroundColor(.red)
                            .font(.caption1())
                    }

                    TextField("소개 입력", text: $viewModel.introduction, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)

                    Divider()
                        .background(viewModel.introductionErrorMessage == nil ? Color.gray75 : Color.red)

                    if let introductionErrorMessage = viewModel.introductionErrorMessage {
                        Text(introductionErrorMessage)
                            .foregroundColor(.red)
                            .font(.caption1())
                    }

                    Button {
                        viewModel.handleSignUp()
                    } label: {
                        Text("회원가입")
                            .font(.body1(.pretendardMedium))
                            .foregroundStyle(Color.gray0)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.deepCream)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .onAppear {
            viewModel.onSignUpSuccess = {
                dismiss()
            }
        }
        .toast(message: $viewModel.toastMessage)
        .defaultBackground()
        .navigationTitle("회원가입")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
}
