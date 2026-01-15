//
//  ProfileHeaderView.swift
//  KickIn
//
//  Created by 서준일 on 01/16/26
//

import SwiftUI
import CachingKit

struct ProfileHeaderView: View {
    let profile: UserProfileUIModel
    let onEditProfile: () -> Void

    @Environment(\.cachingKit) private var cachingKit

    var body: some View {
        VStack(spacing: 16) {
            // 프로필 이미지
            profileImageView(profile.profileImage)
                .padding(.top, 24)

            // 닉네임
            Text(profile.nick ?? "사용자")
                .font(.title1(.pretendardBold))
                .foregroundStyle(Color.gray90)

            // 소개글
            if let introduction = profile.introduction, !introduction.isEmpty {
                Text(introduction)
                    .font(.body2(.pretendardRegular))
                    .foregroundStyle(Color.gray60)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 40)
            }

            // 프로필 편집 버튼
            Button {
                onEditProfile()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.caption1(.pretendardMedium))
                    Text("프로필 편집")
                        .font(.body3(.pretendardMedium))
                }
                .foregroundStyle(Color.gray75)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray30)
                .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }
}

// MARK: - Private Views
private extension ProfileHeaderView {
    func profileImageView(_ profileImage: String?) -> some View {
        Group {
            if let profileImage = profileImage,
               let imageURL = profileImage.thumbnailURL {
                CachedAsyncImage(
                    url: imageURL,
                    targetSize: CGSize(width: 100, height: 100),
                    cachingKit: cachingKit
                ) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Color.gray30, lineWidth: 1)
                        }
                } placeholder: {
                    Circle()
                        .fill(Color.gray30)
                        .frame(width: 100, height: 100)
                        .overlay {
                            ProgressView()
                        }
                }
            } else {
                Circle()
                    .fill(Color.gray30)
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray45)
                    }
            }
        }
    }
}

#Preview {
    ProfileHeaderView(
        profile: UserProfileUIModel(
            userId: "test123",
            nick: "테스트 사용자",
            introduction: "안녕하세요. 테스트 소개글입니다.",
            profileImage: nil
        ),
        onEditProfile: { }
    )
}
