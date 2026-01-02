//
//  SortButton.swift
//  KickIn
//
//  Created by 서준일 on 12/30/25.
//

import SwiftUI

struct SortButton: View {
    let isDescending: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("Icon/Sort")
                .resizable()
                .renderingMode(.template)
                .frame(width: 24, height: 24)
                .foregroundColor(isDescending ? .gray75 : .gray45)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        SortButton(isDescending: false) {}
        SortButton(isDescending: true) {}
    }
    .padding()
}
