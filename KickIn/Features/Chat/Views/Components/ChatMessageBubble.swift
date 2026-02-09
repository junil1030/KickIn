//
//  ChatMessageBubble.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import SwiftUI
import CachingKit

struct ChatMessageBubble: View {
    @Environment(\.cachingKit) private var cachingKit
    @ObservedObject var viewModel: ChatDetailViewModel

    let config: MessageDisplayConfig
    let myUserId: String

    @State private var showImageViewer = false
    @State private var selectedImageIndex = 0
    @State private var selectedUserProfile: UserProfileInfo?
    @State private var selectedPDF: PDFInfo?

    private var message: ChatMessageUIModel {
        config.message
    }

    struct UserProfileInfo: Identifiable {
        let id: String
        let userId: String
        let userName: String
    }

    struct PDFInfo: Identifiable {
        let id = UUID()
        let url: URL
        let fileName: String
    }

    private var mediaItems: [MediaItem] {
        message.mediaItems(roomId: config.roomId ?? "")
    }

    private var linkMetadata: [LinkMetadata] {
        let metadata = viewModel.getLinkMetadata(for: message.id)
        return metadata
    }

    private var hasTextAbove: Bool {
        guard let content = message.content, !content.isEmpty else { return false }
        if !linkMetadata.isEmpty {
            let displayText = message.detectedURLs.reduce(content) { text, link in
                text.replacingOccurrences(of: link.url, with: "")
            }.trimmingCharacters(in: .whitespacesAndNewlines)
            return !displayText.isEmpty
        }
        return true
    }

    private var hasTextContent: Bool {
        // 텍스트, 링크 프리뷰, 업로드 상태, 실패 메시지가 있는 경우
        let hasText = message.content != nil && !message.content!.isEmpty
        let hasMetadata = !linkMetadata.isEmpty
        let hasUploadState = message.uploadState != nil || message.isTemporary || message.sendFailed
        return hasText || hasMetadata || hasUploadState
    }

    var body: some View {
        VStack(alignment: message.isSentByMe ? .trailing : .leading, spacing: 4) {
            // 이미지는 버블 없이 먼저 표시 (카카오톡 스타일)
            if !mediaItems.isEmpty {
                HStack(alignment: .bottom, spacing: 8) {
                    if message.isSentByMe {
                        Spacer()

                        if config.showTime && !hasTextContent {
                            timeText
                        }

                        mediaContent
                    } else {
                        // 프로필 영역 공간 확보
                        if config.showProfile {
                            profileImage
                        } else {
                            Color.clear
                                .frame(width: 36, height: 36)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            if config.showNickname {
                                Text(message.senderNickname)
                                    .font(.caption1(.pretendardMedium))
                                    .foregroundColor(.gray75)
                            }

                            HStack(alignment: .bottom, spacing: 4) {
                                mediaContent

                                if config.showTime && !hasTextContent {
                                    timeText
                                }
                            }
                        }

                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
            }

            // 텍스트 버블은 나중에 표시
            if hasTextContent {
                HStack(alignment: .bottom, spacing: 8) {
                    if message.isSentByMe {
                        Spacer()

                        if config.showTime {
                            timeText
                        }

                        textContent
                            .background(Color.deepCream)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        // 프로필 이미지 영역 (조건부 표시)
                        if !mediaItems.isEmpty {
                            // 이미지가 있으면 프로필 공간만 확보
                            Color.clear
                                .frame(width: 36, height: 0)
                        } else {
                            // 이미지가 없으면 프로필 표시
                            if config.showProfile {
                                profileImage
                            } else {
                                Color.clear
                                    .frame(width: 36, height: 36)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            if config.showNickname && mediaItems.isEmpty {
                                Text(message.senderNickname)
                                    .font(.caption1(.pretendardMedium))
                                    .foregroundColor(.gray75)
                            }

                            HStack(alignment: .bottom, spacing: 4) {
                                textContent
                                    .background(Color.gray30)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                if config.showTime {
                                    timeText
                                }
                            }
                        }

                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, config.showProfile ? 4 : 1)  // 연속 메시지는 패딩 축소
        .sheet(isPresented: $showImageViewer) {
            FullScreenImageViewer(
                mediaItems: mediaItems,
                initialIndex: selectedImageIndex,
                isPresented: $showImageViewer
            )
        }
        .sheet(item: $selectedPDF) { pdfInfo in
            PDFViewerSheet(
                pdfURL: pdfInfo.url,
                fileName: pdfInfo.fileName,
                isPresented: Binding(
                    get: { selectedPDF != nil },
                    set: { if !$0 { selectedPDF = nil } }
                )
            )
        }
        .sheet(item: $selectedUserProfile) { profileInfo in
            UserProfileSheetView(
                userId: profileInfo.userId,
                userName: profileInfo.userName
            )
        }
    }

    // 텍스트, 링크 프리뷰, 상태 메시지만 포함 (버블용)
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let content = message.content, !content.isEmpty {
                let detectedLinks = message.detectedURLs
                let displayText = {
                    if !linkMetadata.isEmpty {
                        // 링크 프리뷰가 있으면 URL들을 제거
                        return detectedLinks.reduce(content) { text, link in
                            text.replacingOccurrences(of: link.url, with: "")
                        }.trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        return content
                    }
                }()

                // 텍스트가 있을 때만 표시
                if !displayText.isEmpty {
                    if !detectedLinks.isEmpty && linkMetadata.isEmpty {
                        // URL이 있지만 프리뷰가 없는 경우 클릭 가능한 텍스트로 표시
                        ClickableTextView(
                            text: displayText,
                            detectedLinks: detectedLinks
                        ) { url in
                            if let url = URL(string: url) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                    } else {
                        // 일반 텍스트 또는 프리뷰가 있는 경우
                        Text(displayText)
                            .font(.body2(.pretendardMedium))
                            .foregroundColor(.gray90)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, linkMetadata.isEmpty ? 8 : 0)
                    }
                }
            }

            // 링크 프리뷰 카드
            if !linkMetadata.isEmpty {
                ForEach(linkMetadata, id: \.url) { metadata in
                    LinkPreviewCard(
                        metadata: metadata,
                        isSentByMe: message.isSentByMe,
                        hasTextAbove: hasTextAbove
                    )
                    .onTapGesture {
                        if let url = URL(string: metadata.url) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }

            // 비디오 업로드 상태 표시
            if let uploadState = message.uploadState {
                VStack(spacing: 4) {
                    ProgressView(value: uploadState.progress)
                        .progressViewStyle(.linear)
                        .tint(.deepCream)

                    Text(uploadState.displayText)
                        .font(.caption2(.pretendardMedium))
                        .foregroundColor(.gray60)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            // 일반 메시지 전송 중 표시 (비디오가 아닌 경우)
            else if message.isTemporary {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("전송 중...")
                        .font(.caption2(.pretendardMedium))
                        .foregroundColor(.gray60)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            if message.sendFailed {
                HStack(spacing: 8) {
                    Text("전송 실패")
                        .font(.caption2(.pretendardMedium))
                        .foregroundColor(.red)

                    HStack(spacing: 4) {
                        // 재전송 버튼
                        Button {
                            Task {
                                await viewModel.retryFailedMessage(chatId: message.id)
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.deepCream)
                                .clipShape(Circle())
                        }

                        // 삭제 버튼
                        Button {
                            Task {
                                await viewModel.deleteFailedMessage(chatId: message.id)
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.gray60)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }

    // 이미지/비디오/PDF 그리드 (버블 없음)
    private var mediaContent: some View {
        MessageImageGrid(
            mediaItems: mediaItems,
            isSentByMe: message.isSentByMe,
            onImageTap: { item, index in
                if item.type == .pdf {
                    if let url = item.url.thumbnailURL {
                        selectedPDF = PDFInfo(
                            url: url,
                            fileName: item.fileName ?? "document.pdf"
                        )
                    }
                } else {
                    selectedImageIndex = index
                    showImageViewer = true
                }
            }
        )
    }

    private var profileImage: some View {
        Group {
            if let profileImagePath = message.senderProfileImage,
               let url = profileImagePath.thumbnailURL {
                CachedAsyncImage(
                    url: url,
                    targetSize: CGSize(width: 36, height: 36),
                    cachingKit: cachingKit
                ) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray45)
                        .frame(width: 36, height: 36)
                }
            } else {
                Circle()
                    .fill(Color.gray45)
                    .frame(width: 36, height: 36)
            }
        }
        .onTapGesture {
            if !message.isSentByMe,
               let userId = message.senderUserId {
                selectedUserProfile = UserProfileInfo(
                    id: userId,
                    userId: userId,
                    userName: message.senderNickname
                )
            }
        }
    }

    private var timeText: some View {
        Text(message.createdAt.toChatTime() ?? "")
            .font(.caption2(.pretendardMedium))
            .foregroundColor(.gray60)
    }
}
