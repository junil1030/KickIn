//
//  PostDetailView.swift
//  KickIn
//
//  Created by 서준일 on 01/02/26.
//

import SwiftUI

struct PostDetailView: View {
    let postId: String

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                Text("Post ID: \(postId)")
                    .font(.body1(.pretendardBold))
                    .foregroundStyle(Color.gray90)
                    .padding()
            }
            .frame(maxWidth: .infinity)
        }
        .defaultBackground()
        .navigationTitle("게시글 상세")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        PostDetailView(postId: "670bcd66539a670e42b2a3d8")
    }
}
