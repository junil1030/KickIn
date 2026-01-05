//
//  ProfileView.swift
//  KickIn
//
//  Created by 서준일 on 12/18/25.
//

import SwiftUI
import CachingKit

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.cachingKit) private var cachingKit

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let profile = viewModel.userProfile {
                VStack(spacing: 24) {
                    // 프로필 이미지
                    profileImageView(profile.profileImage)
                        .padding(.top, 40)

                    // 프로필 정보
                    VStack(spacing: 12) {
                        // 닉네임
                        if let nick = profile.nick {
                            Text(nick)
                                .font(.body3(.pretendardBold))
                                .foregroundStyle(Color.gray90)
                        }

                        // 소개글
                        if let introduction = profile.introduction {
                            Text(introduction)
                                .font(.body2(.pretendardRegular))
                                .foregroundStyle(Color.gray60)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        // 사용자 ID
                        if let userId = profile.userId {
                            Text("ID: \(userId)")
                                .font(.caption1(.pretendardRegular))
                                .foregroundStyle(Color.gray45)
                        }
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Text("프로필을 불러올 수 없습니다")
                        .font(.body2(.pretendardBold))
                        .foregroundStyle(Color.gray60)

                    Text(errorMessage)
                        .font(.caption1(.pretendardRegular))
                        .foregroundStyle(Color.gray45)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("프로필")
        .defaultBackground()
        .task {
            await viewModel.loadMyProfile()
        }
    }
}

// MARK: - SubViews
private extension ProfileView {
    func profileImageView(_ profileImage: String?) -> some View {
        Group {
            if let profileImage = profileImage,
               let imageURL = profileImage.thumbnailURL {
                CachedAsyncImage(
                    url: imageURL,
                    targetSize: CGSize(width: 120, height: 120),
                    cachingKit: cachingKit
                ) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray45)
                        .frame(width: 120, height: 120)
                        .overlay {
                            ProgressView()
                        }
                }
            } else {
                Circle()
                    .fill(Color.gray45)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray60)
                    }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
