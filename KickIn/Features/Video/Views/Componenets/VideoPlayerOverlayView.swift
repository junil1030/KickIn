//
//  VideoPlayerOverlayView.swift
//  KickIn
//
//  Created by 서준일 on 01/09/26.
//

import SwiftUI

struct VideoPlayerOverlayView: View {
    @Binding var playerState: VideoPlayerState
    let qualities: [VideoStreamQualityDTO]
    let onPlayPauseTap: () -> Void
    let onFullscreenTap: () -> Void
    let onCaptionTap: () -> Void
    let onQualitySelect: (VideoStreamQualityDTO) -> Void

    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            // 3단 레이아웃
            VStack {
                // Top bar: 화질 버튼
                HStack {
                    Spacer()
                    Button(action: toggleQualityMenu) {
                        Image(systemName: "gear")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.gray0)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                // Center: 재생/일시정지 버튼
                Button(action: onPlayPauseTap) {
                    Image(systemName: playerState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.gray0)
                        .padding(18)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                // Bottom bar: CC 버튼, 전체화면 버튼
                HStack {
                    Button(action: onCaptionTap) {
                        Image(systemName: playerState.isSubtitleVisible ? "captions.bubble.fill" : "captions.bubble")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(playerState.isSubtitleVisible ? Color.deepCoast : Color.gray0)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: onFullscreenTap) {
                        Image(systemName: playerState.isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.gray0)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            // 조건부 화질 메뉴
            if playerState.showQualityMenu {
                QualityMenuView(
                    qualities: qualities,
                    currentQuality: playerState.selectedQuality,
                    onSelect: { quality in
                        onQualitySelect(quality)
                    },
                    onDismiss: {
                        playerState.showQualityMenu = false
                    }
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func toggleQualityMenu() {
        playerState.showQualityMenu.toggle()
    }
}
