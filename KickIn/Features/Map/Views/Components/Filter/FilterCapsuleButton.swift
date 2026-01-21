//
//  FilterCapsuleButton.swift
//  KickIn
//
//  Created by 서준일 on 01/20/26.
//

import SwiftUI

struct FilterCapsuleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body2(.pretendardMedium))
                .foregroundColor(isSelected ? .brightWood : .gray75)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.brightWood.opacity(0.1) : Color.gray0)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.brightWood : Color.gray45, lineWidth: 1)
                )
                .cornerRadius(20)
        }
    }
}
