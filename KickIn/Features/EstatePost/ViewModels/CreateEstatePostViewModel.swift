//
//  CreateEstatePostViewModel.swift
//  KickIn
//
//  Created by 서준일 on 01/03/26.
//

import Foundation
import SwiftUI
import Combine
import OSLog

@MainActor
final class CreateEstatePostViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isUploading = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false

    // MARK: - Private Properties

    private let estateId: String
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()

    // MARK: - Constants

    private let maxFileCount = 5
    private let maxFileSizeBytes = 5 * 1024 * 1024  // 5MB

    // MARK: - Initialization

    init(estateId: String) {
        self.estateId = estateId
    }

    // MARK: - Public Methods

    /// 게시글 작성 전체 플로우: 파일 업로드 → 게시글 생성
    func submitPost(title: String, content: String, images: [UIImage]) async {
        guard !title.isEmpty, !content.isEmpty else {
            errorMessage = "제목과 내용을 입력해주세요."
            return
        }

        isUploading = true
        errorMessage = nil

        do {
            // Step 1: 이미지가 있으면 업로드
            var filePaths: [String] = []
            if !images.isEmpty {
                filePaths = try await uploadFiles(images: images)
                Logger.network.info("Uploaded \(filePaths.count) files")
            }

            // Step 2: 게시글 생성
            try await createPost(title: title, content: content, filePaths: filePaths)

            showSuccessAlert = true
            Logger.network.info("Post created successfully for estate ID: \(self.estateId)")

        } catch let error as NetworkError {
            Logger.network.error("Failed to create post: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            Logger.network.error("Unknown error: \(error.localizedDescription)")
            errorMessage = "게시글 작성에 실패했습니다."
        }

        isUploading = false
    }

    // MARK: - Private Methods

    /// 파일 업로드: POST /v1/posts/files (multipart/form-data)
    private func uploadFiles(images: [UIImage]) async throws -> [String] {
        // 파일 개수 검증
        guard images.count <= maxFileCount else {
            throw NetworkError.badRequest(message: "최대 \(maxFileCount)개의 이미지만 업로드할 수 있습니다.")
        }

        // UIImage -> Data 변환 및 파일 크기 검증
        let files = try images.map { image -> (data: Data, name: String, fileName: String, mimeType: String) in
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw NetworkError.unknown
            }

            guard imageData.count <= maxFileSizeBytes else {
                throw NetworkError.badRequest(message: "이미지 크기는 5MB를 초과할 수 없습니다.")
            }

            let fileName = "image_\(UUID().uuidString).jpg"
            return (data: imageData, name: "files", fileName: fileName, mimeType: "image/jpeg")
        }

        Logger.network.debug("Uploading \(files.count) files to /posts/files...")

        // NetworkService.upload() 호출
        let response: PostFilesResponseDTO = try await networkService.upload(
            CommunityPostRouter.uploadFiles,
            files: files
        )

        guard let filePaths = response.files, !filePaths.isEmpty else {
            throw NetworkError.noData
        }

        return filePaths
    }

    /// 게시글 생성: POST /v1/posts (application/json)
    private func createPost(title: String, content: String, latitude: Double = 37.654215, longitude: Double = 127.049914, filePaths: [String]) async throws {
        let requestDTO = CreatePostRequestDTO(
            category: estateId,
            title: title,
            content: content,
            latitude: latitude,
            longitude: longitude,
            files: filePaths
        )

        Logger.network.debug("Creating post with \(filePaths.count) files...")

        let _: PostResponseDTO = try await networkService.request(
            CommunityPostRouter.createPost(requestDTO)
        )
    }
}
