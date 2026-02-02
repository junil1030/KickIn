//
//  ClusterMarkerView.swift
//  KickIn
//
//  Created by 서준일 on 01/13/26.
//

import SwiftUI

struct ClusterMarkerView: View {
    let count: Int

    /// 아이템 수에 따른 마커 크기 (제곱근 스케일)
    /// - 최소: 24pt, 최대: 80pt
    /// - 최대 count: 300개
    private var size: CGFloat {
        let minSize: CGFloat = 24
        let maxSize: CGFloat = 80

        // count를 0~1로 정규화
        let normalized = min(1.0, Double(count) / 300.0)

        // 제곱근 스케일 적용
        let sqrtScale = sqrt(normalized)

        return minSize + (maxSize - minSize) * sqrtScale
    }

    /// 마커 크기에 비례하는 폰트 크기 (제곱근 스케일)
    /// - 최소: 10pt, 최대: 22pt
    private var fontSize: CGFloat {
        let minFontSize: CGFloat = 10
        let maxFontSize: CGFloat = 22

        let normalized = min(1.0, Double(count) / 300.0)
        let sqrtScale = sqrt(normalized)

        return minFontSize + (maxFontSize - minFontSize) * sqrtScale
    }

    var body: some View {
        ZStack {
            // Circle background with deepCream color at 85% opacity
            Circle()
                .fill(Color.deepCream.opacity(0.85))
                .frame(width: size, height: size)

            // Count label
            Text("\(count)")
                .font(.system(size: fontSize, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}
