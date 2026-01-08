//
//  HLSPlaylistProcessor.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import Foundation
import OSLog

final class HLSPlaylistProcessor {
    /// 마스터 플레이리스트를 다운로드하고 자막 정보를 제거한 후 Data URL로 반환합니다.
    /// 실패 시 원본 URL을 반환합니다.
    func processedPlaylistURL(from originalURL: URL) async -> URL {
        do {
            let playlistText = try await fetchPlaylist(from: originalURL)
            let processedText = removeSubtitlesAndResolveURLs(from: playlistText, baseURL: originalURL)

#if DEBUG
            Logger.network.debug("📝 Processed playlist:\n\(processedText.components(separatedBy: .newlines).prefix(15).joined(separator: "\n"))")
#endif

            if let dataURL = createDataURL(from: processedText) {
                Logger.network.info("✅ Successfully processed HLS master playlist")
                return dataURL
            } else {
                Logger.network.warning("⚠️ Failed to create data URL, falling back to original")
                return originalURL
            }
        } catch {
            Logger.network.error("❌ Failed to process playlist: \(error.localizedDescription), falling back to original")
            return originalURL
        }
    }

    private func fetchPlaylist(from url: URL) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return String(decoding: data, as: UTF8.self)
    }

    private func removeSubtitlesAndResolveURLs(from playlistText: String, baseURL: URL) -> String {
        let lines = playlistText.components(separatedBy: .newlines)
        var filteredLines: [String] = []

        // baseURL에서 디렉토리 경로 추출 (master.m3u8을 제외한 경로)
        let baseDirectory = baseURL.deletingLastPathComponent()

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // 자막 관련 라인 제거
            // 1. #EXT-X-MEDIA:TYPE=SUBTITLES로 시작하는 라인
            if trimmedLine.hasPrefix("#EXT-X-MEDIA:TYPE=SUBTITLES") {
                continue
            }

            // 2. SUBTITLES="subs" 속성을 포함하는 스트림 라인 처리
            if trimmedLine.contains("SUBTITLES=") {
                // SUBTITLES 속성만 제거
                let processedLine = trimmedLine.replacingOccurrences(
                    of: ",SUBTITLES=\"subs\"",
                    with: ""
                )
                filteredLines.append(processedLine)
            } else if !trimmedLine.isEmpty &&
                      !trimmedLine.hasPrefix("#") &&
                      !trimmedLine.hasPrefix("http://") &&
                      !trimmedLine.hasPrefix("https://") {
                // 3. 상대 경로를 절대 경로로 변환 (쿼리 파라미터 보존)
                if let absoluteURL = URL(string: trimmedLine, relativeTo: baseDirectory)?.absoluteURL {
                    filteredLines.append(absoluteURL.absoluteString)
                } else {
                    // 변환 실패 시 원본 유지
                    filteredLines.append(line)
                }
            } else {
                filteredLines.append(line)
            }
        }

        let finalURL = filteredLines.joined(separator: "\n")
        Logger.network.info("최종 URL: \(finalURL)")
        return finalURL
    }

    /// 동기 버전: 플레이리스트에서 자막 제거 및 상대 경로를 절대 경로로 변환
    /// ResourceLoader에서 사용하기 위한 동기 메서드
    func removeSubtitlesAndResolveURLsSync(from playlistText: String, baseURL: URL) -> String {
        return removeSubtitlesAndResolveURLs(from: playlistText, baseURL: baseURL)
    }

    private func createDataURL(from text: String) -> URL? {
        guard let data = text.data(using: .utf8) else { return nil }
        let base64 = data.base64EncodedString()
        return URL(string: "data:application/vnd.apple.mpegurl;base64,\(base64)")
    }
}
