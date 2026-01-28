//
//  ChatMessagesResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct ChatMessagesResponseDTO: Decodable {
    let data: [ChatMessageItemDTO]?
}

struct ChatMessageItemDTO: Decodable {
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

    init(
        chatId: String?,
        roomId: String?,
        content: String?,
        createdAt: String?,
        updatedAt: String?,
        sender: ChatSenderDTO?,
        files: [String]?
    ) {
        self.chatId = chatId
        self.roomId = roomId
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sender = sender
        self.files = files
    }
}
