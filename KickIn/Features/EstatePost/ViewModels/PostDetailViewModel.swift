//
//  PostDetailViewModel.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation
import Combine
import OSLog

final class PostDetailViewModel: ObservableObject {
    @Published var post: PostDetailUIModel?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let postId: String
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()

    // MARK: - Initialization

    init(postId: String) {
        self.postId = postId
    }

    // MARK: - Public Methods

    func loadPostDetail() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        Logger.network.info("📡 Fetching post detail for postId: \(self.postId)")

        do {
            let response: PostResponseDTO = try await networkService.request(
                CommunityPostRouter.getPostDetail(postId: postId)
            )

            let postDetail = response.toPostDetailUIModel()

            await MainActor.run {
                self.post = postDetail
                self.isLoading = false
            }

            Logger.network.info("✅ Post detail loaded successfully")
            Logger.network.debug("Post ID: \(postDetail.id)")
            Logger.network.debug("Title: \(postDetail.title)")
            Logger.network.debug("Author: \(postDetail.authorName)")
            Logger.network.debug("Like Count: \(postDetail.likeCount)")
            Logger.network.debug("Comment Count: \(postDetail.comments.count)")

        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to load post detail: \(error.localizedDescription)")
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
