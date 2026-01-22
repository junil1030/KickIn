//
//  LinkPreviewService.swift
//  KickIn
//
//  Created by 서준일 on 01/22/26.
//

import Foundation
import OSLog

/// 링크 프리뷰 관련 에러
enum LinkPreviewError: Error {
    case invalidURL
    case networkError(Error)
    case parsingFailed
    case timeout
}

/// 링크 프리뷰 서비스 프로토콜
protocol LinkPreviewServiceProtocol {
    func fetchMetadata(for url: String) async throws -> LinkMetadata
}

/// 링크 프리뷰 메타데이터를 가져오는 서비스
final class LinkPreviewService: LinkPreviewServiceProtocol {
    // MARK: - Properties

    private let cache: LinkMetadataCache
    private let session: URLSession
    private let timeout: TimeInterval = 10.0

    // MARK: - Initialization

    init(cache: LinkMetadataCache = LinkMetadataCache()) {
        self.cache = cache

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public Methods

    /// URL에서 오픈 그래프 메타데이터 가져오기
    /// - Parameter url: 메타데이터를 가져올 URL
    /// - Returns: 파싱된 LinkMetadata
    /// - Throws: LinkPreviewError
    func fetchMetadata(for url: String) async throws -> LinkMetadata {
        // 1. 캐시 확인
        if let cached = cache.get(url: url), !cached.isExpired {
            Logger.chat.debug("Link metadata cache hit: \(url)")
            return cached
        }

        // 2. URL 유효성 검증
        guard let parsedURL = URL(string: url),
              let scheme = parsedURL.scheme,
              (scheme == "http" || scheme == "https") else {
            throw LinkPreviewError.invalidURL
        }

        // 3. HTML fetch
        Logger.chat.debug("Fetching link metadata: \(url)")

        do {
            let (data, _) = try await session.data(from: parsedURL)

            // 4. HTML 파싱
            guard let html = String(data: data, encoding: .utf8) else {
                Logger.chat.debug("Failed to decode HTML: \(url)")
                throw LinkPreviewError.parsingFailed
            }

            // HTML 샘플 로깅 (처음 500자)
            let htmlPreview = String(html.prefix(500))
            Logger.chat.debug("HTML preview for \(url): \(htmlPreview)")

            guard let metadata = OpenGraphParser.parse(html: html, url: url) else {
                Logger.chat.debug("Failed to parse OG metadata: \(url)")
                throw LinkPreviewError.parsingFailed
            }

            // 5. 캐시 저장
            cache.set(url: url, metadata: metadata)
            Logger.chat.debug("Link metadata fetched successfully: \(url) - title: \(metadata.title ?? "nil")")

            return metadata
        } catch is CancellationError {
            Logger.chat.debug("Link metadata fetch cancelled: \(url)")
            throw LinkPreviewError.timeout
        } catch {
            Logger.chat.debug("Link metadata fetch failed: \(url), error: \(error.localizedDescription)")
            throw LinkPreviewError.networkError(error)
        }
    }
}
