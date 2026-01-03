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
    @StateObject private var viewModel: CreateEstatePostViewModel
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var title: String = ""
    @State private var content: String = ""

    private let maxImages = 5

    init(estateId: String) {
        _viewModel = StateObject(wrappedValue: CreateEstatePostViewModel(estateId: estateId))
    }

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

                // 에러 메시지 표시
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption1(.pretendardMedium))
                        .foregroundStyle(Color.red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                Button {
                    Task {
                        await viewModel.submitPost(
                            title: title,
                            content: content,
                            images: selectedImages
                        )
                    }
                } label: {
                    HStack {
                        if viewModel.isUploading {
                            ProgressView()
                                .tint(Color.gray0)
                        }
                        Text(viewModel.isUploading ? "업로드 중..." : "작성 완료")
                            .font(.title1(.pretendardBold))
                            .foregroundStyle(Color.gray0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.deepCream)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(viewModel.isUploading || title.isEmpty || content.isEmpty)
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
        .onChange(of: viewModel.showSuccessAlert) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationView {
        CreateEstatePostView(estateId: "693a07fccd1a3725c019c953")
    }
}
