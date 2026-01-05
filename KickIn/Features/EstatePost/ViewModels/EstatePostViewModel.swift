//
//  EstatePostViewModel.swift
//  KickIn
//
//  Created by 서준일 on 01/02/26.
//

import Foundation
import Combine
import OSLog

final class EstatePostViewModel: ObservableObject {
    @Published var posts: [EstatePostUIModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var deleteMessage: String?

    private let estateId: String
    private var nextCursor: String? = nil
    private var hasMoreData = true
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()

    // MARK: - Initialization

    init(estateId: String) {
        self.estateId = estateId
    }

    // MARK: - Public Methods

    func loadPosts() async {
        await fetchPosts(cursor: nil)
    }

    func loadMoreIfNeeded(currentItem: EstatePostUIModel) async {
        guard let lastItem = posts.last else { return }
        guard currentItem.id == lastItem.id else { return }
        guard hasMoreData && !isLoading else { return }

        await fetchPosts(cursor: nextCursor)
    }

    func deletePost(postId: String) async {
        await MainActor.run {
            deleteMessage = nil
        }

        do {
            let response: MessageResponseDTO = try await networkService.request(
                CommunityPostRouter.deletePost(postId: postId)
            )

            await MainActor.run {
                // 성공 시 배열에서 제거
                self.posts.removeAll { $0.id == postId }
                self.deleteMessage = response.message
            }

            Logger.network.info("✅ Post deleted successfully: \(postId)")

        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to delete post: \(error.localizedDescription)")
            await MainActor.run {
                self.deleteMessage = error.localizedDescription
            }
        } catch {
            Logger.network.error("❌ Unknown error while deleting post: \(error.localizedDescription)")
            await MainActor.run {
                self.deleteMessage = "게시글 삭제에 실패했습니다."
            }
        }
    }
}

// MARK: - Load Data
extension EstatePostViewModel {
    private func fetchPosts(cursor: String?) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let response: PostsGeolocationResponseDTO = try await networkService.request(
                CommunityPostRouter.getPostsByGeolocation(
                    category: estateId,
                    longitude: nil,
                    latitude: nil,
                    maxDistance: nil,
                    limit: nil,
                    next: cursor,
                    orderBy: nil
                )
            )

            let newPosts = response.data?.map { $0.toEstatePostUIModel() } ?? []

            await MainActor.run {
                if cursor == nil {
                    // 첫 로드
                    self.posts = newPosts
                } else {
                    // 추가 로드
                    self.posts.append(contentsOf: newPosts)
                }

                // nextCursor가 "0"이면 더 이상 데이터가 없음
                if let nextCursor = response.nextCursor, nextCursor != "0" {
                    self.nextCursor = nextCursor
                    self.hasMoreData = true
                } else {
                    self.nextCursor = nil
                    self.hasMoreData = false
                }

                self.isLoading = false
            }

            Logger.network.info("✅ Loaded \(newPosts.count) posts for estate ID: \(self.estateId) (total: \(self.posts.count))")

        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to load posts: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        } catch {
            Logger.network.error("❌ Unknown error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "게시글을 불러오는데 실패했습니다."
                self.isLoading = false
            }
        }
    }
}
