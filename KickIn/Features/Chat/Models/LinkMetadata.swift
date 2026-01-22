//
//  LinkMetadata.swift
//  KickIn
//
//  Created by 서준일 on 01/22/26.
//

import Foundation

/// 링크 프리뷰를 위한 오픈 그래프 메타데이터
struct LinkMetadata: Codable, Hashable {
    let url: String
    let title: String?
    let description: String?
    let imageURL: String?
    let siteName: String?
    let fetchedAt: Date

    /// 메타데이터가 표시 가능한지 확인 (제목 또는 이미지가 있어야 함)
    var isValid: Bool {
        title != nil || imageURL != nil
    }

    /// 메타데이터가 만료되었는지 확인 (7일 TTL)
    var isExpired: Bool {
        let expirationDate = Calendar.current.date(byAdding: .day, value: 7, to: fetchedAt) ?? fetchedAt
        return Date() > expirationDate
    }
}
