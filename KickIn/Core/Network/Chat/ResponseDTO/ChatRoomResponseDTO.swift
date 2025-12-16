//
//  ChatRoomResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct ChatRoomResponseDTO: Decodable {
    let roomId: String?
    let createdAt: String?
    let updatedAt: String?
    let participants: [ChatParticipantDTO]?
    let lastChat: LastChatDTO?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case createdAt
        case updatedAt
        case participants
        case lastChat
    }
}

struct ChatParticipantDTO: Decodable {
    let userId: String?
    let nick: String?
    let introduction: String?
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case introduction
        case profileImage
    }
}

struct LastChatDTO: Decodable {
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
}

struct ChatSenderDTO: Decodable {
    let userId: String?
    let nick: String?
    let introduction: String?
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case introduction
        case profileImage
    }
}
