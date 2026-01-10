//
//  VideoPlayerFullscreenView.swift
//  KickIn
//
//  Created by 서준일 on 01/10/26.
//

import SwiftUI
import AVFoundation
import OSLog

struct VideoPlayerFullscreenView: View {
    @ObservedObject var viewModel: VideoDetailViewModel
    @Binding var isFullscreen: Bool
    @Binding var isPlaying: Bool
    @Binding var currentSubtitle: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = viewModel.player {
                GeometryReader { geometry in
                    ZStack {
                        VideoPlayerContainerRepresentable(player: player)
                            .ignoresSafeArea()

                        VideoPlayerGestureView(
                            geometry: geometry,
                            seekFeedback: $viewModel.playerState.seekFeedback,
                            onSeekTap: handleSeekTap,
                            onSeekEnd: applySeekOffset,
                            onLongPressStart: startFastPlayback,
                            onLongPressEnd: endFastPlayback,
                            onCenterTap: togglePlayback
                        )

                        VideoPlayerOverlayView(
                            playerState: $viewModel.playerState,
                            qualities: viewModel.streamInfo?.qualities ?? [],
                            onPlayPauseTap: togglePlayback,
                            onFullscreenTap: {
                                exitFullscreen()
                            },
                            onCaptionTap: {
                                viewModel.toggleSubtitleVisibility()
                            },
                            onQualitySelect: { quality in
                                Task {
                                    await viewModel.switchQuality(to: quality)
                                }
                            }
                        )

                        // 시크 피드백 표시
                        if let feedback = viewModel.playerState.seekFeedback {
                            SeekFeedbackView(feedback: feedback)
                        }

                        // 2배속 인디케이터
                        if viewModel.playerState.isLongPressing {
                            VStack {
                                HStack {
                                    Spacer()
                                    SpeedIndicatorView()
                                        .padding(.trailing, 16)
                                        .padding(.top, 16)
                                }
                                Spacer()
                            }
                        }

                        // 자막 오버레이
                        VStack {
                            Spacer()
                            if viewModel.playerState.isSubtitleVisible && !currentSubtitle.isEmpty {
                                Text(currentSubtitle)
                                    .font(.caption1(.pretendardMedium))
                                    .foregroundStyle(Color.gray0)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .padding(.horizontal, 24)
                                    .padding(.bottom, 12)
                            }
                        }
                    }
                }
            }
        }
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            setOrientation(.landscapeRight)
        }
        .onDisappear {
            setOrientation(.portrait)
        }
    }

    private func setOrientation(_ orientation: UIInterfaceOrientation) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }

        let geometryPreferences: UIWindowScene.GeometryPreferences
        switch orientation {
        case .landscapeRight:
            geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeRight)
        case .landscapeLeft:
            geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeLeft)
        case .portrait:
            geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
        default:
            geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
        }

        windowScene.requestGeometryUpdate(geometryPreferences) { error in
            Logger.network.error("❌ Failed to update geometry: \(error.localizedDescription)")
        }
    }

    private func exitFullscreen() {
        isFullscreen = false
        viewModel.playerState.isFullscreen = false
    }

    private func togglePlayback() {
        guard let player = viewModel.player else { return }
        Logger.network.debug("▶️ FullscreenView: Toggle playback - isPlaying: \(isPlaying)")
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        viewModel.playerState.isPlaying = isPlaying
    }

    // MARK: - Gesture Handlers

    private func handleSeekTap(_ direction: SeekDirection) {
        Logger.network.debug("🎬 FullscreenView: handleSeekTap called")
    }

    private func applySeekOffset() {
        guard let feedback = viewModel.playerState.seekFeedback else {
            Logger.network.debug("⚠️ FullscreenView: No feedback to apply")
            return
        }
        let offset = TimeInterval(feedback.accumulatedSeconds) * (feedback.direction == .forward ? 1 : -1)
        Logger.network.debug("🎬 FullscreenView: Applying seek offset: \(offset)s")
        viewModel.seek(by: offset)
    }

    private func startFastPlayback() {
        Logger.network.debug("⚡️ FullscreenView: Starting fast playback (2x)")
        viewModel.playerState.isLongPressing = true
        viewModel.setPlaybackSpeed(2.0)
    }

    private func endFastPlayback() {
        Logger.network.debug("⚡️ FullscreenView: Ending fast playback")
        viewModel.playerState.isLongPressing = false
        viewModel.setPlaybackSpeed(isPlaying ? 1.0 : 0.0)
    }
}
