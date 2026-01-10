//
//  VideoPlayerState.swift
//  KickIn
//
//  Created by 서준일 on 01/10/26.
//

import Foundation

struct VideoPlayerState {
    var isPlaying: Bool = true
    var isFullscreen: Bool = false
    var isSubtitleVisible: Bool = true
    var selectedQuality: VideoStreamQualityDTO? = nil
    var showQualityMenu: Bool = false
    var isLongPressing: Bool = false
    var seekFeedback: SeekFeedback? = nil
}

struct SeekFeedback {
    var direction: SeekDirection
    var accumulatedSeconds: Int
}

enum SeekDirection {
    case forward, backward
}
