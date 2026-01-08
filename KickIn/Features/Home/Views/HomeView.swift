//
//  HomeView.swift
//  KickIn
//
//  Created by 서준일 on 12/18/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.screenSize) private var screenSize
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // 상단 이미지 컴포넌트 (3:2 비율)
                TodayEstatesTopImageView(
                    estates: viewModel.todayEstates
                )

                // 아이콘 버튼 그룹
                CategoryButtonRow()

                // 최근 검색 매물 섹션
                RecentEstateSection()
                
                // 매물 홍보 영상 섹션
                VideoPromoSection(
                    videos: viewModel.promoVideos
                )

                // HOT 매물 섹션
                HotEstateSection(
                    estates: viewModel.hotEstates
                )

                // 오늘의 Topic
                TopicSection(
                    topics: viewModel.todayTopics,
                    banners: viewModel.banners
                )
            }
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .defaultBackground()
        .task {
            await viewModel.loadData()
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(\.screenSize, ScreenSize(width: 390, height: 844, safeAreaTop: 47, safeAreaBottom: 34))
    }
}
