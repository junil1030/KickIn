//
//  VideoCompressor.swift
//  KickIn
//
//  Created by 서준일 on 01/12/26.
//

import AVFoundation
import OSLog

final class VideoCompressor {

    // MARK: - Properties

    /// 임시 디렉토리 (앱 전용)
    private lazy var temporaryDirectory: URL = {
        let baseTemp = FileManager.default.temporaryDirectory
        let videoTemp = baseTemp.appendingPathComponent("VideoCompression", isDirectory: true)

        // 디렉토리 생성
        if !FileManager.default.fileExists(atPath: videoTemp.path) {
            try? FileManager.default.createDirectory(
                at: videoTemp,
                withIntermediateDirectories: true
            )
        }

        return videoTemp
    }()

    // MARK: - Compression Quality

    enum CompressionQuality {
        case high      // HEVC 1920x1080 (HEVC 지원 시), H.264 1920x1080 (fallback)
        case medium    // HEVC 1280x720
        case low       // H.264 960x540

        func preset(hevcSupported: Bool) -> String {
            switch self {
            case .high:
                return hevcSupported
                    ? AVAssetExportPresetHEVC1920x1080
                    : AVAssetExportPresetHighestQuality
            case .medium:
                return hevcSupported
                    ? AVAssetExportPresetHEVC1920x1080
                    : AVAssetExportPresetMediumQuality
            case .low:
                return AVAssetExportPresetMediumQuality
            }
        }

        var targetResolution: CGSize {
            switch self {
            case .high: return CGSize(width: 1920, height: 1080)
            case .medium: return CGSize(width: 1280, height: 720)
            case .low: return CGSize(width: 960, height: 540)
            }
        }
    }

    // MARK: - Initialization

    init() {
        cleanupOldTemporaryFiles()
    }

    // MARK: - Public Methods

    /// 비디오 압축
    /// - Parameters:
    ///   - url: 원본 비디오 URL
    ///   - quality: 압축 품질
    ///   - progressHandler: 진행률 콜백 (0.0 ~ 1.0)
    /// - Returns: 압축된 비디오 URL (임시 디렉토리)
    func compress(
        url: URL,
        quality: CompressionQuality = .medium,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
//        let asset = AVAsset(url: url)
        let asset = AVURLAsset(url: url)

        // 압축 필요 여부 판단
        let needsCompression = try await shouldCompress(asset: asset, targetQuality: quality)

        if !needsCompression {
            Logger.chat.info("✅ Pass-through: 원본 URL 반환")
            // 원본을 임시 디렉토리로 복사 (일관성 유지)
            let outputURL = temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
            try FileManager.default.copyItem(at: url, to: outputURL)
            await MainActor.run {
                progressHandler(1.0) // 즉시 100% 완료
            }
            return outputURL
        }

        // HEVC 지원 여부 확인
        let hevcSupported = checkHEVCSupport()
        let preset = quality.preset(hevcSupported: hevcSupported)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw VideoCompressionError.exportSessionCreationFailed
        }

        // 비디오 트랙 가져오기
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoCompressionError.noVideoTrack
        }

        // Transform 정보 가져오기
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let naturalSize = try await videoTrack.load(.naturalSize)

        // 세로 영상 판단 (90도 또는 270도 회전)
        let isPortrait = abs(preferredTransform.b) == 1.0 && abs(preferredTransform.c) == 1.0

        if isPortrait {
            Logger.chat.info("📱 세로 영상 감지, transform 유지")
        } else {
            Logger.chat.info("📐 가로 영상")
        }

        // Export session 설정
        let outputURL = temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true  // 스트리밍 최적화

        // Video composition으로 transform 보존
        if isPortrait {
            let composition = AVMutableVideoComposition(propertiesOf: asset)
            composition.renderSize = CGSize(
                width: naturalSize.height,  // 세로 영상은 width/height 교환
                height: naturalSize.width
            )

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(
                start: .zero,
                duration: try await asset.load(.duration)
            )

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            layerInstruction.setTransform(preferredTransform, at: .zero)

            instruction.layerInstructions = [layerInstruction]
            composition.instructions = [instruction]

            exportSession.videoComposition = composition
        }

        // 진행률 모니터링 시작
        let monitoringTask = startProgressMonitoring(exportSession, handler: progressHandler)

        // Task cancellation 체크
        try Task.checkCancellation()

        // Export 시작
        await exportSession.export()

        // 모니터링 종료
        monitoringTask.cancel()

        // Task cancellation 체크
        if Task.isCancelled {
            throw VideoCompressionError.cancelled
        }

        // Export 결과 확인
        switch exportSession.status {
        case .completed:
            Logger.chat.info("✅ Video compression completed")
            await MainActor.run {
                progressHandler(1.0)
            }
            return outputURL

        case .failed:
            if let error = exportSession.error {
                throw VideoCompressionError.compressionFailed(error)
            } else {
                throw VideoCompressionError.unknown
            }

        case .cancelled:
            throw VideoCompressionError.cancelled

        default:
            throw VideoCompressionError.unknown
        }
    }

    /// 압축 완료 후 호출 (외부에서 사용)
    func cleanupTemporaryFile(at url: URL) {
        guard url.path.hasPrefix(temporaryDirectory.path) else {
            Logger.chat.warning("⚠️ 임시 디렉토리 외부 파일, 삭제 건너뜀")
            return
        }

        try? FileManager.default.removeItem(at: url)
        Logger.chat.info("🗑️ 임시 파일 삭제: \(url.lastPathComponent)")
    }

    // MARK: - Private Methods

    /// 압축 필요 여부 판단 (Pass-through 로직)
    private func shouldCompress(
        asset: AVAsset,
        targetQuality: CompressionQuality
    ) async throws -> Bool {
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoCompressionError.noVideoTrack
        }

        // 원본 해상도 확인
        let naturalSize = try await videoTrack.load(.naturalSize)
        let estimatedDataRate = try await videoTrack.load(.estimatedDataRate)

        let targetResolution = targetQuality.targetResolution

        // 원본이 목표보다 작거나 같으면 pass-through
        if naturalSize.width <= targetResolution.width &&
           naturalSize.height <= targetResolution.height {
            Logger.chat.info("✅ 원본 해상도(\(naturalSize.width)x\(naturalSize.height)) ≤ 목표(\(targetResolution.width)x\(targetResolution.height)), 압축 건너뜀")
            return false
        }

        // 비트레이트가 이미 효율적이면 pass-through
        // HEVC는 일반적으로 H.264의 50% 비트레이트로 동일 화질
        let estimatedBitrateMbps = estimatedDataRate / 1_000_000
        if estimatedBitrateMbps < 3.0 { // 3Mbps 미만은 이미 효율적
            Logger.chat.info("✅ 원본 비트레이트(\(estimatedBitrateMbps)Mbps)가 이미 효율적, 압축 건너뜀")
            return false
        }

        return true
    }

    /// HEVC 호환성 체크
    private func checkHEVCSupport() -> Bool {
        let hevcPresets = [
            AVAssetExportPresetHEVC1920x1080,
            AVAssetExportPresetHEVC3840x2160
        ]

        let allPresets = AVAssetExportSession.allExportPresets()
        let hevcSupported = hevcPresets.contains { allPresets.contains($0) }

        if hevcSupported {
            Logger.chat.info("✅ HEVC 인코딩 지원됨")
        } else {
            Logger.chat.info("⚠️ HEVC 미지원, H.264 fallback 사용")
        }

        return hevcSupported
    }

    /// 24시간 이상 된 임시 파일 삭제
    private func cleanupOldTemporaryFiles() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: temporaryDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        ) else { return }

        let now = Date()
        let expirationInterval: TimeInterval = 24 * 60 * 60 // 24시간

        for fileURL in files {
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                  let creationDate = attributes[.creationDate] as? Date else {
                continue
            }

            if now.timeIntervalSince(creationDate) > expirationInterval {
                try? FileManager.default.removeItem(at: fileURL)
                Logger.chat.info("🗑️ 오래된 임시 파일 삭제: \(fileURL.lastPathComponent)")
            }
        }
    }

    /// Progress 모니터링
    private func startProgressMonitoring(
        _ session: AVAssetExportSession,
        handler: @escaping (Double) -> Void
    ) -> Task<Void, Never> {
        Task {
            while !Task.isCancelled {
                let progress = Double(session.progress)
                await MainActor.run {
                    handler(progress)
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            }
        }
    }
}
