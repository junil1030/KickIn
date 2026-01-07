//
//  LoginView.swift
//  KickIn
//
//  Created by 서준일 on 12/17/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var email = ""
    @State private var password = ""
    var onLoginSuccess: (() -> Void)?

    init(onLoginSuccess: (() -> Void)? = nil) {
        self.onLoginSuccess = onLoginSuccess
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 12) {
                TextField("이메일 입력", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)

                Divider()

                SecureField("비밀번호 입력", text: $password)
                    .textContentType(.password)

                Divider()
                
                Button {
                    
                } label: {
                    Text("로그인")
                        .font(.body1(.pretendardMedium))
                        .foregroundStyle(Color.gray0)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.deepCream)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                
                HStack(spacing: 12) {
                    Button {
                        
                    } label: {
                        Text("아이디 찾기")
                            .font(.body2(.pretendardMedium))
                            .foregroundStyle(Color.gray75)
                            .frame(width: 80)
                    }
                    
                    Divider()
                        .foregroundStyle(Color.gray75)
                        .padding(4)

                    Button {
                        
                    } label: {
                        Text("비밀번호 찾기")
                            .font(.body2(.pretendardMedium))
                            .foregroundStyle(Color.gray75)
                            .frame(width: 80)
                    }
                }
                .frame(height: 40)
            }
            .padding(.horizontal, 20)
            
            Spacer()

            // 카카오 로그인 버튼
            Button(action: {
                viewModel.handleKakaoLogin()
            }) {
                Image("Login/kakao_login_image")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
            }
            .padding(.horizontal, 40)

            // Apple 로그인 버튼
            Button(action: {
                viewModel.handleAppleLogin()
            }) {
                Image("Login/apple_login_image")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
            }
            .padding(.horizontal, 40)
            
            Button(action: {
                
            }) {
                Text("이메일로 가입하기")
                    .font(.body1(.pretendardMedium))
                    .foregroundStyle(Color.gray100)
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray75, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 40)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption1())
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
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
            viewModel.onLoginSuccess = onLoginSuccess
        }
        .defaultBackground()
    }
}

#Preview {
    LoginView()
}
