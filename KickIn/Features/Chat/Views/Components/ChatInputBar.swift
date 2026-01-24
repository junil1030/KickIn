//
//  ChatInputBar.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct ChatInputBar: View {
    @Binding var messageText: String
    @Binding var selectedImages: [UIImage]
    @Binding var selectedVideoURLs: [URL]
    @Binding var selectedPDFURLs: [URL]
    @FocusState.Binding var isInputFocused: Bool

    let onSend: () -> Void

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showAttachmentMenu = false

    var body: some View {
        VStack(spacing: 0) {
            // 선택된 미디어 미리보기
            if !selectedImages.isEmpty || !selectedVideoURLs.isEmpty || !selectedPDFURLs.isEmpty {
                mediaPreviewSection
                Divider()
            }

            // 첨부 메뉴
            if showAttachmentMenu {
                AttachmentMenuView(
                    isPresented: $showAttachmentMenu,
                    selectedPDFURLs: $selectedPDFURLs,
                    remainingSlots: max(0, 5 - totalMediaCount),
                    onPhotosSelected: { items in
                        selectedItems = items
                        Task {
                            await loadMediaItems()
                        }
                    },
                    onVideosSelected: { items in
                        selectedItems = items
                        Task {
                            await loadMediaItems()
                        }
                    },
                    onDismiss: {
                        isInputFocused = false
                    }
                )
                .transition(.move(edge: .bottom))
            }

            // 입력창
            HStack(spacing: 12) {
                // + 버튼 (첨부 메뉴)
                Button {
                    isInputFocused = false
                    withAnimation {
                        showAttachmentMenu.toggle()
                    }
                } label: {
                    Image(systemName: showAttachmentMenu ? "xmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray75)
                }

                // 텍스트 입력
                TextField("메시지를 입력하세요", text: $messageText, axis: .vertical)
                    .font(.body2(.pretendardMedium))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.gray30)
                    .cornerRadius(20)
                    .lineLimit(1...5)
                    .focused($isInputFocused)

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
        .onChange(of: selectedImages) { _, newValue in
            // 외부에서 selectedImages가 비워지면 selectedItems도 초기화
            if newValue.isEmpty && selectedVideoURLs.isEmpty && !selectedItems.isEmpty {
                selectedItems.removeAll()
            }
        }
        .onChange(of: selectedVideoURLs) { _, newValue in
            // 외부에서 selectedVideoURLs가 비워지면 selectedItems도 초기화
            if newValue.isEmpty && selectedImages.isEmpty && !selectedItems.isEmpty {
                selectedItems.removeAll()
            }
        }
        .onChange(of: selectedPDFURLs) { _, newValue in
            // PDF가 비워지면 첨부 메뉴 닫기
            if newValue.isEmpty && selectedImages.isEmpty && selectedVideoURLs.isEmpty {
                showAttachmentMenu = false
            }
        }
    }

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty || !selectedVideoURLs.isEmpty || !selectedPDFURLs.isEmpty
    }

    private var totalMediaCount: Int {
        selectedImages.count + selectedVideoURLs.count + selectedPDFURLs.count
    }

    private var mediaPreviewSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 이미지 미리보기
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

                // 비디오 미리보기
                ForEach(Array(selectedVideoURLs.enumerated()), id: \.offset) { index, videoURL in
                    ZStack(alignment: .topTrailing) {
                        // 비디오 썸네일
                        VideoThumbnailView(url: videoURL)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                // Play 아이콘
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 2)
                            }

                        // 삭제 버튼
                        Button {
                            removeVideo(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray90)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .offset(x: 5, y: -5)
                    }
                }

                // PDF 미리보기
                ForEach(Array(selectedPDFURLs.enumerated()), id: \.offset) { index, pdfURL in
                    ZStack(alignment: .topTrailing) {
                        // PDF 아이콘
                        VStack(spacing: 4) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                            Text(pdfURL.lastPathComponent)
                                .font(.caption2)
                                .lineLimit(1)
                                .frame(maxWidth: 50)
                        }
                        .frame(width: 60, height: 60)
                        .background(Color.gray30)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // 삭제 버튼
                        Button {
                            removePDF(at: index)
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

    private func loadMediaItems() async {
        selectedImages.removeAll()
        selectedVideoURLs.removeAll()

        for item in selectedItems {
            // 이미지 처리
            if item.supportedContentTypes.contains(.image) {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImages.append(image)
                }
            }
            // 비디오 처리
            else if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
                if let movie = try? await item.loadTransferable(type: Movie.self) {
                    selectedVideoURLs.append(movie.url)
                }
            }
        }
    }

    private func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)

        // selectedItems에서도 해당 이미지 항목 찾아서 삭제
        var itemIndex = 0
        for (i, item) in selectedItems.enumerated() {
            if item.supportedContentTypes.contains(.image) {
                if itemIndex == index {
                    selectedItems.remove(at: i)
                    return
                }
                itemIndex += 1
            }
        }
    }

    private func removeVideo(at index: Int) {
        guard index < selectedVideoURLs.count else { return }
        selectedVideoURLs.remove(at: index)

        // selectedItems에서도 해당 비디오 항목 찾아서 삭제
        var itemIndex = 0
        for (i, item) in selectedItems.enumerated() {
            if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
                if itemIndex == index {
                    selectedItems.remove(at: i)
                    return
                }
                itemIndex += 1
            }
        }
    }

    private func removePDF(at index: Int) {
        guard index < selectedPDFURLs.count else { return }
        let pdfURL = selectedPDFURLs[index]

        // 임시 디렉토리의 파일인 경우 삭제
        if pdfURL.path.contains(FileManager.default.temporaryDirectory.path) {
            try? FileManager.default.removeItem(at: pdfURL)
        }

        selectedPDFURLs.remove(at: index)
    }
}

// MARK: - Movie Transferable
struct Movie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.temporaryDirectory.appendingPathComponent(received.file.lastPathComponent)
            if FileManager.default.fileExists(atPath: copy.path) {
                try FileManager.default.removeItem(at: copy)
            }
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

// MARK: - Video Thumbnail View
struct VideoThumbnailView: View {
    let url: URL
    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray30)
                    .overlay {
                        Image(systemName: "video.fill")
                            .foregroundColor(.gray60)
                    }
            }
        }
        .onAppear {
            generateThumbnail()
        }
    }

    private func generateThumbnail() {
        Task {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true

            do {
                let cgImage = try await imageGenerator.image(at: .zero).image
                await MainActor.run {
                    thumbnail = UIImage(cgImage: cgImage)
                }
            } catch {
                // 썸네일 생성 실패 시 기본 placeholder 유지
            }
        }
    }
}
