//
//  HLSResourceLoaderDelegate.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import Foundation
import AVFoundation
import OSLog

final class HLSResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    private let authToken: String
    private let session: URLSession
    private let playlistProcessor = HLSPlaylistProcessor()

    init(authToken: String, session: URLSession = .shared) {
        self.authToken = authToken
        self.session = session
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let originalURL = loadingRequest.request.url else {
            return false
        }

        // .vtt 파일 요청 차단 (자막은 별도로 처리)
        if originalURL.pathExtension.lowercased() == "vtt" {
            loadingRequest.finishLoading(with: NSError(
                domain: "HLSResourceLoaderDelegate",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Subtitle requests are handled separately"]
            ))
            return true
        }

        guard let resolvedURL = resolvedURL(for: originalURL) else {
            return false
        }

        // 마스터 플레이리스트 요청 감지
        let isMasterPlaylist = resolvedURL.lastPathComponent.contains("master.m3u8")

        let task = session.dataTask(with: resolvedURL) { [weak self] data, response, error in
            if let error = error {
                loadingRequest.finishLoading(with: error)
                return
            }

            guard let self = self else {
                loadingRequest.finishLoading()
                return
            }

            if let response = response as? HTTPURLResponse {
                let mimeType = response.mimeType ?? self.mimeType(for: resolvedURL)
                loadingRequest.contentInformationRequest?.contentType = mimeType
                loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
            }

            if let data = data {
                // 마스터 플레이리스트인 경우 자막 제거 처리
                if isMasterPlaylist, let playlistText = String(data: data, encoding: .utf8) {
                    let processedText = self.playlistProcessor.removeSubtitlesAndResolveURLsSync(
                        from: playlistText,
                        baseURL: resolvedURL
                    )
                    if let processedData = processedText.data(using: .utf8) {
                        loadingRequest.contentInformationRequest?.contentLength = Int64(processedData.count)
                        loadingRequest.dataRequest?.respond(with: processedData)
                        Logger.network.debug("✅ Processed master playlist in ResourceLoader")
                    } else {
                        loadingRequest.contentInformationRequest?.contentLength = Int64(data.count)
                        loadingRequest.dataRequest?.respond(with: data)
                    }
                } else {
                    loadingRequest.contentInformationRequest?.contentLength = Int64(data.count)
                    loadingRequest.dataRequest?.respond(with: data)
                }
            }
            loadingRequest.finishLoading()
        }
        task.resume()
        return true
    }

    private func resolvedURL(for url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return url }

        if components.scheme == "myhls" {
            components.scheme = "http"
        }

        if shouldAppendToken(components) {
            var queryItems = components.queryItems ?? []
            if !queryItems.contains(where: { $0.name == "token" }) {
                queryItems.append(URLQueryItem(name: "token", value: authToken))
                components.queryItems = queryItems
            }
        }

        return components.url
    }

    private func shouldAppendToken(_ components: URLComponents) -> Bool {
        let queryItems = components.queryItems ?? []
        return !queryItems.contains(where: { $0.name == "token" })
    }

    private func mimeType(for url: URL) -> String {
        if url.pathExtension.lowercased() == "m3u8" {
            return "application/vnd.apple.mpegurl"
        }
        if url.pathExtension.lowercased() == "vtt" {
            return "text/vtt"
        }
        return "application/octet-stream"
    }
}
