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
    @Published var commentText = ""
    @Published var isCommentLoading = false
    @Published var replyToCommentId: String?
    @Published var replyToNick: String?
    @Published var currentUserId: String?

    private let postId: String
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    private let tokenStorage = NetworkServiceFactory.shared.getTokenStorage()

    // MARK: - Initialization

    init(postId: String) {
        self.postId = postId
        Task {
            await loadCurrentUserId()
        }
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

    func createComment() async {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        await MainActor.run {
            isCommentLoading = true
        }

        Logger.network.info("📡 Creating comment for postId: \(self.postId)")

        do {
            let requestDTO = PostCommentRequestDTO(
                parentCommentId: replyToCommentId,
                content: commentText
            )

            let _: PostResponseDTO = try await networkService.request(
                CommunityPostCommentRouter.createComment(postId: postId, requestDTO)
            )

            await MainActor.run {
                self.commentText = ""
                self.replyToCommentId = nil
                self.replyToNick = nil
                self.isCommentLoading = false
            }

            Logger.network.info("✅ Comment created successfully")

            // Reload post detail to update comments
            await loadPostDetail()

        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to create comment: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isCommentLoading = false
            }
        } catch {
            Logger.network.error("❌ Unknown error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "댓글 작성에 실패했습니다."
                self.isCommentLoading = false
            }
        }
    }

    func setReplyTo(commentId: String, nick: String) {
        replyToCommentId = commentId
        replyToNick = nick
    }

    func cancelReply() {
        replyToCommentId = nil
        replyToNick = nil
    }

    func deleteComment(commentId: String) async {
        Logger.network.info("📡 Deleting comment: \(commentId)")

        do {
            try await networkService.request(CommunityPostCommentRouter.deleteComment(postId: postId, commentId: commentId))

            Logger.network.info("✅ Comment deleted successfully")

            // Reload post detail to update comments
            await loadPostDetail()

        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to delete comment: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        } catch {
            Logger.network.error("❌ Unknown error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "댓글 삭제에 실패했습니다."
            }
        }
    }

    // MARK: - Private Methods

    private func loadCurrentUserId() async {
        let userId = await tokenStorage.getUserId()
        await MainActor.run {
            self.currentUserId = userId
        }
        Logger.network.info("Current User ID: \(userId ?? "nil")")
    }
}
