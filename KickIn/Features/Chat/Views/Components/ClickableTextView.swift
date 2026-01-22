//
//  ClickableTextView.swift
//  KickIn
//
//  Created by 서준일 on 01/22/26.
//

import SwiftUI

/// URL을 하이라이트하고 클릭 가능하게 만드는 텍스트 뷰
struct ClickableTextView: View {
    let text: String
    let detectedLinks: [DetectedLink]
    let onURLTap: (String) -> Void

    var body: some View {
        Text(attributedText)
            .font(.body2(.pretendardMedium))
            .foregroundColor(.gray90)
            .textSelection(.enabled)
            .environment(\.openURL, OpenURLAction { url in
                onURLTap(url.absoluteString)
                return .handled
            })
    }

    private var attributedText: AttributedString {
        var attributedString = AttributedString(text)

        // 모든 텍스트에 기본 스타일 적용
        attributedString.font = .body2(.pretendardMedium)
        attributedString.foregroundColor = .gray90

        // URL 부분 하이라이트
        for link in detectedLinks {
            guard let range = Range(link.range, in: text),
                  let startIndex = AttributedString.Index(range.lowerBound, within: attributedString),
                  let endIndex = AttributedString.Index(range.upperBound, within: attributedString) else {
                continue
            }

            attributedString[startIndex..<endIndex].foregroundColor = .blue
            attributedString[startIndex..<endIndex].underlineStyle = .single

            if let url = URL(string: link.url) {
                attributedString[startIndex..<endIndex].link = url
            }
        }

        return attributedString
    }
}
