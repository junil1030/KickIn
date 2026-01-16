//
//  ClusterEstateListView.swift
//  KickIn
//
//  Created by 서준일 on 01/16/26.
//

import SwiftUI

struct ClusterEstateListView: View {
    let estates: [InterestUIModel]

    var body: some View {
        VStack(spacing: 0) {
            // 매물 리스트
            if estates.isEmpty {
                // Empty State
                VStack {
                    Spacer()
                    Text("매물이 없습니다")
                        .font(.body1(.pretendardBold))
                        .foregroundColor(.gray90)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(estates) { estate in
                            NavigationLink(destination: EstateDetailView(estateId: estate.id)) {
                                InterestEstateCell(estate: estate)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle("지역목록 \(estates.count)개")
        .navigationBarTitleDisplayMode(.inline)
        .defaultBackground()
    }
}
