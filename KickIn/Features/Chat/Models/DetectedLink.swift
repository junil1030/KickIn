//
//  DetectedLink.swift
//  KickIn
//
//  Created by 서준일 on 01/22/26.
//

import Foundation

/// 텍스트에서 감지된 URL 정보
struct DetectedLink: Identifiable, Hashable {
    let id: String  // URL 자체를 ID로 사용
    let url: String
    let range: NSRange

    init(url: String, range: NSRange) {
        self.id = url
        self.url = url
        self.range = range
    }
}
