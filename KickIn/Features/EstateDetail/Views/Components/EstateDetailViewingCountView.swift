//
//  EstateDetailViewingCountView.swift
//  KickIn
//
//  Created by 서준일 on 12/26/25.
//

import SwiftUI

struct EstateDetailViewingCountView: View {
    let likeCount: Int?

    var body: some View {
        Text("\(likeCount ?? 0)명이 함께 보는 중")
            .font(.body3(.pretendardMedium))
            .foregroundStyle(Color.gray60)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .background(Color.gray45)
    }
}

#Preview {
    VStack(spacing: 0) {
        EstateDetailViewingCountView(likeCount: 15)
        EstateDetailViewingCountView(likeCount: 0)
        EstateDetailViewingCountView(likeCount: nil)
    }
    .background(Color.gray15)
}
