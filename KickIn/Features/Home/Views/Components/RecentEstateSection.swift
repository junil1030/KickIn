//
//  RecentEstateSection.swift
//  KickIn
//
//  Created by 서준일 on 12/19/25.
//

import SwiftUI

struct RecentEstateSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 섹션 헤더
            SectionHeader(title: "최근검색 매물") {
                print("최근검색 매물 View All tapped")
            }

            // 매물 리스트 (가로 스크롤)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    RecentEstateCell(
                        imageName: "placeholder",
                        category: "원룸",
                        price: "월세 500/50",
                        dong: "역삼동",
                        area: "20평"
                    )

                    RecentEstateCell(
                        imageName: "placeholder",
                        category: "오피스텔",
                        price: "전세 1억",
                        dong: "강남역",
                        area: "15평"
                    )

                    RecentEstateCell(
                        imageName: "placeholder",
                        category: "아파트",
                        price: "매매 5억",
                        dong: "삼성동",
                        area: "30평"
                    )
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    RecentEstateSection()
}
