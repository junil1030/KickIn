//  UserPostCardView.swift
//  KickIn
//  Created by 서준일 on 01/22/26

import SwiftUI

struct UserPostCardView: View {
    let post: UserPostUIModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 제목 (최대 2줄)
            Text(post.title)
                .font(.body1(.pretendardBold))
                .foregroundColor(.gray90)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // 내용 미리보기 (최대 3줄)
            Text(post.content)
                .font(.body2(.pretendardRegular))
                .foregroundColor(.gray60)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            // 하단 정보: 좋아요 수 + 작성일
            HStack(spacing: 8) {
                // 좋아요 수
                HStack(spacing: 4) {
                    Image(systemName: post.isLike ? "heart.fill" : "heart")
                        .font(.caption)
                        .foregroundColor(post.isLike ? .red : .gray60)

                    Text("\(post.likeCount)")
                        .font(.caption2(.pretendardMedium))
                        .foregroundColor(.gray60)
                }

                // 구분점
                Text("•")
                    .font(.caption2(.pretendardMedium))
                    .foregroundColor(.gray45)

                // 작성일
                Text(post.createdAt.timeAgoFromNow ?? post.createdAt)
                    .font(.caption2(.pretendardMedium))
                    .foregroundColor(.gray45)

                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
    }
}
