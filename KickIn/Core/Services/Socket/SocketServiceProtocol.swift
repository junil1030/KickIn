//
//  SocketServiceProtocol.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation

protocol SocketServiceProtocol {
    var isConnected: Bool { get }
    var currentRoom: String? { get }
    var messages: AsyncStream<ChatMessageItemDTO> { get }
    var connectionStates: AsyncStream<Bool> { get }

    func prepareNewConnection()
    func connect(roomID: String) async
    func disconnect()
    func reconnect() async
}
