//
//  PDFViewerViewModel.swift
//  KickIn
//
//  Created by 서준일 on 01/23/26
//

import Foundation
import Combine
import OSLog

@MainActor
final class PDFViewerViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var isLoading: Bool = false
    @Published var downloadProgress: Double = 0.0
    @Published var localPDFURL: URL?
    @Published var errorMessage: String?

    // MARK: - Properties

    private let networkService: NetworkServiceProtocol
    private let cacheManager: PDFCacheManagerProtocol
    private let fileManager = FileManager.default

    private lazy var cacheDirectory: URL = {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("PDFCache")
    }()

    // MARK: - Initialization

    init(
        networkService: NetworkServiceProtocol = NetworkServiceFactory.shared.makeNetworkService(),
        cacheManager: PDFCacheManagerProtocol = PDFCacheManager.shared
    ) {
        self.networkService = networkService
        self.cacheManager = cacheManager
    }

    // MARK: - Public Methods

    func loadPDF(from url: URL) async {
        Logger.chat.info("📄 [PDFViewer] Starting to load PDF from: \(url.absoluteString)")

        isLoading = true
        downloadProgress = 0.0
        errorMessage = nil
        localPDFURL = nil

        do {
            let localURL = try await downloadAndCache(url: url) { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.downloadProgress = progress
                }
            }

            self.localPDFURL = localURL
            Logger.chat.info("✅ PDF loaded successfully: \(localURL.lastPathComponent)")

        } catch {
            Logger.chat.error("❌ Failed to load PDF from \(url.absoluteString)")
            Logger.chat.error("❌ Error: \(error.localizedDescription)")

            if let networkError = error as? NetworkError {
                self.errorMessage = networkError.localizedDescription
            } else {
                self.errorMessage = "PDF를 불러오는 데 실패했습니다: \(error.localizedDescription)"
            }
        }

        isLoading = false
    }

    // MARK: - Private Methods

    private func downloadAndCache(
        url: URL,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        let urlString = url.absoluteString

        // 1. 캐시에 이미 있는지 확인
        if let cachedURL = cacheManager.getCachedPDF(for: urlString) {
            Logger.chat.info("✅ PDF found in cache: \(cachedURL.lastPathComponent)")
            Task { @MainActor in
                progressHandler(1.0)
            }
            return cachedURL
        }

        // 2. 다운로드할 로컬 경로 설정
        let fileName = (urlString as NSString).lastPathComponent.isEmpty
            ? "document_\(UUID().uuidString).pdf"
            : (urlString as NSString).lastPathComponent

        let localURL = cacheDirectory.appendingPathComponent(fileName)

        // 3. NetworkService로 다운로드 (SeSACKey와 AccessToken 자동 포함)
        Logger.chat.info("📥 Downloading PDF: \(urlString)")
        Logger.chat.info("📁 Local path will be: \(localURL.path)")
        Logger.chat.info("📝 File name: \(fileName)")

        let fileURL = try await networkService.downloadPDF(
            from: url,
            to: localURL,
            progressHandler: progressHandler
        )

        // 4. 파일 크기 확인
        let fileSize: Int64
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            fileSize = attributes[.size] as? Int64 ?? 0
        } catch {
            Logger.chat.error("❌ Failed to get file size: \(error.localizedDescription)")
            fileSize = 0
        }

        // 5. 캐시에 저장
        cacheManager.savePDF(
            url: urlString,
            localPath: fileURL.path,
            fileName: fileName,
            fileSize: fileSize
        )

        Logger.chat.info("✅ PDF downloaded and cached: \(fileURL.lastPathComponent)")
        return fileURL
    }
}
