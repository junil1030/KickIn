//
//  ChatMessageRepositoryProtocol.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation

protocol ChatMessageRepositoryProtocol {
    // CRUD Operations
    func saveMessages(_ messages: [ChatMessageObject]) async throws
    func saveMessage(_ message: ChatMessageObject) async throws
    func saveMessageFromDTO(_ messageDTO: ChatMessageItemDTO, myUserId: String) async throws
    func createAndSaveMessage(
        chatId: String,
        roomId: String,
        content: String?,
        createdAt: String,
        updatedAt: String?,
        senderUserId: String?,
        senderNickname: String?,
        senderProfileImage: String?,
        senderIntroduction: String?,
        files: [String],
        isSentByMe: Bool,
        isTemporary: Bool
    ) async throws
    func fetchMessages(roomId: String, limit: Int, beforeDate: String?) async throws -> [ChatMessageObject]
    func fetchMessagesAsUIModels(roomId: String, limit: Int, beforeDate: String?) async throws -> [ChatMessageUIModel]
    func fetchChatIds(roomId: String) async throws -> Set<String>
    func deleteMessage(chatId: String) async throws
    func updateMessageStatus(chatId: String, isTemporary: Bool, failReason: String?) async throws

    // Metadata Operations
    func getMetadata(roomId: String) async throws -> ChatRoomMetadataObject?
    func updateMetadata(roomId: String, lastCursor: String?, hasMoreData: Bool) async throws
}
