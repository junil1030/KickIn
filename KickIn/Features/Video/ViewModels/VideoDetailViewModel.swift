//
//  VideoDetailViewModel.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import Foundation
import Combine
import AVFoundation
import UIKit
import OSLog

final class VideoDetailViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var streamInfo: VideoStreamResponseDTO?
    @Published var subtitleCues: [VideoSubtitleCue] = []
    @Published var selectedSubtitle: VideoStreamSubtitleDTO?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var playerState = VideoPlayerState()
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    private let tokenStorage = NetworkServiceFactory.shared.getTokenStorage()
    private let audioSessionService = AudioSessionService.shared
    private let videoId: String
    private var playerStatusObserver: NSKeyValueObservation?
    private var resourceLoaderDelegate: HLSResourceLoaderDelegate?
    private let resourceLoaderQueue = DispatchQueue(label: "hls.resource.loader")
    private var qualitySwitchTask: Task<Void, Never>?
    private var overlayHideTimer: Timer?
    private var backgroundObserver: NSObjectProtocol?

    weak var playerContainerView: VideoPlayerContainerView?

    init(videoId: String) {
        self.videoId = videoId
        setupBackgroundObserver()
    }

    deinit {
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func setPlayer(with url: URL) async {
#if DEBUG
        await logPlaylistHead(url)
#endif

        // 백그라운드 재생을 위한 오디오 세션 구성
        do {
            try audioSessionService.configureForPlayback()
        } catch {
            Logger.network.error("❌ Failed to configure audio session: \(error.localizedDescription)")
        }

        let item: AVPlayerItem

        if let customAsset = makeCustomAsset(from: url) {
            item = AVPlayerItem(asset: customAsset)
        } else {
            item = AVPlayerItem(url: url)
        }

        playerStatusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            switch item.status {
            case .readyToPlay:
                Logger.network.info("✅ Player ready to play")
            case .failed:
                let message = item.error?.localizedDescription ?? "unknown error"
                Logger.network.error("❌ Player failed: \(message)")
                if let log = item.errorLog()?.events.last?.errorComment {
                    Logger.network.error("❌ Player error log: \(log)")
                }
                self?.errorMessage = "영상을 재생할 수 없습니다."
            case .unknown:
                Logger.network.debug("ℹ️ Player status unknown")
            @unknown default:
                Logger.network.debug("ℹ️ Player status default")
            }
        }

        await MainActor.run {
            let newPlayer = AVPlayer(playerItem: item)
            self.player = newPlayer
            newPlayer.play()
        }
    }

    func stopPlayer() {
        // PIP 중지
        playerContainerView?.stopPictureInPicture()

        player?.pause()
        player = nil
        playerStatusObserver = nil
        resourceLoaderDelegate = nil
        qualitySwitchTask?.cancel()
        qualitySwitchTask = nil
        overlayHideTimer?.invalidate()
        overlayHideTimer = nil

        // 오디오 세션 비활성화
        audioSessionService.deactivateSession()
    }

    func loadStream() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let response: VideoStreamResponseDTO = try await networkService.request(
                VideoRouter.getStream(videoId: videoId)
            )

            await MainActor.run {
                self.streamInfo = response
                self.isLoading = false
            }

            Logger.network.info("✅ Loaded stream info for video: \(self.videoId)")
        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to load stream info: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        } catch {
            Logger.network.error("❌ Unknown error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "스트리밍 정보를 불러오는데 실패했습니다."
                self.isLoading = false
            }
        }
    }

    func loadDefaultSubtitleIfNeeded() async {
        let token = streamToken(from: streamInfo)
        let defaultSubtitle = streamInfo?.subtitles?.first(where: { $0.isDefault == true })
            ?? streamInfo?.subtitles?.first
        await selectSubtitle(defaultSubtitle, token: token)
    }

    func selectSubtitle(_ subtitle: VideoStreamSubtitleDTO?, token: String?) async {
        guard let subtitle = subtitle else {
            await MainActor.run {
                self.subtitleCues = []
                self.selectedSubtitle = nil
            }
            return
        }

        guard let urlString = subtitle.url,
              let url = resolvedSubtitleURL(from: urlString, token: token) else {
            await MainActor.run {
                self.subtitleCues = []
                self.selectedSubtitle = subtitle
            }
            return
        }

        await MainActor.run {
            self.subtitleCues = []
            self.selectedSubtitle = subtitle
        }

        do {
            let vttText = try await fetchSubtitleText(from: url)
            let cues = parseWebVTT(vttText)
            await MainActor.run {
                self.subtitleCues = cues
            }
        } catch {
            await MainActor.run {
                self.subtitleCues = []
            }
            Logger.network.error("❌ Failed to load subtitle: \(error.localizedDescription)")
        }
    }

    // MARK: - Player Controls

    func seek(by offset: TimeInterval) {
        guard let player = player else {
            Logger.network.debug("⚠️ ViewModel: No player to seek")
            return
        }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: offset, preferredTimescale: 600))
        Logger.network.debug("🎯 ViewModel: Seeking by \(offset)s - from \(currentTime.seconds)s to \(newTime.seconds)s")
        player.seek(to: newTime)
    }

    func seek(to time: TimeInterval) {
        guard let player = player else {
            Logger.network.debug("⚠️ ViewModel: No player to seek")
            return
        }
        Logger.network.debug("🎯 ViewModel: Seeking to \(time)s")
        player.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }

    func setPlaybackSpeed(_ rate: Float) {
        guard let player = player else {
            Logger.network.debug("⚠️ ViewModel: No player to set speed")
            return
        }
        Logger.network.debug("⚡️ ViewModel: Setting playback speed to \(rate)x")
        player.rate = rate
    }

    func switchQuality(to quality: VideoStreamQualityDTO) async {
        // 기존 작업 취소 (디바운싱)
        qualitySwitchTask?.cancel()

        // 새 작업 생성
        qualitySwitchTask = Task {
            // 0.5초 대기 (디바운싱)
            try? await Task.sleep(nanoseconds: 500_000_000)

            // 취소되었으면 중단
            guard !Task.isCancelled else {
                Logger.network.debug("⚠️ Quality switch cancelled")
                return
            }

            guard let qualityUrl = quality.url,
                  let url = resolvedStreamURL(from: qualityUrl) else { return }

            Logger.network.debug("🎬 Switching quality to: \(quality.quality ?? "unknown")")

            // 현재 재생 위치와 상태 저장
            let savedTime = player?.currentTime().seconds ?? 0
            let wasPlaying = playerState.isPlaying

            // 새 URL로 플레이어 재설정
            await setPlayer(with: url)

            // 이전 위치로 seek
            await MainActor.run {
                player?.seek(to: CMTime(seconds: savedTime, preferredTimescale: 600))
                if wasPlaying {
                    player?.play()
                }
                playerState.selectedQuality = quality
                playerState.showQualityMenu = false
            }
        }

        await qualitySwitchTask?.value
    }

    func toggleFullscreen() {
        playerState.isFullscreen.toggle()
    }

    func toggleSubtitleVisibility() {
        playerState.isSubtitleVisible.toggle()
    }

    func showOverlayTemporarily() {
        playerState.showOverlay = true
        startOverlayHideTimer()
    }

    func resetOverlayTimer() {
        // 재생 중일 때만 타이머 시작
        if playerState.isPlaying {
            startOverlayHideTimer()
        }
    }

    private func startOverlayHideTimer() {
        // 기존 타이머 취소
        overlayHideTimer?.invalidate()

        // 재생 중일 때만 3초 후 자동 숨김
        guard playerState.isPlaying else { return }

        overlayHideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            // 재생 중이고, 화질 메뉴가 열려있지 않을 때만 숨김
            if self.playerState.isPlaying && !self.playerState.showQualityMenu {
                self.playerState.showOverlay = false
            }
        }
    }

    func cancelOverlayTimer() {
        overlayHideTimer?.invalidate()
        overlayHideTimer = nil
    }

    private func fetchSubtitleText(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(APIConfig.apikey, forHTTPHeaderField: "SeSACKey")
        if let accessToken = await tokenStorage.getAccessToken() {
            request.setValue(accessToken, forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        return String(decoding: data, as: UTF8.self)
    }

    private func resolvedSubtitleURL(from path: String, token: String?) -> URL? {
        let resolvedURL: URL?
        if path.hasPrefix("http") {
            resolvedURL = URL(string: path)
        } else {
            resolvedURL = URL(string: APIConfig.baseURL + path)
        }

        guard let resolvedURL else { return nil }
        guard let token else { return resolvedURL }

        var components = URLComponents(url: resolvedURL, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        if !queryItems.contains(where: { $0.name == "token" }) {
            queryItems.append(URLQueryItem(name: "token", value: token))
        }
        components?.queryItems = queryItems
        return components?.url ?? resolvedURL
    }

    private func parseWebVTT(_ text: String) -> [VideoSubtitleCue] {
        var cues: [VideoSubtitleCue] = []
        let lines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")

        var index = 0
        while index < lines.count {
            let line = lines[index].trimmingCharacters(in: .whitespaces)

            if line.isEmpty || line == "WEBVTT" || line.allSatisfy({ $0.isNumber }) {
                index += 1
                continue
            }

            if line.contains("-->") {
                let parts = line.components(separatedBy: " --> ")
                guard parts.count >= 2,
                      let start = parseTimecode(parts[0]) else {
                    index += 1
                    continue
                }

                let endPart = parts[1].components(separatedBy: " ").first ?? parts[1]
                guard let end = parseTimecode(endPart) else {
                    index += 1
                    continue
                }

                index += 1
                var textLines: [String] = []
                while index < lines.count {
                    let subtitleLine = lines[index]
                    if subtitleLine.trimmingCharacters(in: .whitespaces).isEmpty {
                        break
                    }
                    textLines.append(subtitleLine)
                    index += 1
                }

                let cueText = textLines.joined(separator: "\n")
                if !cueText.isEmpty {
                    cues.append(VideoSubtitleCue(startTime: start, endTime: end, text: cueText))
                }
            } else {
                index += 1
            }
        }

        return cues
    }

    private func parseTimecode(_ timeString: String) -> TimeInterval? {
        let clean = timeString.trimmingCharacters(in: .whitespaces)
        let parts = clean.components(separatedBy: ":")

        if parts.count == 3 {
            guard let hours = Double(parts[0]),
                  let minutes = Double(parts[1]),
                  let seconds = Double(parts[2].replacingOccurrences(of: ",", with: ".")) else {
                return nil
            }
            return hours * 3600 + minutes * 60 + seconds
        }

        if parts.count == 2 {
            guard let minutes = Double(parts[0]),
                  let seconds = Double(parts[1].replacingOccurrences(of: ",", with: ".")) else {
                return nil
            }
            return minutes * 60 + seconds
        }

        return nil
    }

    private func streamToken(from info: VideoStreamResponseDTO?) -> String? {
        guard let path = info?.streamUrl ?? info?.qualities?.first?.url,
              let url = resolvedStreamURL(from: path) else {
            return nil
        }
        return tokenValue(from: url)
    }

    private func resolvedStreamURL(from streamPath: String) -> URL? {
        if streamPath.hasPrefix("http") {
            return URL(string: streamPath)
        }
        return URL(string: APIConfig.baseURL + streamPath)
    }

    private func tokenValue(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "token" })?
            .value
    }

    private func makeCustomAsset(from url: URL) -> AVURLAsset? {
        guard let token = tokenValue(from: url),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }

        components.scheme = "myhls"
        guard let customURL = components.url else { return nil }

        let asset = AVURLAsset(url: customURL)
        let delegate = HLSResourceLoaderDelegate(authToken: token)
        resourceLoaderDelegate = delegate
        asset.resourceLoader.setDelegate(delegate, queue: resourceLoaderQueue)
        return asset
    }

    private func logPlaylistHead(_ url: URL) async {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let text = String(decoding: data, as: UTF8.self)
            let preview = text
                .components(separatedBy: "\n")
                .prefix(8)
                .joined(separator: "\n")
            Logger.network.debug("🎬 Playlist status: \(statusCode)")
            Logger.network.debug("🎬 Playlist head:\n\(preview)")
        } catch {
            Logger.network.error("❌ Playlist fetch failed: \(error.localizedDescription)")
        }
    }

    // MARK: - PIP Control

    func startPictureInPicture() {
        playerContainerView?.startPictureInPicture()
    }

    func stopPictureInPicture() {
        playerContainerView?.stopPictureInPicture()
    }

    func togglePictureInPicture() {
        if playerState.isPictureInPictureActive {
            stopPictureInPicture()
        } else {
            startPictureInPicture()
        }
    }

    // MARK: - Background Observer

    private func setupBackgroundObserver() {
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidEnterBackground()
        }
    }

    private func handleAppDidEnterBackground() {
        Logger.network.info("📱 App entered background - checking PIP conditions")
        Logger.network.info("  - isPlaying: \(self.playerState.isPlaying)")
        Logger.network.info("  - isPictureInPicturePossible: \(self.playerState.isPictureInPicturePossible)")
        Logger.network.info("  - isPictureInPictureActive: \(self.playerState.isPictureInPictureActive)")
        Logger.network.info("  - player exists: \(self.player != nil)")
        Logger.network.info("  - playerContainerView exists: \(self.playerContainerView != nil)")

        // 비디오 재생 중이고, PIP 가능하며, 아직 PIP 모드가 아닐 때 자동으로 PIP 시작
        guard playerState.isPlaying else {
            Logger.network.warning("⚠️ Cannot auto-start PIP: video not playing")
            return
        }

        guard playerState.isPictureInPicturePossible else {
            Logger.network.warning("⚠️ Cannot auto-start PIP: PIP not possible")
            return
        }

        guard !playerState.isPictureInPictureActive else {
            Logger.network.info("ℹ️ PIP already active, skipping auto-start")
            return
        }

        Logger.network.info("📱 Auto-starting PIP due to backgrounding")

        // 백그라운드 전환 시 약간의 딜레이를 주어 안정적으로 PIP 시작
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.startPictureInPicture()
        }
    }
}

// MARK: - PIPControllerDelegate

extension VideoDetailViewModel: PIPControllerDelegate {

    func pipWillStart() {
        Logger.network.info("🎬 ViewModel: PIP will start")
    }

    func pipDidStart() {
        Logger.network.info("✅ ViewModel: PIP started")
        playerState.isPictureInPictureActive = true
        playerState.showOverlay = false
    }

    func pipWillStop() {
        Logger.network.info("🎬 ViewModel: PIP will stop")
    }

    func pipDidStop() {
        Logger.network.info("✅ ViewModel: PIP stopped")
        playerState.isPictureInPictureActive = false
        showOverlayTemporarily()
    }

    func pipPossibilityChanged(_ isPossible: Bool) {
        Logger.network.info("🔄 ViewModel: PIP possibility changed to \(isPossible)")
        playerState.isPictureInPicturePossible = isPossible
    }
}
