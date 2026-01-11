//
//  SubtitleListView.swift
//  KickIn
//
//  Created by 서준일 on 01/10/26.
//

import SwiftUI

struct SubtitleListView: View {
    let subtitleCues: [VideoSubtitleCue]
    let currentTime: TimeInterval
    let onSubtitleTap: (VideoSubtitleCue) -> Void

    @State private var autoScrollEnabled = true
    @State private var scrollTimer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("자막 목록")
                .font(.body2(.pretendardBold))
                .foregroundStyle(Color.gray75)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(subtitleCues.indices, id: \.self) { index in
                            SubtitleRowView(
                                cue: subtitleCues[index],
                                isActive: isCurrentSubtitle(subtitleCues[index]),
                                onTap: {
                                    onSubtitleTap(subtitleCues[index])
                                    // 자막 클릭 시 자동 스크롤 재활성화
                                    autoScrollEnabled = true
                                }
                            )
                            .id(index)
                        }
                    }
                }
                .frame(maxHeight: 300)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { _ in
                            // 사용자가 스크롤하면 자동 스크롤 비활성화
                            autoScrollEnabled = false

                            // 기존 타이머 취소
                            scrollTimer?.invalidate()

                            // 3초 후 재활성화
                            scrollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                autoScrollEnabled = true
                            }
                        }
                )
                .onChange(of: currentTime) { _, _ in
                    // 자동 스크롤이 활성화되어 있을 때만 실행
                    if autoScrollEnabled {
                        if let activeIndex = activeSubtitleIndex() {
                            withAnimation {
                                proxy.scrollTo(activeIndex, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .onDisappear {
            // 타이머 정리
            scrollTimer?.invalidate()
            scrollTimer = nil
        }
    }

    private func isCurrentSubtitle(_ cue: VideoSubtitleCue) -> Bool {
        currentTime >= cue.startTime && currentTime <= cue.endTime
    }

    private func activeSubtitleIndex() -> Int? {
        subtitleCues.firstIndex { cue in
            isCurrentSubtitle(cue)
        }
    }
}

struct SubtitleRowView: View {
    let cue: VideoSubtitleCue
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Text(formatTime(cue.startTime))
                    .font(.caption1(.pretendardMedium))
                    .foregroundStyle(isActive ? Color.deepCoast : Color.gray60)
                    .frame(width: 50, alignment: .leading)

                Text(cue.text)
                    .font(.caption1(.pretendardMedium))
                    .foregroundStyle(isActive ? Color.deepCoast : Color.gray90)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isActive ? Color.deepCoast.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        // NaN이나 infinite 값 처리
        guard time.isFinite && !time.isNaN else {
            return "0:00"
        }

        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
