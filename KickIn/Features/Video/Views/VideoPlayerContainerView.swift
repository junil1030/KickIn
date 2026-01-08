//
//  VideoPlayerContainerView.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import SwiftUI
import AVFoundation

final class VideoPlayerContainerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        playerLayer.videoGravity = .resizeAspect
    }
}

struct VideoPlayerContainerRepresentable: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> VideoPlayerContainerView {
        let view = VideoPlayerContainerView()
        view.player = player
        return view
    }

    func updateUIView(_ uiView: VideoPlayerContainerView, context: Context) {
        if uiView.player !== player {
            uiView.player = player
        }
    }
}
