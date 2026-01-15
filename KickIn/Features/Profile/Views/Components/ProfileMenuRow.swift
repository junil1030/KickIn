//
//  ProfileMenuRow.swift
//  KickIn
//
//  Created by 서준일 on 01/16/26
//

import SwiftUI

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var titleColor: Color = .gray90
    var showChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body2(.pretendardRegular))
                    .foregroundStyle(Color.gray60)
                    .frame(width: 24)

                Text(title)
                    .font(.body2(.pretendardRegular))
                    .foregroundStyle(titleColor)

                Spacer()

                if let value = value {
                    Text(value)
                        .font(.body3(.pretendardRegular))
                        .foregroundStyle(Color.gray45)
                }

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption1(.pretendardRegular))
                        .foregroundStyle(Color.gray45)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 0) {
        ProfileMenuRow(
            icon: "bell.fill",
            title: "알림 설정",
            action: { }
        )

        ProfileMenuRow(
            icon: "info.circle.fill",
            title: "앱 버전",
            value: "1.0.0",
            showChevron: false,
            action: { }
        )

        ProfileMenuRow(
            icon: "rectangle.portrait.and.arrow.right",
            title: "로그아웃",
            titleColor: .gray75,
            showChevron: false,
            action: { }
        )
    }
    .background(Color.gray0)
}
