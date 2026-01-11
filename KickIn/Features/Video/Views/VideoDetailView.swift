//
//  VideoDetailView.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import SwiftUI
import AVFoundation
import OSLog
import CachingKit

struct VideoDetailView: View {
    @Environment(\.cachingKit) private var cachingKit
    @StateObject private var viewModel: VideoDetailViewModel
    @State private var timeObserver: Any?
    @State private var currentSubtitle: String = ""
    @State private var isPlaying = true
    @State private var currentTime: TimeInterval = 0

    private let video: VideoUIModel

    init(video: VideoUIModel) {
        self.video = video
        _viewModel = StateObject(wrappedValue: VideoDetailViewModel(videoId: video.videoId ?? ""))
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                playerSection

                titleSection

                // 자막 리스트
                if !viewModel.subtitleCues.isEmpty {
                    SubtitleListView(
                        subtitleCues: viewModel.subtitleCues,
                        currentTime: currentTime,
                        onSubtitleTap: { cue in
                            viewModel.seek(to: cue.startTime)
                        }
                    )
                    .padding(.horizontal, 16)
                }

                subtitleSection

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption1(.pretendardMedium))
                        .foregroundStyle(Color.gray60)
                        .padding(.horizontal, 16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 24)
        }
        .defaultBackground()
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $viewModel.playerState.isFullscreen) {
            VideoPlayerFullscreenView(
                viewModel: viewModel,
                isFullscreen: $viewModel.playerState.isFullscreen,
                isPlaying: $isPlaying,
                currentSubtitle: $currentSubtitle,
                currentTime: $currentTime
            )
        }
        .task {
            await viewModel.loadStream()
        }
        .onChange(of: streamPathKey) { _, newValue in
            guard !newValue.isEmpty,
                  let url = resolvedStreamURL(from: newValue) else { return }
            Task {
                await viewModel.loadDefaultSubtitleIfNeeded()
                await setPlayer(with: url)
            }
        }
        .onChange(of: viewModel.subtitleCues.count) { _, _ in
            updateSubtitleObserver()
        }
        .onDisappear {
            cleanupObserver()
            viewModel.stopPlayer()
        }
    }

    private var playerSection: some View {
        ZStack {
            if let player = viewModel.player {
                GeometryReader { geometry in
                    ZStack {
                        VideoPlayerContainerRepresentable(player: player)
                            .aspectRatio(16 / 9, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VideoPlayerGestureView(
                            geometry: geometry,
                            seekFeedback: $viewModel.playerState.seekFeedback,
                            onSeekTap: handleSeekTap,
                            onSeekEnd: applySeekOffset,
                            onLongPressStart: startFastPlayback,
                            onLongPressEnd: endFastPlayback,
                            onOverlayToggle: toggleOverlay
                        )

                        if viewModel.playerState.showOverlay {
                            VideoPlayerOverlayView(
                                playerState: $viewModel.playerState,
                                qualities: viewModel.streamInfo?.qualities ?? [],
                                currentTime: currentTime,
                                duration: viewModel.player?.currentItem?.duration.seconds ?? 0,
                                onPlayPauseTap: togglePlayback,
                                onFullscreenTap: {
                                    viewModel.toggleFullscreen()
                                },
                                onCaptionTap: {
                                    viewModel.toggleSubtitleVisibility()
                                },
                                onQualitySelect: { quality in
                                    Task {
                                        await viewModel.switchQuality(to: quality)
                                    }
                                },
                                onSeek: { time in
                                    viewModel.seek(to: time)
                                }
                            )
                        }

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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .aspectRatio(16 / 9, contentMode: .fit)
                .padding(.horizontal, 16)
            } else {
                CachedAsyncImage(
                    url: getThumbnailURL(from: video.thumbnailUrl),
                    targetSize: CGSize(width: 800, height: 450),
                    cachingKit: cachingKit
                ) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray90)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                        .overlay {
                            if viewModel.isLoading {
                                ProgressView()
                            }
                        }
                }
            }
        }
        .padding(.top, 8)
    }

    private var titleSection: some View {
        Text(video.title ?? "제목 없음")
            .font(.title1(.pretendardBold))
            .foregroundStyle(Color.gray90)
            .padding(.horizontal, 16)
    }

    private var subtitleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("자막")
                .font(.body2(.pretendardBold))
                .foregroundStyle(Color.gray75)

            if let subtitles = viewModel.streamInfo?.subtitles, !subtitles.isEmpty {
                ForEach(subtitles.indices, id: \.self) { index in
                    subtitleRow(subtitles[index])
                }
            } else {
                Text("제공되는 자막이 없습니다.")
                    .font(.caption1(.pretendardMedium))
                    .foregroundStyle(Color.gray60)
            }
        }
        .padding(.horizontal, 16)
    }

    private var streamPathKey: String {
        selectedStreamPath(from: viewModel.streamInfo) ?? ""
    }

    private func subtitleRow(_ subtitle: VideoStreamSubtitleDTO) -> some View {
        HStack(spacing: 8) {
            Text(subtitle.name ?? subtitle.language ?? "자막")
                .font(.caption1(.pretendardMedium))
                .foregroundStyle(Color.gray90)

            if subtitle.isDefault == true {
                Text("기본")
                    .font(.caption3())
                    .foregroundStyle(Color.gray0)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.deepCoast)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private func getThumbnailURL(from thumbnail: String?) -> URL? {
        guard let thumbnail = thumbnail else { return nil }
        let urlString = APIConfig.baseURL + thumbnail
        return URL(string: urlString)
    }

    private func resolvedStreamURL(from streamPath: String?) -> URL? {
        guard let streamPath = streamPath else { return nil }
        if streamPath.hasPrefix("http") {
            return URL(string: streamPath)
        }
        return URL(string: APIConfig.baseURL + streamPath)
    }

    private func selectedStreamPath(from info: VideoStreamResponseDTO?) -> String? {
        if let streamUrl = info?.streamUrl {
            return streamUrl
        }
        return info?.qualities?.first?.url
    }

    private func setPlayer(with url: URL) async {
        await MainActor.run {
            cleanupObserver()
        }
        Logger.network.debug("🎬 Stream URL: \(url.absoluteString)")
        await viewModel.setPlayer(with: url)
        await MainActor.run {
            isPlaying = true
        }
        await MainActor.run {
            startSubtitleObserverIfNeeded()
        }
    }

    private func cleanupObserver() {
        if let player = viewModel.player, let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
    }

    private func startSubtitleObserverIfNeeded() {
        guard timeObserver == nil,
              let player = viewModel.player,
              !viewModel.subtitleCues.isEmpty else { return }

        let interval = CMTime(seconds: 0.2, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentSubtitle = subtitleText(at: time.seconds)
            currentTime = time.seconds
        }
    }

    private func updateSubtitleObserver() {
        if viewModel.subtitleCues.isEmpty {
            currentSubtitle = ""
            if let player = viewModel.player, let timeObserver {
                player.removeTimeObserver(timeObserver)
            }
            timeObserver = nil
            return
        }
        startSubtitleObserverIfNeeded()
    }

    private func subtitleText(at time: TimeInterval) -> String {
        for cue in viewModel.subtitleCues {
            if time >= cue.startTime && time <= cue.endTime {
                return cue.text
            }
        }
        return ""
    }

    private func togglePlayback() {
        guard let player = viewModel.player else { return }
        Logger.network.debug("▶️ VideoDetailView: Toggle playback - isPlaying: \(isPlaying)")
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        viewModel.playerState.isPlaying = isPlaying
    }

    private func toggleOverlay() {
        Logger.network.debug("👁️ VideoDetailView: Toggle overlay")
        viewModel.playerState.showOverlay.toggle()
    }

    // MARK: - Gesture Handlers

    private func handleSeekTap(_ direction: SeekDirection) {
        // 누적된 시크 값은 VideoPlayerGestureView에서 관리
        // 여기서는 별도 처리 불필요
        Logger.network.debug("🎬 VideoDetailView: handleSeekTap called")
    }

    private func applySeekOffset() {
        guard let feedback = viewModel.playerState.seekFeedback else {
            Logger.network.debug("⚠️ VideoDetailView: No feedback to apply")
            return
        }
        let offset = TimeInterval(feedback.accumulatedSeconds) * (feedback.direction == .forward ? 1 : -1)
        Logger.network.debug("🎬 VideoDetailView: Applying seek offset: \(offset)s")
        viewModel.seek(by: offset)
    }

    private func startFastPlayback() {
        Logger.network.debug("⚡️ VideoDetailView: Starting fast playback (2x)")
        viewModel.playerState.isLongPressing = true
        viewModel.setPlaybackSpeed(2.0)
    }

    private func endFastPlayback() {
        Logger.network.debug("⚡️ VideoDetailView: Ending fast playback")
        viewModel.playerState.isLongPressing = false
        viewModel.setPlaybackSpeed(isPlaying ? 1.0 : 0.0)
    }

}

#Preview {
    NavigationStack {
        VideoDetailView(
            video: VideoUIModel(
                videoId: "123",
                title: "대로변 코너 상가 매물 소개",
                thumbnailUrl: "/data/videos/estate_video_5.jpg",
                duration: 331.58,
                isLiked: false,
                viewCount: 190
            )
        )
    }
}
