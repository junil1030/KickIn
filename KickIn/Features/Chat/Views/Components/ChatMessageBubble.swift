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
        if !metadata.isEmpty {
            print("📎 [ChatMessageBubble] Found \(metadata.count) metadata for message \(message.id)")
        }
        return metadata
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isSentByMe {
                Spacer()

                // 내 메시지: 시간이 버블 왼쪽
                if config.showTime {
                    timeText
                }

                messageContent
                    .background(Color.deepCream)
                    .cornerRadius(12)
            } else {
                // 프로필 이미지 영역 (조건부 표시)
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

                    // 상대방 메시지: 버블과 시간을 HStack으로 묶어서 버블 바로 옆에 시간 표시
                    HStack(alignment: .bottom, spacing: 4) {
                        messageContent
                            .background(Color.gray30)
                            .cornerRadius(12)

                        if config.showTime {
                            timeText
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(.horizontal, 16)
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

    private var messageContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let content = message.content, !content.isEmpty {
                let detectedLinks = message.detectedURLs

                if !detectedLinks.isEmpty {
                    // URL이 있는 경우 클릭 가능한 텍스트로 표시
                    ClickableTextView(
                        text: content,
                        detectedLinks: detectedLinks
                    ) { url in
                        if let url = URL(string: url) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, linkMetadata.isEmpty ? 8 : 6)
                } else {
                    // 일반 텍스트
                    Text(content)
                        .font(.body2(.pretendardMedium))
                        .foregroundColor(.gray90)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            }

            // 링크 프리뷰 카드
            if !linkMetadata.isEmpty {
                ForEach(linkMetadata, id: \.url) { metadata in
                    LinkPreviewCard(
                        metadata: metadata,
                        isSentByMe: message.isSentByMe,
                        hasTextAbove: message.content != nil && !message.content!.isEmpty
                    )
                    .onTapGesture {
                        if let url = URL(string: metadata.url) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }

            if !mediaItems.isEmpty {
                MessageImageGrid(
                    mediaItems: mediaItems,
                    isSentByMe: message.isSentByMe,
                    onImageTap: { item, index in
                        if item.type == .pdf {
                            print("📄 [PDF Tap] item.url: \(item.url)")
                            if let url = item.url.thumbnailURL {
                                print("📄 [PDF Tap] Generated URL: \(url.absoluteString)")
                                selectedPDF = PDFInfo(
                                    url: url,
                                    fileName: item.fileName ?? "document.pdf"
                                )
                                print("📄 [PDF Tap] selectedPDF set: \(selectedPDF != nil)")
                            } else {
                                print("❌ [PDF Tap] Failed to create URL from: \(item.url)")
                            }
                        } else {
                            selectedImageIndex = index
                            showImageViewer = true
                        }
                    }
                )
                .padding(linkMetadata.isEmpty ? 8 : 0)
                .padding(.top, linkMetadata.isEmpty ? 0 : 8)
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
                Text("전송 실패")
                    .font(.caption2(.pretendardMedium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
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
