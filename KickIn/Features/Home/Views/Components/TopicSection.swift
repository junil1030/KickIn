//
//  TopicSection.swift
//  KickIn
//
//  Created by 서준일 on 12/22/25.
//

import SwiftUI
import OSLog

struct TopicSection: View {

    let topics: [TopicUIModel]
    let banners: [BannerUIModel]
    @State private var selectedURL: URL?
    @State private var showSafari = false
    @State private var selectedBanner: BannerUIModel?

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "오늘의 부동산 TOPIC", visibleViewAll: false) {

            }

            LazyVStack(spacing: 0) {
                ForEach(Array(topics.enumerated()), id: \.offset) { index, topic in
                    TopicCell(topic: topic) {
                        if let link = topic.link, let url = URL(string: link) {
                            selectedURL = url
                            showSafari = true
                        }
                    }
                    .background(Color.gray0)

                    Divider()

                    if (index + 1) % 3 == 0 && index + 1 < topics.count {
                        let bannerIndex = (index + 1) / 3 - 1
                        let banner = banners.indices.contains(bannerIndex) ? banners[bannerIndex] : nil

                        AdCell(imageURL: banner?.imageUrl?.thumbnailURL) {
                            if let banner, banner.webViewURL != nil {
                                selectedBanner = banner
                            }
                        }
                        .background(Color.gray0)

                        Divider()
                    }
                }
            }
        }
        .sheet(isPresented: $showSafari) {
            if let url = selectedURL {
                SafariView(url: url)
            }
        }
        .sheet(item: $selectedBanner) { banner in
            if let url = banner.webViewURL {
                BannerWebView(url: url) { count in
                    Logger.network.info("출석체크 횟수: \(count ?? 0)")
                }
            }
        }
    }
}

#Preview {
    TopicSection(
        topics: [
        TopicUIModel(
            title: "부동산 시장 동향",
            content: "2024년 주요 지역 부동산 시장 분석",
            date: "2024.12.22",
            link: "https://example.com"
        ),
        TopicUIModel(
            title: "전세 시장 변화",
            content: "전세 가격 상승 추세 분석",
            date: "2024.12.21",
            link: "https://example.com"
        ),
        TopicUIModel(
            title: "매매 시장 전망",
            content: "2025년 매매 시장 예측",
            date: "2024.12.20",
            link: "https://example.com"
        ),
        TopicUIModel(
            title: "투자 전략",
            content: "부동산 투자 시 고려사항",
            date: "2024.12.19",
            link: "https://example.com"
        )
    ],
        banners: []
    )
}
