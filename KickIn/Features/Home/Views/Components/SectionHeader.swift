//
//  SectionHeader.swift
//  KickIn
//
//  Created by 서준일 on 12/19/25.
//

import SwiftUI

struct SectionHeader: View {
    
    let title: String
    var visibleViewAll: Bool = true
    let action: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.body2(.pretendardBold))
                .foregroundColor(.gray90)

            Spacer()

            if visibleViewAll {
                Button(action: action) {
                    Text("View All")
                        .font(.caption1(.pretendardMedium))
                        .foregroundColor(.deepCoast)
                }
            } else {
                
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    SectionHeader(title: "최근검색 매물") {
        print("View All tapped")
    }
}
