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

    init(postId: String) {
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(postId: postId))
    }

    var body: some View {
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
        .defaultBackground()
        .navigationTitle("게시글 상세")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPostDetail()
        }
    }

    // MARK: - Subviews

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
                authorProfileImageView(post.authorProfileImage, authorName: post.authorName, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.body2(.pretendardBold))
                        .foregroundStyle(Color.gray90)

                    Text(post.createdAt)
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
            Text("댓글 \(post.comments.count)개")
                .font(.body2(.pretendardBold))
                .foregroundStyle(Color.gray90)
                .padding(.top, 8)

            // 댓글 목록
            ForEach(post.comments) { comment in
                commentView(comment: comment)
            }
        }
        .padding(20)
    }

    private func commentView(comment: PostCommentUIModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                authorProfileImageView(comment.authorProfileImage, authorName: comment.authorName, size: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.authorName)
                        .font(.caption1(.pretendardBold))
                        .foregroundStyle(Color.gray90)

                    Text(comment.createdAt)
                        .font(.caption2(.pretendardRegular))
                        .foregroundStyle(Color.gray60)
                }
            }

            Text(comment.content)
                .font(.body2(.pretendardRegular))
                .foregroundStyle(Color.gray90)
                .padding(.leading, 40)

            // 대댓글들
            ForEach(comment.replies) { reply in
                replyView(reply: reply)
                    .padding(.leading, 40)
            }
        }
    }

    private func replyView(reply: PostCommentReplyUIModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                authorProfileImageView(reply.authorProfileImage, authorName: reply.authorName, size: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(reply.authorName)
                        .font(.caption1(.pretendardBold))
                        .foregroundStyle(Color.gray90)

                    Text(reply.createdAt)
                        .font(.caption2(.pretendardRegular))
                        .foregroundStyle(Color.gray60)
                }
            }

            Text(reply.content)
                .font(.body2(.pretendardRegular))
                .foregroundStyle(Color.gray90)
                .padding(.leading, 36)
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
}

#Preview {
    NavigationView {
        PostDetailView(postId: "670bcd66539a670e42b2a3d8")
    }
}
