//
//  HotEstateSection.swift
//  KickIn
//
//  Created by 서준일 on 12/19/25.
//

import SwiftUI

struct HotEstateSection: View {
    @Environment(\.cachingKit) private var cachingKit

    let estates: [HotEstateUIModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 섹션 헤더
            SectionHeader(title: "HOT 매물") {
                print("HOT 매물 View All tapped")
            }

            // 매물 리스트 (가로 스크롤)
            if estates.isEmpty {
                emptyView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(estates.indices, id: \.self) { index in
                            let estate = estates[index]
                            if let estateId = estate.estateId {
                                NavigationLink(destination: EstateDetailView(estateId: estateId)) {
                                    HotEstateCell(
                                        data: estate,
                                        cachingKit: cachingKit
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                HotEstateCell(
                                    data: estate,
                                    cachingKit: cachingKit
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Private Views

    private var emptyView: some View {
        Text("HOT 매물이 없습니다.")
            .font(.body2())
            .foregroundStyle(Color.gray60)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }
}

#Preview {
    HotEstateSection(
        estates: []
    )
    .defaultBackground()
}
