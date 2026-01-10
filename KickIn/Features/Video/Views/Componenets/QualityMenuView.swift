//
//  QualityMenuView.swift
//  KickIn
//
//  Created by 서준일 on 01/10/26.
//

import SwiftUI

struct QualityMenuView: View {
    let qualities: [VideoStreamQualityDTO]
    let currentQuality: VideoStreamQualityDTO?
    let onSelect: (VideoStreamQualityDTO) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // 배경 탭으로 닫기
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 0) {
                // 헤더
                HStack {
                    Text("화질")
                        .font(.body2(.pretendardBold))
                        .foregroundStyle(Color.gray0)

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.gray60)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.gray90)

                // 화질 리스트
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(qualities.indices, id: \.self) { index in
                            QualityRowView(
                                quality: qualities[index],
                                isSelected: isSelected(qualities[index]),
                                onTap: {
                                    onSelect(qualities[index])
                                }
                            )

                            if index < qualities.count - 1 {
                                Divider()
                                    .background(Color.gray75)
                            }
                        }
                    }
                }
                .background(Color.gray90)
            }
            .frame(maxWidth: 300)
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }

    private func isSelected(_ quality: VideoStreamQualityDTO) -> Bool {
        guard let current = currentQuality,
              let currentQualityStr = current.quality,
              let qualityStr = quality.quality else {
            return false
        }
        return currentQualityStr == qualityStr
    }
}

struct QualityRowView: View {
    let quality: VideoStreamQualityDTO
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(quality.quality ?? "Unknown")
                    .font(.body2(.pretendardMedium))
                    .foregroundStyle(isSelected ? Color.deepCoast : Color.gray0)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.deepCoast)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(isSelected ? Color.deepCoast.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}
