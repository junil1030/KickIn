//
//  LoginView.swift
//  KickIn
//
//  Created by 서준일 on 12/17/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // 카카오 로그인 버튼
            Button(action: {
                viewModel.handleKakaoLogin()
            }) {
                Image("kakao_login_image")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
            }
            .padding(.horizontal, 40)

            // Apple 로그인 버튼
            Button(action: {
                viewModel.handleAppleLogin()
            }) {
                Image("apple_login_image")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
            }
            .padding(.horizontal, 40)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
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
    }
}

#Preview {
    LoginView()
}
