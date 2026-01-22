//  UserProfileHeaderSection.swift
//  KickIn
//  Created by 서준일 on 01/22/26

import SwiftUI
import CachingKit

struct UserProfileHeaderSection: View {
    @Environment(\.cachingKit) private var cachingKit
    let profile: UserProfileUIModel?

    var body: some View {
        VStack(spacing: 12) {
            // 프로필 이미지 (80x80)
            Group {
                if let profileImagePath = profile?.profileImage,
                   let url = profileImagePath.thumbnailURL {
                    CachedAsyncImage(
                        url: url,
                        targetSize: CGSize(width: 80, height: 80),
                        cachingKit: cachingKit
                    ) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray30)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(profile?.nick?.first.map { String($0) } ?? "")
                                    .font(.title1(.pretendardBold))
                                    .foregroundColor(.gray60)
                            )
                    }
                } else {
                    // 기본 아바타 (이니셜)
                    Circle()
                        .fill(Color.gray30)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(profile?.nick?.first.map { String($0) } ?? "?")
                                .font(.title1(.pretendardBold))
                                .foregroundColor(.gray60)
                        )
                }
            }

            // 닉네임
            Text(profile?.nick ?? "Unknown")
                .font(.body2())
                .foregroundColor(.gray90)

            // 소개 (최대 3줄)
            if let introduction = profile?.introduction, !introduction.isEmpty {
                Text(introduction)
                    .font(.body2(.pretendardRegular))
                    .foregroundColor(.gray60)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 16)
    }
}
