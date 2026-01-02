//
//  FilterButton.swift
//  KickIn
//
//  Created by 서준일 on 12/30/25.
//

import SwiftUI

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .brightWood : .gray75)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .background(Color.gray0)
        .overlay(
            Capsule()
                .stroke(isSelected ? Color.brightWood : Color.gray45, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

#Preview {
    HStack(spacing: 4) {
        FilterButton(title: "면적 순", isSelected: false) {}
        FilterButton(title: "월세 순", isSelected: true) {}
    }
    .padding()
}
