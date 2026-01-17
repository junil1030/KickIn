//
//  VideoPlayerContainerView.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import SwiftUI
import AVFoundation
import AVKit
import OSLog

// MARK: - PIPControllerDelegate

/// PIP 상태 변경을 ViewModel에 전달하기 위한 프로토콜
protocol PIPControllerDelegate: AnyObject {
    func pipWillStart()
    func pipDidStart()
    func pipWillStop()
    func pipDidStop()
    func pipPossibilityChanged(_ isPossible: Bool)
}

// MARK: - VideoPlayerContainerView

final class VideoPlayerContainerView: UIView {

    // MARK: - Properties

    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    var player: AVPlayer? {
        get { playerLayer.player }
        set {
            playerLayer.player = newValue
            setupPictureInPicture()
        }
    }

    weak var pipDelegate: PIPControllerDelegate?

    private var pipController: AVPictureInPictureController?
    private var pipPossibleObserver: NSKeyValueObservation?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        playerLayer.videoGravity = .resizeAspect
    }

    deinit {
        pipPossibleObserver?.invalidate()
        pipController?.delegate = nil
    }

    // MARK: - PIP Setup

    /// AVPictureInPictureController 초기화 및 구성
    private func setupPictureInPicture() {
        Logger.network.debug("🔧 setupPictureInPicture called")

        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            Logger.network.warning("⚠️ PIP not supported on this device")
            pipDelegate?.pipPossibilityChanged(false)
            return
        }

        guard player != nil else {
            Logger.network.debug("⏸️ Player not set yet, skipping PIP setup")
            return
        }

        // 이미 설정되어 있으면 정리 후 재설정
        pipPossibleObserver?.invalidate()
        pipController?.delegate = nil

        // AVPictureInPictureController는 AVPlayerLayer 기반으로 생성
        pipController = AVPictureInPictureController(playerLayer: playerLayer)
        pipController?.delegate = self

        // 백그라운드 전환 시 자동으로 PIP 시작 (iOS 14.2+)
        if #available(iOS 14.2, *) {
            pipController?.canStartPictureInPictureAutomaticallyFromInline = true
            Logger.network.info("✅ Enabled automatic PIP on background")
        }

        Logger.network.info("✅ Created PIP controller, delegate: \(self.pipDelegate != nil ? "set" : "nil")")

        // PIP 가능 여부 KVO 관찰
        pipPossibleObserver = pipController?.observe(
            \.isPictureInPicturePossible,
             options: [.new, .initial]
        ) { [weak self] controller, change in
            guard let self = self, let isPossible = change.newValue else { return }
            Logger.network.info("🔄 PIP possibility changed to: \(isPossible)")
            DispatchQueue.main.async {
                self.pipDelegate?.pipPossibilityChanged(isPossible)
            }
        }

        Logger.network.info("✅ PIP controller setup completed")
    }

    // MARK: - Public Methods

    /// PIP 모드 시작
    func startPictureInPicture() {
        guard let pipController = pipController,
              pipController.isPictureInPicturePossible else {
            Logger.network.warning("⚠️ Cannot start PIP - not possible")
            return
        }

        guard !pipController.isPictureInPictureActive else {
            Logger.network.info("ℹ️ PIP already active")
            return
        }

        pipController.startPictureInPicture()
        Logger.network.info("🎬 Starting PIP...")
    }

    /// PIP 모드 중지
    func stopPictureInPicture() {
        guard let pipController = pipController,
              pipController.isPictureInPictureActive else {
            Logger.network.info("ℹ️ PIP not active, nothing to stop")
            return
        }

        pipController.stopPictureInPicture()
        Logger.network.info("🛑 Stopping PIP...")
    }
}

// MARK: - AVPictureInPictureControllerDelegate

extension VideoPlayerContainerView: AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Logger.network.info("🎬 PIP will start")
        DispatchQueue.main.async { [weak self] in
            self?.pipDelegate?.pipWillStart()
        }
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Logger.network.info("✅ PIP started")
        DispatchQueue.main.async { [weak self] in
            self?.pipDelegate?.pipDidStart()
        }
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Logger.network.info("🎬 PIP will stop")
        DispatchQueue.main.async { [weak self] in
            self?.pipDelegate?.pipWillStop()
        }
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Logger.network.info("✅ PIP stopped")
        DispatchQueue.main.async { [weak self] in
            self?.pipDelegate?.pipDidStop()
        }
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        Logger.network.error("❌ PIP failed to start: \(error.localizedDescription)")
        // 에러 발생 시 상태를 정리하기 위해 didStop 호출
        DispatchQueue.main.async { [weak self] in
            self?.pipDelegate?.pipDidStop()
        }
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        // PIP 창 복원 시 UI 복원 로직
        // 현재는 SwiftUI NavigationStack이 자동으로 처리
        Logger.network.info("🔄 PIP restore requested")
        completionHandler(true)
    }
}

// MARK: - VideoPlayerContainerRepresentable

struct VideoPlayerContainerRepresentable: UIViewRepresentable {
    let player: AVPlayer
    weak var pipDelegate: PIPControllerDelegate?
    var onViewCreated: ((VideoPlayerContainerView) -> Void)?

    func makeUIView(context: Context) -> VideoPlayerContainerView {
        let view = VideoPlayerContainerView()
        // pipDelegate를 먼저 설정해야 setupPictureInPicture에서 delegate를 찾을 수 있음
        view.pipDelegate = pipDelegate
        view.player = player
        onViewCreated?(view)
        return view
    }

    func updateUIView(_ uiView: VideoPlayerContainerView, context: Context) {
        // pipDelegate를 먼저 설정
        uiView.pipDelegate = pipDelegate

        if uiView.player !== player {
            uiView.player = player
        }
    }
}
