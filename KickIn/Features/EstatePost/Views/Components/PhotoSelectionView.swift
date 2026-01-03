//
//  PhotoSelectionView.swift
//  KickIn
//
//  Created by 서준일 on 01/03/26.
//

import SwiftUI
import PhotosUI

struct PhotoSelectionView: View {
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var selectedImages: [UIImage]

    let maxImages: Int

    private var selectedImageCount: Int {
        selectedImages.count
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                cameraButton()

                selectedImagesList()
            }
            .padding(.horizontal, 20)
        }
        .onChange(of: selectedItems) { oldValue, newValue in
            Task {
                await loadImages()
            }
        }
    }

    // MARK: - Subviews

    private func cameraButton() -> some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: maxImages,
            matching: .images
        ) {
            VStack(spacing: 3) {
                Image("Icon/Camera")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(Color.gray75)

                HStack(spacing: 0) {
                    Text("\(selectedImageCount)")
                        .foregroundStyle(selectedImageCount == 0 ? Color.gray75 : Color.deepCream)
                    Text("/\(maxImages)")
                        .foregroundStyle(Color.gray75)
                }
                .font(.caption1(.pretendardMedium))
            }
            .frame(width: 65, height: 65)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray75, lineWidth: 1)
            )
        }
    }

    private func selectedImagesList() -> some View {
        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 65, height: 65)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                deleteButton(at: index)
            }
        }
    }

    private func deleteButton(at index: Int) -> some View {
        Button {
            removeImage(at: index)
        } label: {
            Image("Icon/Cross")
                .renderingMode(.template)
                .resizable()
                .frame(width: 8, height: 8)
                .foregroundStyle(Color.gray75)
                .padding(4)
                .background(Color.gray0)
                .clipShape(Circle())
        }
        .offset(x: 5, y: -5)
    }

    // MARK: - Methods

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

#Preview {
    @Previewable @State var selectedItems: [PhotosPickerItem] = []
    @Previewable @State var selectedImages: [UIImage] = []

    PhotoSelectionView(
        selectedItems: $selectedItems,
        selectedImages: $selectedImages,
        maxImages: 5
    )
    .defaultBackground()
}
