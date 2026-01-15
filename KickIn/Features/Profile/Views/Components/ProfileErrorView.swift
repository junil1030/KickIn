//
//  ProfileErrorView.swift
//  KickIn
//
//  Created by 서준일 on 01/16/26
//

import SwiftUI

struct ProfileErrorView: View {
    let errorMessage: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.gray45)

            Text("프로필을 불러올 수 없습니다")
                .font(.body1(.pretendardBold))
                .foregroundStyle(Color.gray75)

            Text(errorMessage)
                .font(.body3(.pretendardRegular))
                .foregroundStyle(Color.gray60)
                .multilineTextAlignment(.center)

            Button {
                onRetry()
            } label: {
                Text("다시 시도")
                    .font(.body3(.pretendardMedium))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.deepCoast)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, minHeight: 400)
        .padding(.horizontal, 20)
    }
}

#Preview {
    ProfileErrorView(
        errorMessage: "네트워크 연결을 확인해주세요.",
        onRetry: { }
    )
    .defaultBackground()
}
