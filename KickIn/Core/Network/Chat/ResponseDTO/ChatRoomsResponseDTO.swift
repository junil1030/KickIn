//
//  ChatRoomsResponseDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct ChatRoomsResponseDTO: Decodable {
    let data: [ChatRoomItemDTO]?
}

struct ChatRoomItemDTO: Decodable {
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
