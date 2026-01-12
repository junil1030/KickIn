//
//  VideoUploadService.swift
//  KickIn
//
//  Created by 서준일 on 01/12/26.
//

import Foundation
import AVFoundation
import UIKit
import OSLog

// MARK: - Result Types

struct VideoUploadResult {
    let videoURL: String          // 서버 비디오 URL
    let thumbnailURL: String      // 서버 썸네일 URL
    let localThumbnailURL: URL    // 로컬 썸네일 file:// URL
    let videoUUID: String
}

// MARK: - VideoUploadService

final class VideoUploadService {

    // MARK: - Properties

    private let networkService: NetworkServiceProtocol

    private lazy var temporaryDirectory: URL = {
        let baseTemp = FileManager.default.temporaryDirectory
        let videoTemp = baseTemp.appendingPathComponent("VideoUpload", isDirectory: true)
        if !FileManager.default.fileExists(atPath: videoTemp.path) {
            try? FileManager.default.createDirectory(at: videoTemp, withIntermediateDirectories: true)
        }
        return videoTemp
    }()

    // MARK: - Initialization

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    // MARK: - Public Methods

    /// 비디오에서 썸네일 생성
    func generateThumbnail(from videoURL: URL) async throws -> UIImage {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try await imageGenerator.image(at: .zero).image
            return UIImage(cgImage: cgImage)
        } catch {
            Logger.chat.error("❌ Thumbnail generation failed: \(error.localizedDescription)")
            throw VideoUploadError.thumbnailGenerationFailed(error)
        }
    }

    /// 썸네일을 로컬 파일로 저장
    func saveThumbnailToFile(image: UIImage, videoUUID: String) throws -> URL {
        let thumbnailFileName = "KickIn-\(videoUUID)-thumb.jpg"
        let localURL = temporaryDirectory.appendingPathComponent(thumbnailFileName)

        guard let jpegData = image.jpegData(compressionQuality: 0.7) else {
            let error = NSError(domain: "VideoUploadService", code: -1,
                               userInfo: [NSLocalizedDescriptionKey: "JPEG 데이터 변환 실패"])
            throw VideoUploadError.thumbnailSaveFailed(error)
        }

        do {
            try jpegData.write(to: localURL)
            Logger.chat.info("✅ Thumbnail saved: \(localURL.lastPathComponent)")
            return localURL
        } catch {
            Logger.chat.error("❌ Thumbnail save failed: \(error.localizedDescription)")
            throw VideoUploadError.thumbnailSaveFailed(error)
        }
    }

    /// 썸네일과 비디오를 순차적으로 업로드
    func uploadVideoWithThumbnail(
        videoURL: URL,
        roomId: String,
        quality: VideoCompressor.CompressionQuality = .medium,
        progressHandler: @escaping (VideoUploadProgress) -> Void
    ) async throws -> VideoUploadResult {

        let videoUUID = UUID().uuidString
        var compressedVideoURL: URL?
        var localThumbnailURL: URL?

        // 임시 파일 정리 보장
        defer {
            if let url = compressedVideoURL {
                try? FileManager.default.removeItem(at: url)
                Logger.chat.info("🗑️ Deleted compressed video: \(url.lastPathComponent)")
            }
        }

        // Step 1: Preparing
        await MainActor.run {
            progressHandler(VideoUploadProgress(phase: .preparing, progress: 0.0))
        }

        // Step 2: Generate thumbnail
        await MainActor.run {
            progressHandler(VideoUploadProgress(phase: .thumbnailGenerating, progress: 0.0))
        }

        let thumbnail: UIImage
        do {
            thumbnail = try await generateThumbnail(from: videoURL)
            localThumbnailURL = try saveThumbnailToFile(image: thumbnail, videoUUID: videoUUID)
            Logger.chat.info("✅ Thumbnail generated and saved: \(localThumbnailURL?.path ?? "nil")")
        } catch {
            Logger.chat.warning("⚠️ Thumbnail generation/save failed: \(error.localizedDescription)")
            // 유연한 처리: 썸네일 없이 비디오만 업로드
            return try await uploadVideoOnly(
                videoURL: videoURL,
                videoUUID: videoUUID,
                roomId: roomId,
                quality: quality,
                progressHandler: progressHandler
            )
        }

        // Step 3: Upload thumbnail
        await MainActor.run {
            progressHandler(VideoUploadProgress(phase: .thumbnailUploading, progress: 0.0))
        }

        let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7)!
        let thumbnailFileName = "KickIn-\(videoUUID)-thumb.jpg"

        var serverThumbnailURL: String?
        do {
            let thumbnailResponse: ChatFilesResponseDTO = try await networkService.uploadWithProgress(
                ChatRouter.uploadFiles(roomId: roomId),
                files: [(data: thumbnailData, name: "files", fileName: thumbnailFileName, mimeType: "image/jpeg")]
            ) { progress in
                Task { @MainActor in
                    progressHandler(VideoUploadProgress(phase: .thumbnailUploading, progress: progress))
                }
            }

            serverThumbnailURL = thumbnailResponse.files?.first
            Logger.chat.info("✅ Thumbnail uploaded: \(serverThumbnailURL ?? "nil")")
        } catch {
            Logger.chat.warning("⚠️ Thumbnail upload failed: \(error.localizedDescription)")
            // 유연한 처리: 로컬 썸네일 사용, 비디오 업로드 계속
        }

        // Step 4: Compress video
        await MainActor.run {
            progressHandler(VideoUploadProgress(phase: .compressing, progress: 0.0))
        }

        let compressor = VideoCompressor()
        do {
            compressedVideoURL = try await compressor.compress(
                url: videoURL,
                quality: quality
            ) { progress in
                Task { @MainActor in
                    progressHandler(VideoUploadProgress(phase: .compressing, progress: progress))
                }
            }
        } catch {
            Logger.chat.error("❌ Video compression failed: \(error.localizedDescription)")
            throw VideoUploadError.videoCompressionFailed(error as? VideoCompressionError ?? .unknown)
        }

        // Step 5: Upload video
        await MainActor.run {
            progressHandler(VideoUploadProgress(phase: .videoUploading, progress: 0.0))
        }

        let videoData = try Data(contentsOf: compressedVideoURL!)
        let videoFileName = "KickIn-\(videoUUID).mp4"

        let videoResponse: ChatFilesResponseDTO
        do {
            videoResponse = try await networkService.uploadWithProgress(
                ChatRouter.uploadFiles(roomId: roomId),
                files: [(data: videoData, name: "files", fileName: videoFileName, mimeType: "video/mp4")]
            ) { progress in
                Task { @MainActor in
                    progressHandler(VideoUploadProgress(phase: .videoUploading, progress: progress))
                }
            }
        } catch {
            Logger.chat.error("❌ Video upload failed: \(error.localizedDescription)")
            throw VideoUploadError.videoUploadFailed(error)
        }

        guard let serverVideoURL = videoResponse.files?.first else {
            let error = NetworkError.serverError(message: "No video path from server")
            throw VideoUploadError.videoUploadFailed(error)
        }

        // Step 6: Complete
        await MainActor.run {
            progressHandler(VideoUploadProgress(phase: .completed, progress: 1.0))
        }

        return VideoUploadResult(
            videoURL: serverVideoURL,
            thumbnailURL: serverThumbnailURL ?? VideoUploadService.getThumbnailURL(from: serverVideoURL),
            localThumbnailURL: localThumbnailURL!,
            videoUUID: videoUUID
        )
    }

    /// 임시 파일 정리
    func cleanupTemporaryFiles(videoUUID: String) {
        let thumbnailFileName = "KickIn-\(videoUUID)-thumb.jpg"
        let videoFileName = "KickIn-\(videoUUID).mp4"

        let thumbnailURL = temporaryDirectory.appendingPathComponent(thumbnailFileName)
        let videoURL = temporaryDirectory.appendingPathComponent(videoFileName)

        if FileManager.default.fileExists(atPath: thumbnailURL.path) {
            try? FileManager.default.removeItem(at: thumbnailURL)
            Logger.chat.info("🗑️ Deleted thumbnail: \(thumbnailURL.lastPathComponent)")
        }

        if FileManager.default.fileExists(atPath: videoURL.path) {
            try? FileManager.default.removeItem(at: videoURL)
            Logger.chat.info("🗑️ Deleted video: \(videoURL.lastPathComponent)")
        }
    }

    /// 유틸리티: 비디오 URL에서 썸네일 URL 생성
    static func getThumbnailURL(from videoURL: String) -> String {
        guard !videoURL.isEmpty else { return videoURL }
        if videoURL.contains("-thumb.") { return videoURL }

        if videoURL.hasSuffix(".mp4") {
            return videoURL.replacingOccurrences(of: ".mp4", with: "-thumb.jpg")
        } else if videoURL.hasSuffix(".mov") {
            return videoURL.replacingOccurrences(of: ".mov", with: "-thumb.jpg")
        }

        let url = videoURL as NSString
        let ext = url.pathExtension
        let base = url.deletingPathExtension
        return "\(base)-thumb.\(ext.isEmpty ? "jpg" : ext)"
    }

    // MARK: - Private Methods

    /// 썸네일 없이 비디오만 업로드 (썸네일 생성 실패 시)
    private func uploadVideoOnly(
        videoURL: URL,
        videoUUID: String,
        roomId: String,
        quality: VideoCompressor.CompressionQuality,
        progressHandler: @escaping (VideoUploadProgress) -> Void
    ) async throws -> VideoUploadResult {

        var compressedVideoURL: URL?

        defer {
            if let url = compressedVideoURL {
                try? FileManager.default.removeItem(at: url)
                Logger.chat.info("🗑️ Deleted compressed video: \(url.lastPathComponent)")
            }
        }

        // Step 1: Compress video
        await MainActor.run {
            progressHandler(VideoUploadProgress(phase: .compressing, progress: 0.0))
        }

        let compressor = VideoCompressor()
        do {
            compressedVideoURL = try await compressor.compress(
                url: videoURL,
                quality: quality
            ) { progress in
                Task { @MainActor in
                    progressHandler(VideoUploadProgress(phase: .compressing, progress: progress))
                }
            }
        } catch {
            Logger.chat.error("❌ Video compression failed: \(error.localizedDescription)")
            throw VideoUploadError.videoCompressionFailed(error as? VideoCompressionError ?? .unknown)
        }

        // Step 2: Upload video
        await MainActor.run {
            progressHandler(VideoUploadProgress(phase: .videoUploading, progress: 0.0))
        }

        let videoData = try Data(contentsOf: compressedVideoURL!)
        let videoFileName = "KickIn-\(videoUUID).mp4"

        let videoResponse: ChatFilesResponseDTO
        do {
            videoResponse = try await networkService.uploadWithProgress(
                ChatRouter.uploadFiles(roomId: roomId),
                files: [(data: videoData, name: "files", fileName: videoFileName, mimeType: "video/mp4")]
            ) { progress in
                Task { @MainActor in
                    progressHandler(VideoUploadProgress(phase: .videoUploading, progress: progress))
                }
            }
        } catch {
            Logger.chat.error("❌ Video upload failed: \(error.localizedDescription)")
            throw VideoUploadError.videoUploadFailed(error)
        }

        guard let serverVideoURL = videoResponse.files?.first else {
            let error = NetworkError.serverError(message: "No video path from server")
            throw VideoUploadError.videoUploadFailed(error)
        }

        // Step 3: Complete
        await MainActor.run {
            progressHandler(VideoUploadProgress(phase: .completed, progress: 1.0))
        }

        // 썸네일 없이 비디오만 반환 (로컬 썸네일 URL은 임시 디렉토리의 빈 파일)
        let dummyThumbnailURL = temporaryDirectory.appendingPathComponent("KickIn-\(videoUUID)-thumb.jpg")

        return VideoUploadResult(
            videoURL: serverVideoURL,
            thumbnailURL: VideoUploadService.getThumbnailURL(from: serverVideoURL),
            localThumbnailURL: dummyThumbnailURL,
            videoUUID: videoUUID
        )
    }
}
