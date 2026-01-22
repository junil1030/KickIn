//  UserProfileViewModel.swift
//  KickIn
//  Created by 서준일 on 01/22/26

import Foundation
import Combine
import OSLog

@MainActor
final class UserProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userProfile: UserProfileUIModel?
    @Published var userPosts: [UserPostUIModel] = []
    @Published var isLoadingProfile = false
    @Published var isLoadingPosts = false
    @Published var isCreatingChat = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private var nextCursor: String?
    private var hasMoreData = true
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()

    // MARK: - Public Methods

    /// 사용자 프로필 로드
    func loadUserProfile(userId: String) async {
        isLoadingProfile = true
        errorMessage = nil

        do {
            let response: UserProfileResponseDTO = try await networkService.request(
                UserRouter.userProfile(userId: userId)
            )

            userProfile = response.toUIModel()
            isLoadingProfile = false

            Logger.network.info("✅ User profile loaded: \(userId)")

        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to load user profile: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoadingProfile = false
        } catch {
            Logger.network.error("❌ Unknown error: \(error.localizedDescription)")
            errorMessage = "프로필을 불러오는데 실패했습니다."
            isLoadingProfile = false
        }
    }

    /// 사용자 게시글 로드 (페이지네이션)
    func loadUserPosts(userId: String, cursor: String? = nil) async {
        isLoadingPosts = true
        // 게시글 로딩은 errorMessage를 초기화하지 않음 (프로필 에러 유지)

        do {
            let response: PostsGeolocationResponseDTO = try await networkService.request(
                CommunityPostRouter.getUserPosts(
                    userId: userId,
                    category: nil,
                    limit: 10,
                    next: cursor
                )
            )

            let newPosts = response.data?.compactMap { $0.toUserPostUIModel() } ?? []

            if cursor == nil {
                // 첫 로드 - 데이터 교체
                userPosts = newPosts
            } else {
                // 추가 로드 - 데이터 append
                userPosts.append(contentsOf: newPosts)
            }

            // nextCursor가 "0"이면 더 이상 데이터가 없음
            if let nextCursor = response.nextCursor, nextCursor != "0" {
                self.nextCursor = nextCursor
                hasMoreData = true
            } else {
                self.nextCursor = nil
                hasMoreData = false
            }

            isLoadingPosts = false

            Logger.network.info("✅ Loaded \(newPosts.count) user posts (total: \(self.userPosts.count))")

        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to load user posts: \(error.localizedDescription)")
            // 게시글 로딩 실패는 조용히 처리 (빈 상태로 표시)
            isLoadingPosts = false
        } catch {
            Logger.network.error("❌ Unknown error: \(error.localizedDescription)")
            // 게시글 로딩 실패는 조용히 처리 (빈 상태로 표시)
            isLoadingPosts = false
        }
    }

    /// 마지막 아이템에 도달 시 자동으로 다음 페이지 로드
    func loadMoreIfNeeded(currentItem: UserPostUIModel, userId: String) async {
        guard let lastItem = userPosts.last else { return }
        guard currentItem.id == lastItem.id else { return }
        guard hasMoreData && !isLoadingPosts else { return }

        await loadUserPosts(userId: userId, cursor: nextCursor)
    }

    /// 채팅방 생성/조회 및 네비게이션
    /// - Returns: 성공 시 true (시트 dismiss용)
    func createOrNavigateToChat(userId: String, userName: String) async -> Bool {
        isCreatingChat = true
        errorMessage = nil

        do {
            let requestDTO = CreateChatRoomRequestDTO(opponentId: userId)
            let response: ChatRoomResponseDTO = try await networkService.request(
                ChatRouter.createOrGetChatRoom(requestDTO)
            )

            guard let roomId = response.roomId else {
                Logger.network.error("❌ No roomId in response")
                errorMessage = "채팅방 생성에 실패했습니다."
                isCreatingChat = false
                return false
            }

            // DeepLinkManager를 통해 채팅방으로 이동
            DeepLinkManager.shared.navigateToChatRoom(roomId: roomId)

            isCreatingChat = false
            Logger.network.info("✅ Chat room created/retrieved: \(roomId)")

            return true

        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to create chat room: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isCreatingChat = false
            return false
        } catch {
            Logger.network.error("❌ Unknown error: \(error.localizedDescription)")
            errorMessage = "채팅방 생성에 실패했습니다."
            isCreatingChat = false
            return false
        }
    }
}
