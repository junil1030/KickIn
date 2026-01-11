//
//  VideoPlayerProgressView.swift
//  KickIn
//
//  Created by 서준일 on 01/11/26.
//

import SwiftUI

struct VideoPlayerProgressView: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void

    @State private var isDragging = false
    @State private var draggedTime: TimeInterval = 0

    private let progressHeight: CGFloat = 4
    private let thumbSizeNormal: CGFloat = 12
    private let thumbSizeDragging: CGFloat = 16

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 배경 바 (회색)
                Capsule()
                    .fill(Color.gray60.opacity(0.5))
                    .frame(height: progressHeight)

                // 재생된 부분 (빨간색/파란색)
                Capsule()
                    .fill(Color.deepCoast)
                    .frame(width: progressWidth(in: geometry.size.width), height: progressHeight)

                // Thumb (항상 표시, 드래그 중 크기 증가)
                Circle()
                    .fill(Color.deepCoast)
                    .frame(width: currentThumbSize, height: currentThumbSize)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .offset(x: progressWidth(in: geometry.size.width) - currentThumbSize / 2)
                    .animation(.easeInOut(duration: 0.15), value: isDragging)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let newTime = timeFromPosition(value.location.x, width: geometry.size.width)
                        draggedTime = newTime
                    }
                    .onEnded { value in
                        isDragging = false
                        let newTime = timeFromPosition(value.location.x, width: geometry.size.width)
                        onSeek(newTime)
                    }
            )
        }
        .frame(height: max(progressHeight, thumbSizeDragging))
    }

    private var currentThumbSize: CGFloat {
        isDragging ? thumbSizeDragging : thumbSizeNormal
    }

    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        let time = isDragging ? draggedTime : currentTime
        guard duration > 0 && duration.isFinite && !duration.isNaN else { return 0 }
        guard time.isFinite && !time.isNaN else { return 0 }
        let progress = min(max(time / duration, 0), 1)
        return totalWidth * progress
    }

    private func timeFromPosition(_ position: CGFloat, width: CGFloat) -> TimeInterval {
        guard duration > 0 && duration.isFinite && !duration.isNaN else { return 0 }
        guard width > 0 else { return 0 }
        let progress = min(max(position / width, 0), 1)
        return duration * progress
    }
}

struct TimeTextView: View {
    let time: TimeInterval

    var body: some View {
        Text(formatTime(time))
            .font(.caption2(.pretendardMedium))
            .foregroundStyle(Color.gray0)
            .monospacedDigit()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        // NaN이나 infinite 값 처리
        guard time.isFinite && !time.isNaN else {
            return "0:00"
        }

        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
