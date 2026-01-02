//
//  EstatePostView.swift
//  KickIn
//
//  Created by 서준일 on 01/02/26.
//

import SwiftUI

struct EstatePostView: View {
    @StateObject private var viewModel: EstatePostViewModel

    init(estateId: String) {
        _viewModel = StateObject(wrappedValue: EstatePostViewModel(estateId: estateId))
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    loadingView()
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else if viewModel.posts.isEmpty {
                    emptyView()
                } else {
                    postsListView()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .defaultBackground()
        .navigationTitle("게시판")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPosts()
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

    private func emptyView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundStyle(Color.gray60)

            Text("아직 작성된 게시글이 없습니다")
                .font(.body2(.pretendardRegular))
                .foregroundStyle(Color.gray60)

            Text("첫 번째 게시글을 작성해보세요!")
                .font(.caption1(.pretendardRegular))
                .foregroundStyle(Color.gray45)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    private func postsListView() -> some View {
        VStack(spacing: 0) {
            ForEach(viewModel.posts) { post in
                NavigationLink(destination: PostDetailView(postId: post.id)) {
                    EstatePostCardView(post: post)
                }
                .buttonStyle(PlainButtonStyle())
                .task {
                    await viewModel.loadMoreIfNeeded(currentItem: post)
                }

                Divider()
                    .background(Color.gray30)
                    .padding(.horizontal, 20)
            }

            // 로딩 인디케이터 (페이지네이션 로딩 중)
            if viewModel.isLoading && !viewModel.posts.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 20)
                    Spacer()
                }
            }
        }
        .padding(.top, 16)
    }
}

#Preview {
    NavigationView {
        EstatePostView(estateId: "693a07fccd1a3725c019c953")
    }
}
