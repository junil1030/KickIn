//
//  ChatMessageUIModel.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation

struct ChatMessageUIModel: Identifiable, Hashable {
    let id: String
    let content: String?
    let createdAt: String
    let senderNickname: String
    let senderProfileImage: String?
    let files: [String]
    let isSentByMe: Bool
    let isTemporary: Bool
    let sendFailed: Bool
}

// MARK: - Realm Object → UIModel Extension

extension ChatMessageObject {
    func toUIModel() -> ChatMessageUIModel {
        ChatMessageUIModel(
            id: chatId,
            content: content,
            createdAt: createdAt,
            senderNickname: senderNickname ?? "알 수 없음",
            senderProfileImage: senderProfileImage,
            files: Array(files),
            isSentByMe: isSentByMe,
            isTemporary: isTemporary,
            sendFailed: sendFailedReason != nil
        )
    }
}
