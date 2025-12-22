//
//  CategoryButtonRow.swift
//  KickIn
//
//  Created by 서준일 on 12/19/25.
//

import SwiftUI

struct CategoryButtonRow: View {
    var body: some View {
        HStack(spacing: 0) {
            CategoryButton(imageName: "Category/OneRoom", title: "원룸") {
                print("원룸 tapped")
            }
            .frame(maxWidth: .infinity)

            CategoryButton(imageName: "Category/Officetel", title: "오피스텔") {
                print("오피스텔 tapped")
            }
            .frame(maxWidth: .infinity)

            CategoryButton(imageName: "Category/Apartment", title: "아파트") {
                print("아파트 tapped")
            }
            .frame(maxWidth: .infinity)

            CategoryButton(imageName: "Category/Villa", title: "빌라") {
                print("빌라 tapped")
            }
            .frame(maxWidth: .infinity)

            CategoryButton(imageName: "Category/Storefront", title: "상가") {
                print("상가 tapped")
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
    }
}

#Preview {
    CategoryButtonRow()
}
