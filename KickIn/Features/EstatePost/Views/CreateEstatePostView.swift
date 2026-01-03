//
//  CreateEstatePostView.swift
//  KickIn
//
//  Created by 서준일 on 01/03/26.
//

import SwiftUI
import PhotosUI

struct CreateEstatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var title: String = ""
    @State private var content: String = ""

    private let maxImages = 5

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PhotoSelectionView(
                        selectedItems: $selectedItems,
                        selectedImages: $selectedImages,
                        maxImages: maxImages
                    )
                    .padding(.top, 10)

                    PostInputFieldsView(
                        title: $title,
                        content: $content
                    )
                    .padding(.top, 24)
                }
                .padding(.bottom, 100) // 하단 버튼 공간 확보
            }

            VStack {
                Spacer()

                Button {
                    // TODO: 작성 완료 기능 구현
                } label: {
                    Text("작성 완료")
                        .font(.title1(.pretendardBold))
                        .foregroundStyle(Color.gray0)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.deepCream)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(
                    Color.gray0
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .defaultBackground()
        .navigationTitle("게시글 작성")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    NavigationView {
        CreateEstatePostView()
    }
}
