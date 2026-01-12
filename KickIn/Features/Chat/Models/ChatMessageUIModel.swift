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

    // MARK: - Parsed Files

    /// 실제 미디어 파일만 반환 (썸네일 제외)
    var mediaFiles: [String] {
        files.filter { !$0.contains("-thumb") }
    }

    // MARK: - Media Items

    func mediaItems(roomId: String) -> [MediaItem] {
        mediaFiles.map { filePath in
            let thumbnailURL: String

            if filePath.mediaType == .video {
                // 비디오의 경우 매칭되는 썸네일 찾기
                thumbnailURL = findThumbnail(for: filePath) ?? filePath
            } else {
                // 이미지는 자기 자신이 썸네일
                thumbnailURL = filePath
            }

            return MediaItem(
                id: "\(id)_\(filePath)",
                type: filePath.mediaType,
                url: filePath,
                thumbnailURL: thumbnailURL,
                createdAt: createdAt,
                roomId: roomId
            )
        }
    }

    /// 비디오 파일에 매칭되는 썸네일 찾기
    /// - Parameter videoPath: 비디오 파일 경로 (예: /data/chats/KickIn-UUID_timestamp.mp4)
    /// - Returns: 썸네일 파일 경로 (예: /data/chats/KickIn-UUID-thumb_timestamp.jpg)
    private func findThumbnail(for videoPath: String) -> String? {
        // 파일명 추출
        let fileName = (videoPath as NSString).lastPathComponent
        let baseName = (fileName as NSString).deletingPathExtension

        // "_timestamp" 제거해서 UUID 부분만 추출
        // 예: "KickIn-BAAE399D-FB1A-4ED8-BC25-50C3A4E5E678_1768222036156" → "KickIn-BAAE399D-FB1A-4ED8-BC25-50C3A4E5E678"
        guard let underscoreIndex = baseName.lastIndex(of: "_") else {
            return nil
        }

        let uuid = String(baseName[..<underscoreIndex])

        // files 배열에서 UUID가 포함되고 "-thumb"이 있는 파일 찾기
        return files.first { thumbnail in
            thumbnail.contains(uuid) && thumbnail.contains("-thumb")
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
