//
//  VideoPromoSection.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import SwiftUI

struct VideoPromoSection: View {
    @Environment(\.cachingKit) private var cachingKit

    let videos: [VideoUIModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "매물 홍보 영상", visibleViewAll: false) {
                print("매물 홍보 영상 View All tapped")
            }

            if videos.isEmpty {
                emptyView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(videos.indices, id: \.self) { index in
                            let video = videos[index]
                            if video.videoId != nil {
                                NavigationLink(destination: VideoDetailView(video: video)) {
                                    VideoPromoCell(video: video, cachingKit: cachingKit)
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                VideoPromoCell(video: video, cachingKit: cachingKit)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var emptyView: some View {
        Text("홍보 영상이 없습니다.")
            .font(.body2())
            .foregroundStyle(Color.gray60)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }
}

#Preview {
    VideoPromoSection(videos: [])
        .defaultBackground()
}
