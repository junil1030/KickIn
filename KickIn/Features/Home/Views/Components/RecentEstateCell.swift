//
//  RecentEstateCell.swift
//  KickIn
//
//  Created by 서준일 on 12/19/25.
//

import SwiftUI

struct RecentEstateCell: View {
    let imageName: String
    let category: String
    let price: String
    let dong: String
    let area: String

    var body: some View {
        HStack(spacing: 12) {
            // 왼쪽: 이미지
            Rectangle()
                .fill(Color.gray45)
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundColor(.gray60)
                }

            // 오른쪽: 정보
            VStack(alignment: .leading, spacing: 6) {
                // 카테고리
                Text(category)
                    .font(.caption2(.pretendardMedium))
                    .foregroundColor(.deepWood)

                // 가격
                Text(price)
                    .font(.body3(.pretendardBold))
                    .foregroundColor(.gray90)

                // 동, 평수
                HStack(spacing: 8) {
                    Text(dong)
                        .font(.caption1())
                        .foregroundColor(.gray60)

                    Text("·")
                        .foregroundColor(.gray60)

                    Text(area)
                        .font(.caption1())
                        .foregroundColor(.gray60)
                }
            }

            Spacer()
        }
        .padding(12)
        .frame(width: 280)
        .background(Color.gray0)
        .cornerRadius(12)
    }
}

#Preview {
    RecentEstateCell(
        imageName: "placeholder",
        category: "원룸",
        price: "월세 500/50",
        dong: "역삼동",
        area: "20평"
    )
}
