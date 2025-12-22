//
//  CategoryButton.swift
//  KickIn
//
//  Created by 서준일 on 12/19/25.
//

import SwiftUI

struct CategoryButton: View {
    let imageName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray30)
                        .frame(width: 40, height: 40)

                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                }

                Text(title)
                    .font(.body3())
                    .foregroundColor(.gray75)
            }
        }
    }
}

#Preview {
    CategoryButton(imageName: "Icon/Fire", title: "인기매물") {
        print("Button tapped")
    }
}
