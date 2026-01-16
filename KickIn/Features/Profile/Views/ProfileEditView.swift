//
//  ProfileEditView.swift
//  KickIn
//
//  Created by 서준일 on 01/16/26
//

import SwiftUI
import CachingKit

struct ProfileEditView: View {
    @StateObject private var viewModel = ProfileEditViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.cachingKit) private var cachingKit

    @State private var showImagePicker = false
    @State private var showCancelAlert = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) {
                    // MARK: - 프로필 이미지 섹션
                    profileImageSection

                    // MARK: - 입력 폼 섹션
                    VStack(spacing: 20) {
                        // 닉네임
                        ProfileEditTextField(
                            title: "닉네임",
                            placeholder: "닉네임을 입력하세요",
                            text: $viewModel.nick,
                            maxLength: 20
                        )

                        // 소개글
                        ProfileEditTextEditor(
                            title: "소개",
                            placeholder: "자기소개를 입력하세요",
                            text: $viewModel.introduction,
                            maxLength: 100
                        )

                        // 전화번호
                        ProfileEditTextField(
                            title: "전화번호",
                            placeholder: "010-1234-5678",
                            text: $viewModel.phoneNum,
                            keyboardType: .phonePad,
                            maxLength: 13
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 24)
            }
            .defaultBackground()
            .navigationTitle("프로필 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        showCancelAlert = true
                    }
                    .foregroundStyle(Color.gray75)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            let success = await viewModel.saveProfile()
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .font(.body2(.pretendardBold))
                    .foregroundStyle(Color.deepCoast)
                    .disabled(viewModel.isSaving || viewModel.nick.isEmpty)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .overlay {
                if viewModel.isSaving {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)

                        if viewModel.uploadProgress > 0 && viewModel.uploadProgress < 1 {
                            Text("이미지 업로드 중...")
                                .font(.body3(.pretendardMedium))
                                .foregroundStyle(Color.gray75)

                            ProgressView(value: viewModel.uploadProgress)
                                .frame(width: 200)
                        } else {
                            Text("저장 중...")
                                .font(.body3(.pretendardMedium))
                                .foregroundStyle(Color.gray75)
                        }
                    }
                    .padding(24)
                    .background(Color.gray0)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 10)
                }
            }
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("변경사항 취소", isPresented: $showCancelAlert) {
                Button("계속 편집", role: .cancel) { }
                Button("취소", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("편집한 내용이 저장되지 않습니다.")
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImageData: $viewModel.selectedImageData)
            }
            .task {
                await viewModel.loadProfile()
            }
        }
    }
}

// MARK: - 프로필 이미지 섹션
private extension ProfileEditView {
    var profileImageSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                // 프로필 이미지
                Group {
                    if let selectedImageData = viewModel.selectedImageData,
                       let uiImage = UIImage(data: selectedImageData) {
                        // 새로 선택한 이미지
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(Color.gray30, lineWidth: 1)
                            }
                    } else if let profileImage = viewModel.profileImage,
                              let imageURL = profileImage.thumbnailURL {
                        // 기존 이미지
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
                                .overlay {
                                    Circle()
                                        .stroke(Color.gray30, lineWidth: 1)
                                }
                        } placeholder: {
                            Circle()
                                .fill(Color.gray30)
                                .frame(width: 120, height: 120)
                                .overlay {
                                    ProgressView()
                                }
                        }
                    } else {
                        // 기본 이미지
                        Circle()
                            .fill(Color.gray30)
                            .frame(width: 120, height: 120)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray45)
                            }
                    }
                }

                // 편집 버튼
                Button {
                    showImagePicker = true
                } label: {
                    Circle()
                        .fill(Color.deepCoast)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.body3(.pretendardMedium))
                                .foregroundStyle(Color.white)
                        }
                        .overlay {
                            Circle()
                                .stroke(Color.gray0, lineWidth: 2)
                        }
                }
            }

            Text("프로필 사진 변경")
                .font(.caption1(.pretendardMedium))
                .foregroundStyle(Color.gray60)
        }
    }
}

// MARK: - ProfileEditTextField
struct ProfileEditTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var maxLength: Int = 100

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.body3(.pretendardMedium))
                .foregroundStyle(Color.gray75)

            TextField(placeholder, text: $text)
                .font(.body2(.pretendardRegular))
                .foregroundStyle(Color.gray90)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.gray0)
                .cornerRadius(8)
                .keyboardType(keyboardType)
                .onChange(of: text) { _, newValue in
                    if newValue.count > maxLength {
                        text = String(newValue.prefix(maxLength))
                    }
                }

            HStack {
                Spacer()
                Text("\(text.count)/\(maxLength)")
                    .font(.caption2(.pretendardRegular))
                    .foregroundStyle(Color.gray45)
            }
        }
    }
}

// MARK: - ProfileEditTextEditor
struct ProfileEditTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var maxLength: Int = 100

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.body3(.pretendardMedium))
                .foregroundStyle(Color.gray75)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body2(.pretendardRegular))
                        .foregroundStyle(Color.gray45)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }

                TextEditor(text: $text)
                    .font(.body2(.pretendardRegular))
                    .foregroundStyle(Color.gray90)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .background(Color.gray0)
                    .cornerRadius(8)
                    .onChange(of: text) { _, newValue in
                        if newValue.count > maxLength {
                            text = String(newValue.prefix(maxLength))
                        }
                    }
            }
            .background(Color.gray0)
            .cornerRadius(8)

            HStack {
                Spacer()
                Text("\(text.count)/\(maxLength)")
                    .font(.caption2(.pretendardRegular))
                    .foregroundStyle(Color.gray45)
            }
        }
    }
}

#Preview {
    ProfileEditView()
}
