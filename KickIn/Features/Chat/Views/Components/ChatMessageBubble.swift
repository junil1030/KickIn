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

    let config: MessageDisplayConfig
    let myUserId: String

    private var message: ChatMessageUIModel {
        config.message
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
    }

    private var messageContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let content = message.content, !content.isEmpty {
                Text(content)
                    .font(.body2(.pretendardMedium))
                    .foregroundColor(.gray90)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }

            if !message.files.isEmpty {
                imageGrid
            }

            if message.isTemporary {
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
    }

    private var timeText: some View {
        Text(message.createdAt.toChatTime() ?? "")
            .font(.caption2(.pretendardMedium))
            .foregroundColor(.gray60)
    }

    private var imageGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
            ForEach(message.files, id: \.self) { filePath in
                if let url = filePath.thumbnailURL {
                    CachedAsyncImage(
                        url: url,
                        targetSize: CGSize(width: 200, height: 200),
                        cachingKit: cachingKit
                    ) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(8)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray30)
                            .frame(width: 100, height: 100)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(8)
    }
}
