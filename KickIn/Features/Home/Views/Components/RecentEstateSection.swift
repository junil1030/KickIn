//
//  RecentEstateSection.swift
//  KickIn
//
//  Created by 서준일 on 12/19/25.
//

import SwiftUI

struct RecentEstateSection: View {
    @Environment(\.cachingKit) private var cachingKit
    let estates: [RecentEstateUIModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 섹션 헤더
            SectionHeader(title: "최근검색 매물") {
                print("최근검색 매물 View All tapped")
            }

            if estates.isEmpty {
                emptyView
            } else {
                // 매물 리스트 (가로 스크롤)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(estates) { estate in
                            NavigationLink(destination: EstateDetailView(estateId: estate.estateId)) {
                                RecentEstateCell(data: estate, cachingKit: cachingKit)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var emptyView: some View {
        Text("최근 본 매물이 없습니다.")
            .font(.body2())
            .foregroundStyle(Color.gray60)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }
}
