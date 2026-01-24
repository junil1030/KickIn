//
//  PDFCacheMetadata.swift
//  KickIn
//
//  Created by 서준일 on 01/23/26
//

import Foundation

struct PDFCacheMetadata: Codable {
    let url: String
    let localPath: String
    let cachedAt: Date
    let fileSize: Int64
    let fileName: String

    var isExpired: Bool {
        Date().timeIntervalSince(cachedAt) > TimeInterval(7 * 24 * 60 * 60)
    }
}
