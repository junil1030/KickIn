//
//  ClusterMarkerView.swift
//  KickIn
//
//  Created by 서준일 on 01/13/26.
//

import SwiftUI

struct ClusterMarkerView: View {
    let count: Int

    /// 아이템 수에 따른 마커 크기 (직방 스타일)
    /// - 1-5개: 32pt (소형)
    /// - 6-20개: 40pt (중형)
    /// - 21-50개: 48pt (대형)
    /// - 51개 이상: 56pt (특대형)
    private var size: CGFloat {
        switch count {
        case 1...5:
            return 36
        case 6...50:
            return 40
        case 51...150:
            return 42
        case 151...250:
            return 44
        case 251...400:
            return 46
        case 401...600:
            return 50
        default:
            return 56
        }
    }

    /// 마커 크기에 비례하는 폰트 크기
    private var fontSize: CGFloat {
        switch count {
        case 1...5:
            return 12
        case 6...150:
            return 14
        case 151...400:
            return 16
        default:
            return 18
        }
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
