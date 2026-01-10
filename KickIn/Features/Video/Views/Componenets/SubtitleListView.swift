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
                                }
                            )
                            .id(index)
                        }
                    }
                }
                .frame(maxHeight: 300)
                .onChange(of: currentTime) { _, _ in
                    // 현재 자막으로 자동 스크롤
                    if let activeIndex = activeSubtitleIndex() {
                        withAnimation {
                            proxy.scrollTo(activeIndex, anchor: .center)
                        }
                    }
                }
            }
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
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
