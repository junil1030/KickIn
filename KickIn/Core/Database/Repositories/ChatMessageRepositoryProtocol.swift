//
//  ChatMessageRepositoryProtocol.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation

protocol ChatMessageRepositoryProtocol {
    // MARK: - User Operations
    func getOrCreateUser(userId: String, nickname: String, profileImage: String?, introduction: String?) async throws -> UserObject
    func updateUser(userId: String, nickname: String?, profileImage: String?, introduction: String?) async throws
    func getUser(userId: String) async throws -> UserObject?

    // MARK: - Room Operations
    func getOrCreateRoom(roomId: String, createdAt: String, participants: [UserObject]) async throws -> ChatRoomObject
    func getRoom(roomId: String) async throws -> ChatRoomObject?
    func updateRoomLastMessage(roomId: String, message: ChatMessageObject) async throws

    // MARK: - Message CRUD
    func saveMessage(_ message: ChatMessageObject) async throws
    func saveMessageFromDTO(_ messageDTO: ChatMessageItemDTO, roomId: String, myUserId: String) async throws
    func createAndSaveTemporaryMessage(
        chatId: String,
        roomId: String,
        content: String?,
        createdAt: String,
        senderUserId: String,
        senderNickname: String,
        senderProfileImage: String?,
        files: [String]
    ) async throws
    func fetchMessages(roomId: String, limit: Int, beforeDate: String?) async throws -> [ChatMessageObject]
    func fetchMessagesAsUIModels(roomId: String, limit: Int, beforeDate: String?) async throws -> [ChatMessageUIModel]
    func fetchChatIds(roomId: String) async throws -> Set<String>
    func deleteMessage(chatId: String) async throws
    func updateMessageStatus(chatId: String, isTemporary: Bool, failReason: String?) async throws

    // MARK: - Batch Operations
    func saveMessagesFromDTOs(_ messages: [ChatMessageItemDTO], roomId: String, myUserId: String) async throws

    // MARK: - Metadata Operations (Room 기반)
    func getMetadata(roomId: String) async throws -> (lastCursor: String?, hasMoreData: Bool)?
    func updateMetadata(roomId: String, lastCursor: String?, hasMoreData: Bool) async throws
}
