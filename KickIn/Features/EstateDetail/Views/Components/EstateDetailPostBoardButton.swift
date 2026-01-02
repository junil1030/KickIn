//
//  EstateDetailPostBoardButton.swift
//  KickIn
//
//  Created by 서준일 on 01/02/26.
//

import SwiftUI

struct EstateDetailPostBoardButton: View {
    let estateId: String

    var body: some View {
        NavigationLink(destination: EstatePostView(estateId: estateId)) {
            HStack(spacing: 12) {
                // Left: Post icon
                Image("Icon/Post")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Color.gray75)

                // Center: Text
                Text("이 매물에 대한 사람들의 의견을 들어보세요")
                    .font(.body1(.pretendardBold))
                    .foregroundStyle(Color.gray90)

                Spacer()

                // Right: Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.gray75)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 25)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray30)
                .padding(.horizontal, 20)

            EstateDetailPostBoardButton(estateId: "693a07fccd1a3725c019c953")

            Divider()
                .background(Color.gray30)
                .padding(.horizontal, 20)
        }
        .background(Color.gray15)
    }
}
