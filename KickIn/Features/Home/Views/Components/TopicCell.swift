//
//  TopicCell.swift
//  KickIn
//
//  Created by 서준일 on 12/22/25.
//

import SwiftUI

struct TopicCell: View {
    let topic: TopicUIModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if let title = topic.title {
                        Text(title)
                            .font(.body2(.pretendardBold))
                            .foregroundStyle(Color.gray90)
                    }

                    if let content = topic.content {
                        Text(content)
                            .font(.body2())
                            .foregroundStyle(Color.gray60)
                    }
                }

                Spacer()

                if let date = topic.date {
                    Text(date)
                        .font(.body2())
                        .foregroundStyle(Color.gray75)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TopicCell(
        topic: TopicUIModel(
            title: "부동산 시장 동향",
            content: "2024년 주요 지역 부동산 시장 분석",
            date: "2024.12.22",
            link: "https://example.com"
        ),
        onTap: {}
    )
}
