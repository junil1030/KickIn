//
//  ChatMessageResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct ChatMessageResponseDTO: Decodable {
    let chatId: String?
    let roomId: String?
    let content: String?
    let createdAt: String?
    let updatedAt: String?
    let sender: ChatSenderDTO?
    let files: [String]?

    enum CodingKeys: String, CodingKey {
        case chatId = "chat_id"
        case roomId = "room_id"
        case content
        case createdAt
        case updatedAt
        case sender
        case files
    }

    /// ChatMessageItemDTO로 변환
    func toMessageItemDTO() -> ChatMessageItemDTO {
        ChatMessageItemDTO(
            chatId: chatId,
            roomId: roomId,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sender: sender,
            files: files
        )
    }
}
