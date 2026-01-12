//
//  VideoCompressionError.swift
//  KickIn
//
//  Created by 서준일 on 01/12/26.
//

import Foundation

enum VideoCompressionError: LocalizedError {
    case noVideoTrack
    case exportSessionCreationFailed
    case compressionFailed(Error)
    case cancelled
    case unknown

    var errorDescription: String? {
        switch self {
        case .noVideoTrack:
            return "비디오 트랙을 찾을 수 없습니다."
        case .exportSessionCreationFailed:
            return "비디오 압축 세션을 생성할 수 없습니다."
        case .compressionFailed(let error):
            return "비디오 압축에 실패했습니다: \(error.localizedDescription)"
        case .cancelled:
            return "압축이 취소되었습니다."
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
