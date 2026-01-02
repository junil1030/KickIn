//
//  EstatePostCardView.swift
//  KickIn
//
//  Created by 서준일 on 01/02/26.
//

import SwiftUI
import CachingKit

struct EstatePostCardView: View {
    @Environment(\.cachingKit) private var cachingKit

    let post: EstatePostUIModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Author and Date
            HStack(spacing: 8) {
                // Author avatar
                profileImageView(post.authorProfileImage)

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.body2(.pretendardBold))
                        .foregroundStyle(Color.gray90)

                    Text(post.createdAt.timeAgoFromNow ?? "")
                        .font(.caption2(.pretendardRegular))
                        .foregroundStyle(Color.gray60)
                }

                Spacer()
            }

            // Title (최대 1줄)
            Text(post.title)
                .font(.body1(.pretendardBold))
                .foregroundStyle(Color.gray75)
                .lineLimit(1)

            // Content (최대 3줄)
            Text(post.content)
                .font(.body2(.pretendardRegular))
                .foregroundStyle(Color.gray75)
                .lineSpacing(4)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            // Footer: Like and Comment counts
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.deepCream)

                    Text("\(post.likeCount)")
                        .font(.caption1(.pretendardMedium))
                        .foregroundStyle(Color.gray60)
                }

                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.gray60)

                    Text("000")
                        .font(.caption1(.pretendardMedium))
                        .foregroundStyle(Color.gray60)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Subviews
private extension EstatePostCardView {
    func profileImageView(_ profileImage: String?) -> some View {
        Group {
            if let profileImage = profileImage,
               let imageURL = profileImage.thumbnailURL {
                CachedAsyncImage(
                    url: imageURL,
                    targetSize: CGSize(width: 32, height: 32),
                    cachingKit: cachingKit
                ) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray30)
                        .frame(width: 32, height: 32)
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                }
            } else {
                Circle()
                    .fill(Color.gray30)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(String(post.authorName.prefix(1)))
                            .font(.caption1(.pretendardBold))
                            .foregroundStyle(Color.gray75)
                    }
            }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        EstatePostCardView(
            post: EstatePostUIModel(
                id: "1",
                title: "안녕하세요 ! 새싹동에서 러닝하러 갈 사람 구해요",
                authorName: "김철수",
                authorProfileImage: nil,
                content: "이 매물 실제로 보고 왔는데 사진보다 훨씬 좋네요! 채광도 좋고 주변 환경도 깔끔합니다.",
                likeCount: 12,
                createdAt: "2024-07-21T14:00:00.000Z"
            )
        )

        Divider()
            .background(Color.gray30)
            .padding(.horizontal, 20)

        EstatePostCardView(
            post: EstatePostUIModel(
                id: "2",
                title: "주차 공간 문의드립니다",
                authorName: "이영희",
                authorProfileImage: nil,
                content: "주차 공간이 넉넉한지 궁금합니다.",
                likeCount: 5,
                createdAt: "2024-07-21T12:00:00.000Z"
            )
        )
    }
    .background(Color.gray15)
}
