//
//  VideoPlayerGestureView.swift
//  KickIn
//
//  Created by 서준일 on 01/10/26.
//

import SwiftUI
import OSLog

struct VideoPlayerGestureView: View {
    let geometry: GeometryProxy
    @Binding var seekFeedback: SeekFeedback?
    let onSeekTap: (SeekDirection) -> Void
    let onSeekEnd: () -> Void
    let onLongPressStart: () -> Void
    let onLongPressEnd: () -> Void
    let onCenterTap: () -> Void

    @State private var isLongPressing = false
    @State private var accumulatedSeek: Int = 0
    @State private var tapCount: Int = 0
    @State private var currentDirection: SeekDirection?
    @State private var longPressTimer: Timer?
    @State private var touchStartTime: Date?
    @State private var touchStartLocation: CGPoint?
    @State private var seekWorkItem: DispatchWorkItem?

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleTouchBegan(at: value.location)
                    }
                    .onEnded { value in
                        handleTouchEnded(at: value.location)
                    }
            )
    }

    private func handleTouchBegan(at location: CGPoint) {
        // 이미 터치가 시작된 경우 무시
        guard touchStartTime == nil else { return }

        touchStartTime = Date()
        touchStartLocation = location

        Logger.network.debug("👆 Touch began at: \(location.x), \(location.y)")

        // 0.5초 후 롱프레스 판단
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            if touchStartTime != nil {
                Logger.network.debug("⏱️ Long press detected!")
                isLongPressing = true
                onLongPressStart()
            }
        }
    }

    private func handleTouchEnded(at location: CGPoint) {
        guard let startTime = touchStartTime,
              let startLocation = touchStartLocation else { return }

        let duration = Date().timeIntervalSince(startTime)
        Logger.network.debug("👇 Touch ended. Duration: \(duration)s at: \(location.x), \(location.y)")

        // 타이머 취소
        longPressTimer?.invalidate()
        longPressTimer = nil

        // 롱프레스 중이었다면
        if isLongPressing {
            Logger.network.debug("🔄 Ending long press")
            isLongPressing = false
            onLongPressEnd()
        } else {
            // 짧은 탭 - 영역 판단
            let zone = getTapZone(for: startLocation)
            Logger.network.debug("🎯 Tap zone: \(zone)")

            switch zone {
            case .left:
                handleSeekTap(.backward)
            case .center:
                onCenterTap()
            case .right:
                handleSeekTap(.forward)
            }
        }

        // 리셋
        touchStartTime = nil
        touchStartLocation = nil
    }

    private func getTapZone(for location: CGPoint) -> TapZone {
        let width = geometry.size.width
        let x = location.x

        if x < width * 0.3 {
            return .left
        } else if x > width * 0.7 {
            return .right
        } else {
            return .center
        }
    }

    private func handleSeekTap(_ direction: SeekDirection) {
        // 기존 작업 취소
        seekWorkItem?.cancel()

        // 방향이 바뀌면 리셋
        if let current = currentDirection, current != direction {
            Logger.network.debug("🔄 Direction changed, resetting")
            tapCount = 0
            accumulatedSeek = 0
        }

        currentDirection = direction
        tapCount += 1

        Logger.network.debug("👆 Tap #\(tapCount) - Direction: \(direction == .forward ? "forward" : "backward")")

        // 첫 번째 탭은 누적하지 않음
        if tapCount == 1 {
            Logger.network.debug("🚫 First tap - waiting for double tap")
            // 1초 후 리셋
            let workItem = DispatchWorkItem { [self] in
                Logger.network.debug("⏱️ Timer expired - only 1 tap, ignoring")
                self.tapCount = 0
                self.accumulatedSeek = 0
                self.currentDirection = nil
            }
            seekWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
            return
        }

        // 두 번째 탭부터 누적
        let delta = direction == .forward ? 5 : -5
        let previousAccumulated = accumulatedSeek
        accumulatedSeek += delta

        Logger.network.debug("⏩ Accumulating seek - Previous: \(previousAccumulated)s → New: \(accumulatedSeek)s")

        // 피드백 업데이트
        seekFeedback = SeekFeedback(
            direction: direction,
            accumulatedSeconds: abs(accumulatedSeek)
        )

        // 1초 후 자동 적용
        Logger.network.debug("⏱️ Starting 1-second timer for auto-apply")
        let workItem = DispatchWorkItem { [self] in
            Logger.network.debug("✅ Timer fired! TapCount: \(self.tapCount), Accumulated: \(self.accumulatedSeek)s")

            guard self.tapCount >= 2 else {
                Logger.network.debug("⚠️ Less than 2 taps, ignoring")
                self.tapCount = 0
                self.accumulatedSeek = 0
                self.currentDirection = nil
                return
            }

            guard self.accumulatedSeek != 0 else {
                Logger.network.debug("⚠️ No seek to apply")
                self.tapCount = 0
                self.accumulatedSeek = 0
                self.currentDirection = nil
                return
            }

            self.onSeekEnd()
            self.tapCount = 0
            self.accumulatedSeek = 0
            self.currentDirection = nil

            // 0.5초 후 피드백 제거
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Logger.network.debug("🔄 Clearing seek feedback UI")
                self.seekFeedback = nil
            }
        }

        seekWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)

        // 콜백 호출
        onSeekTap(direction)
    }
}

private enum TapZone: CustomStringConvertible {
    case left, center, right

    var description: String {
        switch self {
        case .left: return "left"
        case .center: return "center"
        case .right: return "right"
        }
    }
}
