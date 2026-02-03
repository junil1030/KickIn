//  UserProfileSheetView.swift
//  KickIn
//  Created by 서준일 on 01/22/26

import SwiftUI

struct UserProfileSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = UserProfileViewModel()

    let userId: String
    let userName: String

    @State private var isOwnProfile = false
    @State private var shouldDismiss = false

    private let tokenStorage = NetworkServiceFactory.shared.getTokenStorage()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. 프로필 헤더 (상단 고정)
                UserProfileHeaderSection(profile: viewModel.userProfile)
                    .padding(.top, 20)

                Divider()
                    .background(Color.gray30)

                // 2. 게시글 리스트 (스크롤 가능)
                if viewModel.isLoadingProfile || viewModel.isLoadingPosts {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Text(errorMessage)
                            .font(.body2(.pretendardRegular))
                            .foregroundColor(.gray60)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Button {
                            Task {
                                await viewModel.loadUserProfile(userId: userId)
                                await viewModel.loadUserPosts(userId: userId)
                            }
                        } label: {
                            Text("다시 시도")
                                .font(.body2(.pretendardBold))
                                .foregroundColor(.gray90)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.deepCream)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if viewModel.userPosts.isEmpty {
                                // 빈 상태
                                Text("게시글이 없습니다")
                                    .font(.body2(.pretendardRegular))
                                    .foregroundColor(.gray60)
                                    .padding(.top, 40)
                            } else {
                                ForEach(viewModel.userPosts) { post in
                                    NavigationLink(destination: PostDetailView(postId: post.id)) {
                                        UserPostCardView(post: post)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .onAppear {
                                        Task {
                                            await viewModel.loadMoreIfNeeded(currentItem: post, userId: userId)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }

                // 3. 채팅 버튼 (하단 고정)
                if !isOwnProfile {
                    ChatInitiateButton(
                        isLoading: viewModel.isCreatingChat,
                        action: {
                            Task {
                                let success = await viewModel.createOrNavigateToChat(
                                    userId: userId,
                                    userName: userName
                                )
                                if success {
                                    shouldDismiss = true
                                }
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(Color.gray0)
            .navigationTitle(viewModel.userProfile?.nick ?? userName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            // 본인 프로필 확인
            let myUserId = await tokenStorage.getUserId() ?? ""
            isOwnProfile = (userId == myUserId)

            // 데이터 로드
            await viewModel.loadUserProfile(userId: userId)
            await viewModel.loadUserPosts(userId: userId)
        }
        .onChange(of: shouldDismiss) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }
}
