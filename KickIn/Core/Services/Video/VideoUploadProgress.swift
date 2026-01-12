//
//  VideoUploadProgress.swift
//  KickIn
//
//  Created by 서준일 on 01/12/26.
//

import Foundation

struct VideoUploadProgress: Hashable {
    let phase: Phase
    let progress: Double  // 0.0 ~ 1.0

    enum Phase: Hashable {
        case preparing           // 준비 중
        case thumbnailGenerating // 썸네일 생성 중
        case thumbnailUploading  // 썸네일 업로드 중
        case compressing         // 비디오 압축 중
        case videoUploading      // 비디오 업로드 중
        case completed           // 완료
        case failed(String)      // 실패 (에러 메시지)
    }

    var percentage: Int {
        Int(progress * 100)
    }

    var displayText: String {
        switch phase {
        case .preparing:
            return "준비 중..."
        case .thumbnailGenerating:
            return "썸네일 생성 중..."
        case .thumbnailUploading:
            return "썸네일 업로드 중... \(percentage)%"
        case .compressing:
            return "비디오 압축 중... \(percentage)%"
        case .videoUploading:
            return "비디오 업로드 중... \(percentage)%"
        case .completed:
            return "완료"
        case .failed:
            return "실패"
        }
    }
}
