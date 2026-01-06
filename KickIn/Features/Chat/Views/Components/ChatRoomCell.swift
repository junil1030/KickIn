//
//  ChatRoomCell.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import SwiftUI
import CachingKit

struct ChatRoomCell: View {
    @Environment(\.cachingKit) private var cachingKit

    let chatRoom: ChatRoomUIModel

    var body: some View {
        HStack(spacing: 12) {
            // 프로필 이미지
            CachedAsyncImage(
                url: getProfileImageURL(from: chatRoom.otherParticipant.profileImage),
                targetSize: CGSize(width: 48, height: 48),
                cachingKit: cachingKit
            ) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            } placeholder: {
                Circle()
                    .fill(Color.gray45)
                    .frame(width: 48, height: 48)
            }

            // 채팅 정보
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chatRoom.otherParticipant.nickname)
                        .font(.body1(.pretendardBold))
                        .foregroundColor(.gray90)

                    Spacer()

                    if let lastMessage = chatRoom.lastMessage {
                        Text(lastMessage.createdAt.timeAgoFromNow ?? "")
                            .font(.caption1(.pretendardMedium))
                            .foregroundColor(.gray60)
                    }
                }

                Text(chatRoom.lastMessage?.content ?? "아직 메시지가 없습니다")
                    .font(.body2(.pretendardMedium))
                    .foregroundColor(.gray75)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func getProfileImageURL(from path: String?) -> URL? {
        guard let path = path else { return nil }
        return path.thumbnailURL
    }
}

#Preview {
    VStack {
        ChatRoomCell(chatRoom: ChatRoomUIModel(
            id: "1",
            otherParticipant: ChatRoomUIModel.ParticipantInfo(
                userId: "user1",
                nickname: "김철수",
                profileImage: nil,
                introduction: "안녕하세요"
            ),
            lastMessage: ChatRoomUIModel.LastMessageInfo(
                content: "안녕하세요! 매물 관련해서 문의드립니다.",
                createdAt: "2026-01-05T09:00:00.000Z",
                senderName: "김철수",
                isMyMessage: false
            ),
            updatedAt: "2026-01-05T09:00:00.000Z"
        ))

        Divider()

        ChatRoomCell(chatRoom: ChatRoomUIModel(
            id: "2",
            otherParticipant: ChatRoomUIModel.ParticipantInfo(
                userId: "user2",
                nickname: "이영희",
                profileImage: nil,
                introduction: nil
            ),
            lastMessage: nil,
            updatedAt: "2026-01-04T15:30:00.000Z"
        ))
    }
    .environment(\.cachingKit, .shared)
}
