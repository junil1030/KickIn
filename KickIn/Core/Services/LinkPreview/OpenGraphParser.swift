//
//  OpenGraphParser.swift
//  KickIn
//
//  Created by 서준일 on 01/22/26.
//

import Foundation

/// HTML에서 오픈 그래프 메타데이터를 추출하는 파서
enum OpenGraphParser {
    /// HTML 문자열에서 오픈 그래프 메타데이터 파싱
    /// - Parameters:
    ///   - html: HTML 문자열
    ///   - url: 원본 URL (메타데이터 저장용)
    /// - Returns: 파싱된 LinkMetadata, 실패 시 nil
    static func parse(html: String, url: String) -> LinkMetadata? {
        let ogTitle = extractMetaTag(from: html, property: "og:title")
        let ogDescription = extractMetaTag(from: html, property: "og:description")
        let ogImage = extractMetaTag(from: html, property: "og:image")
        let ogSiteName = extractMetaTag(from: html, property: "og:site_name")

        // og:title이 없으면 <title> 태그에서 추출
        let title = ogTitle ?? extractTitleTag(from: html)

        // 최소한 제목 또는 이미지가 있어야 유효한 메타데이터
        guard title != nil || ogImage != nil else {
            return nil
        }

        return LinkMetadata(
            url: url,
            title: title,
            description: ogDescription,
            imageURL: ogImage,
            siteName: ogSiteName,
            fetchedAt: Date()
        )
    }

    // MARK: - Private Helpers

    /// HTML에서 특정 property의 meta tag content 추출
    /// - Parameters:
    ///   - html: HTML 문자열
    ///   - property: 찾을 property 이름 (예: "og:title")
    /// - Returns: content 값, 찾지 못하면 nil
    private static func extractMetaTag(from html: String, property: String) -> String? {
        // 여러 패턴 시도 (순서가 바뀐 경우도 처리)
        let patterns = [
            "<meta\\s+property=['\"]?\(property)['\"]?\\s+content=['\"]?([^'\"]+)['\"]?",
            "<meta\\s+content=['\"]?([^'\"]+)['\"]?\\s+property=['\"]?\(property)['\"]?"
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count)),
                  match.numberOfRanges > 1 else {
                continue
            }

            let contentRange = match.range(at: 1)
            guard let range = Range(contentRange, in: html) else {
                continue
            }

            let content = String(html[range])
            if !content.isEmpty {
                return decodeHTMLEntities(content)
            }
        }

        return nil
    }

    /// HTML에서 <title> 태그 내용 추출
    /// - Parameter html: HTML 문자열
    /// - Returns: title 내용, 찾지 못하면 nil
    private static func extractTitleTag(from html: String) -> String? {
        let pattern = "<title>([^<]+)</title>"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count)),
              match.numberOfRanges > 1 else {
            return nil
        }

        let titleRange = match.range(at: 1)
        guard let range = Range(titleRange, in: html) else {
            return nil
        }

        let title = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? nil : decodeHTMLEntities(title)
    }

    /// HTML 엔티티 디코딩 (간단한 케이스만 처리)
    /// - Parameter text: 디코딩할 텍스트
    /// - Returns: 디코딩된 텍스트
    private static func decodeHTMLEntities(_ text: String) -> String {
        var result = text
        let entities = [
            "&quot;": "\"",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&#39;": "'",
            "&apos;": "'"
        ]

        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        return result
    }
}
