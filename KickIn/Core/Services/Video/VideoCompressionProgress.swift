//
//  VideoCompressionProgress.swift
//  KickIn
//
//  Created by 서준일 on 01/12/26.
//

import Foundation

struct VideoCompressionProgress {
    let phase: Phase
    let progress: Double  // 0.0 ~ 1.0

    enum Phase {
        case preparing
        case compressing
        case uploading
        case completed
        case failed(Error)
    }

    var percentage: Int {
        Int(progress * 100)
    }
}
