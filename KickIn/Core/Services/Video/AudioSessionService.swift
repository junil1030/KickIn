//
//  AudioSessionService.swift
//  KickIn
//
//  Created by 서준일 on 01/17/26.
//

import AVFoundation
import OSLog

/// 백그라운드 오디오 재생 및 PIP를 위한 AVAudioSession 관리 서비스
final class AudioSessionService {

    // MARK: - Singleton

    static let shared = AudioSessionService()

    // MARK: - Properties

    private var isConfigured = false
    private var interruptionObserver: NSObjectProtocol?

    // MARK: - Initialization

    private init() {
        setupInterruptionObserver()
    }

    deinit {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public Methods

    /// 백그라운드 재생을 위한 AVAudioSession 구성
    func configureForPlayback() throws {
        guard !isConfigured else {
            Logger.network.info("🔊 AudioSession already configured")
            return
        }

        let audioSession = AVAudioSession.sharedInstance()

        do {
            // .playback 카테고리: 백그라운드 재생, PIP 지원
            // .moviePlayback은 deprecated되어 .playback + .video 사용
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [])
            try audioSession.setActive(true)

            isConfigured = true
            Logger.network.info("✅ AudioSession configured for playback")
        } catch {
            Logger.network.error("❌ AudioSession configuration failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// AVAudioSession 비활성화
    func deactivateSession() {
        guard isConfigured else { return }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            isConfigured = false
            Logger.network.info("✅ AudioSession deactivated")
        } catch {
            Logger.network.error("❌ AudioSession deactivation failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    /// 오디오 인터럽션(전화 등) 옵저버 설정
    private func setupInterruptionObserver() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification: notification)
        }
    }

    /// 오디오 인터럽션 처리
    private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            Logger.network.info("🔕 AudioSession interruption began (e.g., phone call)")
            // 비디오 플레이어가 자동으로 일시정지됨

        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }

            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                Logger.network.info("🔔 AudioSession interruption ended - should resume")
                // 비디오 플레이어가 재생 재개를 결정
            } else {
                Logger.network.info("🔔 AudioSession interruption ended - no auto resume")
            }

        @unknown default:
            Logger.network.warning("⚠️ Unknown AudioSession interruption type")
        }
    }
}
