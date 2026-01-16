//
//  ImagePicker.swift
//  KickIn
//
//  Created by 서준일 on 01/16/26
//

import SwiftUI
import PhotosUI
import OSLog

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let provider = results.first?.itemProvider else {
                Logger.profile.debug("이미지 선택 취소됨")
                return
            }

            Logger.profile.info("이미지 선택 시작")

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    guard let self = self else { return }

                    if let error = error {
                        Logger.profile.error("이미지 로드 실패: \(error.localizedDescription)")
                        return
                    }

                    guard let uiImage = image as? UIImage else {
                        Logger.profile.error("UIImage 변환 실패")
                        return
                    }

                    // JPEG로 변환
                    guard let jpegData = self.convertToJPEG(uiImage) else {
                        Logger.profile.error("JPEG 변환 실패")
                        return
                    }

                    DispatchQueue.main.async {
                        self.parent.selectedImageData = jpegData
                    }
                }
            }
        }

        /// 이미지를 JPEG 포맷으로 변환
        private func convertToJPEG(_ image: UIImage) -> Data? {
            Logger.profile.debug("JPEG 변환 시작")

            // 이미지가 너무 큰 경우 리사이징 (최대 1920px)
            let resizedImage = resizeImageIfNeeded(image, maxDimension: 1920)

            // JPEG로 변환 (품질 0.8)
            guard let jpegData = resizedImage.jpegData(compressionQuality: 0.8) else {
                return nil
            }

            let jpegSizeKB = Double(jpegData.count) / 1024.0
            Logger.profile.info("JPEG 변환 성공 - 파일 크기: \(String(format: "%.2f", jpegSizeKB))KB")

            return jpegData
        }

        /// 이미지가 너무 큰 경우 리사이징
        private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
            let size = image.size

            // 이미지가 이미 작은 경우 원본 반환
            if size.width <= maxDimension && size.height <= maxDimension {
                return image
            }

            // 비율 유지하며 리사이징
            let ratio = min(maxDimension / size.width, maxDimension / size.height)
            let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

            let renderer = UIGraphicsImageRenderer(size: newSize)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }
    }
}
