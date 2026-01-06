//
//  ChatRoomListViewModel.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation
import Combine
import OSLog

final class ChatRoomListViewModel: ObservableObject {
    @Published var chatRooms: [ChatRoomUIModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    private let tokenStorage = NetworkServiceFactory.shared.getTokenStorage()

    func loadChatRooms() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        // myUserId 조회
        let myUserId = await tokenStorage.getUserId() ?? ""

        do {
            let response: ChatRoomsResponseDTO = try await networkService.request(ChatRouter.getChatRooms)

            let rooms = response.data?
                .compactMap { $0.toUIModel(myUserId: myUserId) }
                .sorted { $0.updatedAt > $1.updatedAt }
                ?? []

            await MainActor.run {
                self.chatRooms = rooms
                self.isLoading = false
            }

            Logger.chat.info("✅ Loaded \(rooms.count) chat rooms")

        } catch let error as NetworkError {
            Logger.chat.error("❌ Failed to load chat rooms: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        } catch {
            Logger.chat.error("❌ Unknown error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "채팅방 목록을 불러오는데 실패했습니다."
                self.isLoading = false
            }
        }
    }
}
