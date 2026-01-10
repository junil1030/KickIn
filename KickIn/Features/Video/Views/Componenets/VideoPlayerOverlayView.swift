//
//  VideoPlayerOverlayView.swift
//  KickIn
//
//  Created by 서준일 on 01/09/26.
//

import SwiftUI

struct VideoPlayerOverlayView: View {
    let isPlaying: Bool
    let onPlayPauseTap: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            Button(action: onPlayPauseTap) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.gray0)
                    .padding(18)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
