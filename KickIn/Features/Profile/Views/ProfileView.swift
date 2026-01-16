//
//  ProfileView.swift
//  KickIn
//
//  Created by 서준일 on 12/18/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.logoutAction) private var logoutAction

    @State private var showLogoutAlert = false
    @State private var showWithdrawAlert = false
    @State private var showEditProfile = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 400)
            } else if let profile = viewModel.userProfile {
                VStack(spacing: 0) {
                    // MARK: - 프로필 헤더 섹션
                    ProfileHeaderView(
                        profile: profile,
                        onEditProfile: {
                            showEditProfile = true
                        }
                    )

                    // MARK: - 메뉴 섹션들
                    VStack(spacing: 12) {
                        // 일반 설정
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

                        // 고객 지원
                        ProfileMenuSection(title: "고객 지원") {
                            ProfileMenuRow(
                                icon: "questionmark.circle.fill",
                                title: "고객센터",
                                action: { }
                            )

                            ProfileMenuRow(
                                icon: "doc.text.fill",
                                title: "이용약관",
                                action: { }
                            )

                            ProfileMenuRow(
                                icon: "hand.raised.fill",
                                title: "개인정보 처리방침",
                                action: { }
                            )
                        }

                        // 앱 정보
                        ProfileMenuSection(title: "앱 정보") {
                            ProfileMenuRow(
                                icon: "info.circle.fill",
                                title: "앱 버전",
                                value: Bundle.main.appVersion,
                                showChevron: false,
                                action: { }
                            )
                        }

                        // 계정 관리
                        ProfileMenuSection(title: "계정 관리") {
                            ProfileMenuRow(
                                icon: "rectangle.portrait.and.arrow.right",
                                title: "로그아웃",
                                titleColor: .gray75,
                                showChevron: false,
                                action: { showLogoutAlert = true }
                            )

                            ProfileMenuRow(
                                icon: "person.crop.circle.badge.minus",
                                title: "회원 탈퇴",
                                titleColor: .red,
                                showChevron: false,
                                action: { showWithdrawAlert = true }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            } else if let errorMessage = viewModel.errorMessage {
                ProfileErrorView(errorMessage: errorMessage) {
                    Task {
                        await viewModel.loadMyProfile()
                    }
                }
            }
        }
        .defaultBackground()
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadMyProfile()
        }
        .alert("로그아웃", isPresented: $showLogoutAlert) {
            Button("취소", role: .cancel) { }
            Button("로그아웃", role: .destructive) {
                Task {
                    await viewModel.logout()
                    logoutAction()
                }
            }
        } message: {
            Text("정말 로그아웃 하시겠습니까?")
        }
        .alert("회원 탈퇴", isPresented: $showWithdrawAlert) {
            Button("취소", role: .cancel) { }
            Button("탈퇴하기", role: .destructive) {
                // TODO: 회원 탈퇴 로직 구현
            }
        } message: {
            Text("회원 탈퇴 시 모든 데이터가 삭제됩니다.\n정말 탈퇴하시겠습니까?")
        }
        .sheet(isPresented: $showEditProfile) {
            ProfileEditView()
        }
        .onChange(of: showEditProfile) { _, isPresented in
            if !isPresented {
                // 편집 화면이 닫힐 때 프로필 새로고침
                Task {
                    await viewModel.loadMyProfile()
                }
            }
        }
    }
}

// MARK: - Bundle Extension
extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
