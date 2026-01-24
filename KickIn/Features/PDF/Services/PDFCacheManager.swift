//
//  PDFCacheManager.swift
//  KickIn
//
//  Created by 서준일 on 01/23/26
//

import Foundation

protocol PDFCacheManagerProtocol {
    func getCachedPDF(for url: String) -> URL?
    func savePDF(url: String, localPath: String, fileName: String, fileSize: Int64)
    func clearAllCache()
    func cleanupExpiredFiles()
}

final class PDFCacheManager: PDFCacheManagerProtocol {
    static let shared = PDFCacheManager()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let metadataFileURL: URL
    private var metadata: [String: PDFCacheMetadata] = [:]

    private init() {
        // Documents/PDFCache/ 디렉토리 설정
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = documentsPath.appendingPathComponent("PDFCache")
        self.metadataFileURL = documentsPath.appendingPathComponent("pdf_cache_metadata.json")

        // 캐시 디렉토리 생성
        createCacheDirectoryIfNeeded()

        // 메타데이터 로드
        loadMetadata()

        // 만료된 파일 자동 정리
        cleanupExpiredFiles()
    }

    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    private func loadMetadata() {
        guard fileManager.fileExists(atPath: metadataFileURL.path),
              let data = try? Data(contentsOf: metadataFileURL),
              let decoded = try? JSONDecoder().decode([String: PDFCacheMetadata].self, from: data) else {
            return
        }
        metadata = decoded
    }

    private func saveMetadata() {
        guard let encoded = try? JSONEncoder().encode(metadata) else { return }
        try? encoded.write(to: metadataFileURL)
    }

    // MARK: - Public Methods

    func getCachedPDF(for url: String) -> URL? {
        guard let meta = metadata[url],
              !meta.isExpired,
              fileManager.fileExists(atPath: meta.localPath) else {
            // 만료되었거나 파일이 없으면 메타데이터에서 제거
            metadata.removeValue(forKey: url)
            saveMetadata()
            return nil
        }
        return URL(fileURLWithPath: meta.localPath)
    }

    func savePDF(url: String, localPath: String, fileName: String, fileSize: Int64) {
        let meta = PDFCacheMetadata(
            url: url,
            localPath: localPath,
            cachedAt: Date(),
            fileSize: fileSize,
            fileName: fileName
        )
        metadata[url] = meta
        saveMetadata()
    }

    func clearAllCache() {
        // 모든 캐시 파일 삭제
        try? fileManager.removeItem(at: cacheDirectory)
        createCacheDirectoryIfNeeded()

        // 메타데이터 초기화
        metadata.removeAll()
        saveMetadata()
    }

    func cleanupExpiredFiles() {
        var expiredKeys: [String] = []

        for (key, meta) in metadata {
            if meta.isExpired {
                // 파일 삭제
                try? fileManager.removeItem(atPath: meta.localPath)
                expiredKeys.append(key)
            }
        }

        // 메타데이터에서 제거
        for key in expiredKeys {
            metadata.removeValue(forKey: key)
        }

        if !expiredKeys.isEmpty {
            saveMetadata()
        }
    }
}
