//
//  CreateChatRoomRequestDTO.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

struct CreateChatRoomRequestDTO: Encodable {
    let opponentId: String?

    enum CodingKeys: String, CodingKey {
        case opponentId = "opponent_id"
    }
}
