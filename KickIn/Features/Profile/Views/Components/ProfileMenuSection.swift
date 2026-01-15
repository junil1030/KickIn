//
//  ProfileMenuSection.swift
//  KickIn
//
//  Created by 서준일 on 01/16/26
//

import SwiftUI

struct ProfileMenuSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption1(.pretendardMedium))
                .foregroundStyle(Color.gray60)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.gray0)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    ProfileMenuSection(title: "설정") {
        ProfileMenuRow(
            icon: "bell.fill",
            title: "알림 설정",
            action: { }
        )

        ProfileMenuRow(
            icon: "lock.fill",
            title: "개인정보 설정",
            action: { }
        )
    }
    .padding()
    .defaultBackground()
}
