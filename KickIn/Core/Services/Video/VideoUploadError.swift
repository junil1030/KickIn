//
//  VideoUploadError.swift
//  KickIn
//
//  Created by 서준일 on 01/12/26.
//

import Foundation

enum VideoUploadError: LocalizedError {
    case thumbnailGenerationFailed(Error)
    case thumbnailSaveFailed(Error)
    case thumbnailUploadFailed(Error)
    case videoCompressionFailed(VideoCompressionError)
    case videoUploadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .thumbnailGenerationFailed(let error):
            return "썸네일 생성에 실패했습니다: \(error.localizedDescription)"
        case .thumbnailSaveFailed(let error):
            return "썸네일 저장에 실패했습니다: \(error.localizedDescription)"
        case .thumbnailUploadFailed(let error):
            return "썸네일 업로드에 실패했습니다: \(error.localizedDescription)"
        case .videoCompressionFailed(let error):
            return error.localizedDescription
        case .videoUploadFailed(let error):
            return "비디오 업로드에 실패했습니다: \(error.localizedDescription)"
        }
    }
}
