//
//  ChatRoomUIModel.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation

struct ChatRoomUIModel: Identifiable, Hashable {
    let id: String
    let otherParticipant: ParticipantInfo
    let lastMessage: LastMessageInfo?
    let updatedAt: String

    struct ParticipantInfo: Hashable {
        let userId: String
        let nickname: String
        let profileImage: String?
        let introduction: String?
    }

    struct LastMessageInfo: Hashable {
        let content: String
        let createdAt: String
        let senderName: String
        let isMyMessage: Bool
    }
}

extension ChatRoomItemDTO {
    func toUIModel(myUserId: String) -> ChatRoomUIModel? {
        guard let roomId = self.roomId else { return nil }

        // 상대방 찾기 (나를 제외한 participant)
        guard let otherParticipant = participants?.first(where: { $0.userId != myUserId }) else {
            return nil
        }

        // 상대방 정보 변환
        let participantInfo = ChatRoomUIModel.ParticipantInfo(
            userId: otherParticipant.userId ?? "",
            nickname: otherParticipant.nick ?? "알 수 없는 사용자",
            profileImage: otherParticipant.profileImage,
            introduction: otherParticipant.introduction
        )

        // 최신 메시지 변환
        let lastMessageInfo: ChatRoomUIModel.LastMessageInfo? = {
            guard let lastChat = self.lastChat else { return nil }
            return ChatRoomUIModel.LastMessageInfo(
                content: lastChat.content ?? "",
                createdAt: lastChat.createdAt ?? "",
                senderName: lastChat.sender?.nick ?? "알 수 없음",
                isMyMessage: lastChat.sender?.userId == myUserId
            )
        }()

        return ChatRoomUIModel(
            id: roomId,
            otherParticipant: participantInfo,
            lastMessage: lastMessageInfo,
            updatedAt: self.updatedAt ?? ""
        )
    }
}
