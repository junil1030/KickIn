//
//  LinkPreviewCard.swift
//  KickIn
//
//  Created by 서준일 on 01/22/26.
//

import SwiftUI
import CachingKit

/// 링크 프리뷰 카드
struct LinkPreviewCard: View {
    @Environment(\.cachingKit) private var cachingKit

    let metadata: LinkMetadata
    let isSentByMe: Bool
    let hasTextAbove: Bool

    // 채팅 버블의 최대 너비
    private var maxWidth: CGFloat {
        UIScreen.main.bounds.width * 0.70
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 오픈 그래프 이미지
            if let imageURLString = metadata.imageURL,
               let imageURL = URL(string: imageURLString.hasPrefix("http") ? imageURLString : "https:\(imageURLString)") {
                CachedAsyncImage(
                    url: imageURL,
                    targetSize: CGSize(width: maxWidth, height: 180),
                    cachingKit: cachingKit
                ) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray30)
                        .frame(height: 180)
                        .overlay {
                            ProgressView()
                        }
                }
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: hasTextAbove ? 0 : 12,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: hasTextAbove ? 0 : 12
                    )
                )

                // 이미지와 텍스트 사이 구분선
                Divider()
                    .background(Color.gray30.opacity(0.5))
            }

            // 텍스트 정보 영역
            VStack(alignment: .leading, spacing: 4) {
                // 사이트명
                if let siteName = metadata.siteName {
                    Text(siteName)
                        .font(.caption2(.pretendardMedium))
                        .foregroundColor(.gray60)
                        .lineLimit(1)
                }

                // 제목
                if let title = metadata.title {
                    Text(title)
                        .font(.body2(.pretendardBold))
                        .foregroundColor(.gray90)
                        .lineLimit(1)
                }

                // 설명
                if let description = metadata.description {
                    Text(description)
                        .font(.caption1(.pretendardRegular))
                        .foregroundColor(.gray75)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .padding(.top, metadata.imageURL != nil ? 12 : 0)
            .frame(maxWidth: maxWidth, alignment: .leading)
            .background(isSentByMe ? Color.deepCream : Color.white.opacity(0.95))
        }
        .background(isSentByMe ? Color.deepCream : Color.white.opacity(0.95))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: hasTextAbove ? 0 : 12,
                bottomLeadingRadius: 12,
                bottomTrailingRadius: 12,
                topTrailingRadius: hasTextAbove ? 0 : 12
            )
        )
        .frame(maxWidth: maxWidth, alignment: .leading)
    }
}
