//
//  AttachmentMenuView.swift
//  KickIn
//
//  Created by 서준일 on 01/23/26
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AttachmentMenuView: View {
    @Binding var isPresented: Bool
    @Binding var selectedPDFURLs: [URL]
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedVideoItems: [PhotosPickerItem] = []
    @State private var showPDFPicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    let remainingSlots: Int
    var onPhotosSelected: (([PhotosPickerItem]) -> Void)?
    var onVideosSelected: (([PhotosPickerItem]) -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // 첨부 메뉴 헤더
            HStack {
                Text("첨부")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation {
                        isPresented = false
                        onDismiss?()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()

            Divider()

            // 첨부 옵션
            HStack(spacing: 20) {
                // 사진 버튼
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: remainingSlots,
                    matching: .images
                ) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                        Text("사진")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .onChange(of: selectedPhotoItems) { _, newItems in
                    handlePhotoSelection(newItems)
                }
                .disabled(remainingSlots <= 0)

                // 동영상 버튼
                PhotosPicker(
                    selection: $selectedVideoItems,
                    maxSelectionCount: remainingSlots,
                    matching: .videos
                ) {
                    VStack(spacing: 8) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.purple)
                        Text("동영상")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .onChange(of: selectedVideoItems) { _, newItems in
                    handleVideoSelection(newItems)
                }
                .disabled(remainingSlots <= 0)

                // PDF 버튼
                Button {
                    if remainingSlots > 0 {
                        showPDFPicker = true
                    } else {
                        alertMessage = "최대 5개의 파일만 선택할 수 있습니다."
                        showAlert = true
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                        Text("PDF")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(remainingSlots <= 0)
            }
            .padding()

            Spacer()
        }
        .frame(height: 250)
        .background(Color(uiColor: .systemBackground))
        .fileImporter(
            isPresented: $showPDFPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            handlePDFSelection(result)
        }
        .alert("알림", isPresented: $showAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Private Methods

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        onPhotosSelected?(items)
        selectedPhotoItems.removeAll()
        withAnimation {
            isPresented = false
        }
    }

    private func handleVideoSelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        onVideosSelected?(items)
        selectedVideoItems.removeAll()
        withAnimation {
            isPresented = false
        }
    }

    private func handlePDFSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            // 개수 제한 체크
            let limitedURLs = Array(urls.prefix(remainingSlots))

            if limitedURLs.count < urls.count {
                alertMessage = "최대 5개의 파일만 선택할 수 있습니다."
                showAlert = true
            }

            // 파일 크기 체크 및 임시 디렉토리로 복사
            var copiedURLs: [URL] = []
            let maxFileSize: Int64 = 5 * 1024 * 1024 // 5MB
            let tempDirectory = FileManager.default.temporaryDirectory

            for url in limitedURLs {
                // Security-scoped resource 접근
                guard url.startAccessingSecurityScopedResource() else {
                    continue
                }
                defer { url.stopAccessingSecurityScopedResource() }

                do {
                    // 파일 크기 체크
                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    let fileSize = attributes[.size] as? Int64 ?? 0

                    if fileSize > maxFileSize {
                        alertMessage = "\(url.lastPathComponent)의 크기가 5MB를 초과합니다."
                        showAlert = true
                        continue
                    }

                    // 임시 디렉토리로 복사
                    let fileName = url.lastPathComponent
                    let tempURL = tempDirectory.appendingPathComponent("PDF_\(UUID().uuidString)_\(fileName)")

                    // 기존 파일이 있으면 삭제
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }

                    // 파일 복사
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    copiedURLs.append(tempURL)

                } catch {
                    alertMessage = "PDF 복사에 실패했습니다: \(error.localizedDescription)"
                    showAlert = true
                    continue
                }
            }

            // 복사된 PDF를 부모 뷰로 전달
            if !copiedURLs.isEmpty {
                selectedPDFURLs.append(contentsOf: copiedURLs)
                withAnimation {
                    isPresented = false
                }
            }

        case .failure(let error):
            alertMessage = "PDF 선택에 실패했습니다: \(error.localizedDescription)"
            showAlert = true
        }
    }
}
