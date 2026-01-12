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
    let uploadState: VideoUploadProgress?

    // MARK: - Initializers
    init(
        id: String,
        content: String?,
        createdAt: String,
        senderNickname: String,
        senderProfileImage: String?,
        files: [String],
        isSentByMe: Bool,
        isTemporary: Bool,
        sendFailed: Bool,
        uploadState: VideoUploadProgress? = nil
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.senderNickname = senderNickname
        self.senderProfileImage = senderProfileImage
        self.files = files
        self.isSentByMe = isSentByMe
        self.isTemporary = isTemporary
        self.sendFailed = sendFailed
        self.uploadState = uploadState
    }

    // MARK: - Media Items
    func mediaItems(roomId: String) -> [MediaItem] {
        files.map { filePath in
            MediaItem(
                id: "\(id)_\(filePath)",
                type: filePath.mediaType,
                url: filePath,
                thumbnailURL: filePath,
                createdAt: createdAt,
                roomId: roomId
            )
        }
    }
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
