//
//  ChatInputBar.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import SwiftUI
import PhotosUI

struct ChatInputBar: View {
    @Binding var messageText: String
    @Binding var selectedImages: [UIImage]

    let onSend: () -> Void

    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(spacing: 0) {
            // 선택된 이미지 미리보기
            if !selectedImages.isEmpty {
                imagePreviewSection
                Divider()
            }

            // 입력창
            HStack(spacing: 12) {
                // 이미지 첨부 버튼
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(.gray75)
                }
                .onChange(of: selectedItems) { _, _ in
                    Task {
                        await loadImages()
                    }
                }

                // 텍스트 입력
                TextField("메시지를 입력하세요", text: $messageText, axis: .vertical)
                    .font(.body2(.pretendardMedium))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.gray30)
                    .cornerRadius(20)
                    .lineLimit(1...5)

                // 전송 버튼
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(canSend ? .deepCream : .gray60)
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.white)
    }

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty
    }

    private var imagePreviewSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button {
                            removeImage(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray90)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .offset(x: 5, y: -5)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func loadImages() async {
        selectedImages.removeAll()

        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImages.append(image)
            }
        }
    }

    private func removeImage(at index: Int) {
        selectedImages.remove(at: index)
        selectedItems.remove(at: index)
    }
}
