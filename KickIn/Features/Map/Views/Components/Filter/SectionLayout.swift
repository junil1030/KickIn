//
//  SectionLayout.swift
//  KickIn
//
//  Created by 서준일 on 01/20/26.
//

import SwiftUI

struct SectionLayout<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body1(.pretendardBold))
                    .foregroundColor(.gray90)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption1(.pretendardMedium))
                        .foregroundColor(.gray60)
                }
            }

            content()
        }
        .padding(.vertical, 12)
    }
}
