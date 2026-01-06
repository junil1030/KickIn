//
//  SocketEvent.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation

enum SocketEvent: String {
    // Client → Server
    case connect = "connect"
    case disconnect = "disconnect"

    // Server → Client (메시지 수신)
    case chat = "chat"
    case error = "error"
    case reconnect = "reconnect"
}
