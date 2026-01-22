//
//  PostDetailView.swift
//  KickIn
//
//  Created by 서준일 on 01/02/26.
//

import SwiftUI
import CachingKit

struct PostDetailView: View {
    @Environment(\.cachingKit) private var cachingKit
    @StateObject private var viewModel: PostDetailViewModel

    @State private var showAuthorProfile = false
    @State private var showCommentAuthorProfile = false
    @State private var showReplyAuthorProfile = false
    @State private var selectedAuthor: (userId: String, name: String)?

    init(postId: String) {
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(postId: postId))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        loadingView()
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(message: errorMessage)
                    } else if let post = viewModel.post {
                        postContentView(post: post)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            commentInputView()
        }
        .defaultBackground()
        .navigationTitle("게시글 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.loadPostDetail()
        }
        .sheet(isPresented: $showAuthorProfile) {
            if let author = selectedAuthor {
                UserProfileSheetView(userId: author.userId, userName: author.name)
            }
        }
        .sheet(isPresented: $showCommentAuthorProfile) {
            if let author = selectedAuthor {
                UserProfileSheetView(userId: author.userId, userName: author.name)
            }
        }
        .sheet(isPresented: $showReplyAuthorProfile) {
            if let author = selectedAuthor {
                UserProfileSheetView(userId: author.userId, userName: author.name)
            }
        }
    }

    // MARK: - Subviews

    private func totalCommentCount(post: PostDetailUIModel) -> Int {
        let commentCount = post.comments.count
        let replyCount = post.comments.reduce(0) { $0 + $1.replies.count }
        return commentCount + replyCount
    }

    private func loadingView() -> some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("게시글을 불러오는 중...")
                .font(.body2(.pretendardRegular))
                .foregroundStyle(Color.gray60)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(Color.gray60)

            Text(message)
                .font(.body2(.pretendardRegular))
                .foregroundStyle(Color.gray60)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
        .padding(.horizontal, 40)
    }

    private func postContentView(post: PostDetailUIModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 제목
            Text(post.title)
                .font(.title1(.pretendardBold))
                .foregroundStyle(Color.gray90)

            // 작성자 정보
            HStack(spacing: 8) {
                Button {
                    selectedAuthor = (userId: post.authorId, name: post.authorName)
                    showAuthorProfile = true
                } label: {
                    authorProfileImageView(post.authorProfileImage, authorName: post.authorName, size: 40)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.body2(.pretendardBold))
                        .foregroundStyle(Color.gray90)

                    Text(post.createdAt.commentTimeAgo ?? "알 수 없음")
                        .font(.caption1(.pretendardRegular))
                        .foregroundStyle(Color.gray60)
                }
            }

            // 본문 내용
            Text(post.content)
                .font(.body2(.pretendardRegular))
                .foregroundStyle(Color.gray90)

            // 이미지들 (있는 경우)
            if !post.files.isEmpty {
                ForEach(post.files, id: \.self) { fileUrl in
                    postFileImageView(fileUrl)
                }
            }

            Divider()
                .background(Color.gray30)

            // 좋아요 수
            HStack {
                Image(systemName: post.isLike ? "heart.fill" : "heart")
                    .foregroundStyle(post.isLike ? Color.red : Color.gray60)
                Text("\(post.likeCount)")
                    .font(.body2(.pretendardRegular))
                    .foregroundStyle(Color.gray90)
            }

            // 댓글 수
            Text("댓글 \(totalCommentCount(post: post))개")
                .font(.body2(.pretendardBold))
                .foregroundStyle(Color.gray90)
                .padding(.top, 8)

            // 댓글 목록
            ForEach(post.comments) { comment in
                commentView(comment: comment, postAuthorId: post.authorId)
                    .padding(.bottom, comment.id != post.comments.last?.id ? 20 : 0)
            }
        }
        .padding(20)
    }

    private func commentView(comment: PostCommentUIModel, postAuthorId: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Button {
                    selectedAuthor = (userId: comment.authorId, name: comment.authorName)
                    showCommentAuthorProfile = true
                } label: {
                    authorProfileImageView(comment.authorProfileImage, authorName: comment.authorName, size: 36)
                }

                VStack(alignment: .leading, spacing: 4) {
                    // 작성자 이름
                    Text(comment.authorName)
                        .font(.body3(.pretendardBold))
                        .foregroundStyle(Color.gray90)

                    // 댓글 내용
                    Text(comment.content)
                        .font(.body2(.pretendardRegular))
                        .foregroundStyle(Color.gray90)

                    // 시간 및 작성자 표시
                    HStack(spacing: 4) {
                        if let timeAgo = comment.createdAt.commentTimeAgo {
                            Text(timeAgo)
                                .font(.caption2(.pretendardRegular))
                                .foregroundStyle(Color.gray60)
                        }

                        if comment.authorId == postAuthorId {
                            Text("•")
                                .font(.caption2(.pretendardRegular))
                                .foregroundStyle(Color.gray60)

                            Text("작성자")
                                .font(.caption2(.pretendardRegular))
                                .foregroundStyle(Color.gray60)
                        }

                        Text("•")
                            .font(.caption2(.pretendardRegular))
                            .foregroundStyle(Color.gray60)

                        Button(action: {
                            viewModel.setReplyTo(commentId: comment.id, nick: comment.authorName)
                        }) {
                            Text("답글 달기")
                                .font(.caption2(.pretendardBold))
                                .foregroundStyle(Color.gray60)
                        }

                        // 본인 댓글일 경우 삭제 버튼
                        if let currentUserId = viewModel.currentUserId,
                           comment.authorId == currentUserId {
                            Text("•")
                                .font(.caption2(.pretendardRegular))
                                .foregroundStyle(Color.gray60)

                            Button(action: {
                                Task {
                                    await viewModel.deleteComment(commentId: comment.id)
                                }
                            }) {
                                Text("삭제")
                                    .font(.caption2(.pretendardBold))
                                    .foregroundStyle(Color.red)
                            }
                        }
                    }
                }

                Spacer()
            }

            // 대댓글들
            if !comment.replies.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(comment.replies) { reply in
                        replyView(reply: reply, postAuthorId: postAuthorId)
                    }
                }
                .padding(.leading, 44)
                .padding(.top, 8)
            }
        }
    }

    private func replyView(reply: PostCommentReplyUIModel, postAuthorId: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Button {
                selectedAuthor = (userId: reply.authorId, name: reply.authorName)
                showReplyAuthorProfile = true
            } label: {
                authorProfileImageView(reply.authorProfileImage, authorName: reply.authorName, size: 32)
            }

            VStack(alignment: .leading, spacing: 4) {
                // 작성자 이름
                Text(reply.authorName)
                    .font(.body3(.pretendardBold))
                    .foregroundStyle(Color.gray90)

                // 답글 내용
                Text(reply.content)
                    .font(.body2(.pretendardRegular))
                    .foregroundStyle(Color.gray90)

                // 시간 및 작성자 표시
                HStack(spacing: 4) {
                    if let timeAgo = reply.createdAt.commentTimeAgo {
                        Text(timeAgo)
                            .font(.caption2(.pretendardRegular))
                            .foregroundStyle(Color.gray60)
                    }

                    if reply.authorId == postAuthorId {
                        Text("•")
                            .font(.caption2(.pretendardRegular))
                            .foregroundStyle(Color.gray60)

                        Text("작성자")
                            .font(.caption2(.pretendardRegular))
                            .foregroundStyle(Color.gray60)
                    }

                    // 본인 대댓글일 경우 삭제 버튼
                    if let currentUserId = viewModel.currentUserId,
                       reply.authorId == currentUserId {
                        Text("•")
                            .font(.caption2(.pretendardRegular))
                            .foregroundStyle(Color.gray60)

                        Button(action: {
                            Task {
                                await viewModel.deleteComment(commentId: reply.id)
                            }
                        }) {
                            Text("삭제")
                                .font(.caption2(.pretendardBold))
                                .foregroundStyle(Color.red)
                        }
                    }
                }
            }

            Spacer()
        }
    }

    // MARK: - Image Views

    private func authorProfileImageView(_ profileImage: String?, authorName: String, size: CGFloat) -> some View {
        Group {
            if let profileImage = profileImage,
               let imageURL = profileImage.thumbnailURL {
                CachedAsyncImage(
                    url: imageURL,
                    targetSize: CGSize(width: size, height: size),
                    cachingKit: cachingKit
                ) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray30)
                        .frame(width: size, height: size)
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                }
            } else {
                Circle()
                    .fill(Color.gray30)
                    .frame(width: size, height: size)
                    .overlay {
                        Text(String(authorName.prefix(1)))
                            .font(.caption1(.pretendardBold))
                            .foregroundStyle(Color.gray75)
                    }
            }
        }
    }

    private func postFileImageView(_ fileUrl: String) -> some View {
        Group {
            if let imageURL = fileUrl.thumbnailURL {
                CachedAsyncImage(
                    url: imageURL,
                    targetSize: CGSize(width: UIScreen.main.bounds.width - 40, height: 400),
                    cachingKit: cachingKit
                ) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray30)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            ProgressView()
                        }
                }
            } else {
                Rectangle()
                    .fill(Color.gray30)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.gray60)
                    }
            }
        }
    }

    private func commentInputView() -> some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray30)

            // 답글 대상 표시
            if let replyToNick = viewModel.replyToNick {
                HStack {
                    Text("@\(replyToNick)")
                        .font(.caption1(.pretendardBold))
                        .foregroundStyle(Color.gray75)

                    Spacer()

                    Button(action: {
                        viewModel.cancelReply()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.gray60)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray15)
            }

            HStack(spacing: 12) {
                TextField("댓글을 입력하세요", text: $viewModel.commentText, axis: .vertical)
                    .font(.body2(.pretendardRegular))
                    .foregroundStyle(Color.gray90)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray15)
                    .cornerRadius(20)
                    .lineLimit(1...5)

                Button(action: {
                    Task {
                        await viewModel.createComment()
                    }
                }) {
                    if viewModel.isCommentLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 40, height: 40)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.gray45
                                : Color.deepCream
                            )
                    }
                }
                .disabled(
                    viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || viewModel.isCommentLoading
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray0)
        }
    }
}

#Preview {
    NavigationView {
        PostDetailView(postId: "670bcd66539a670e42b2a3d8")
    }
}
