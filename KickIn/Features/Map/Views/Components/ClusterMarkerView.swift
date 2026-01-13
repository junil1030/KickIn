//
//  ClusterMarkerView.swift
//  KickIn
//
//  Created by 서준일 on 01/13/26.
//

import SwiftUI

struct ClusterMarkerView: View {
    let count: Int
    let size: CGFloat = 40

    var body: some View {
        ZStack {
            // Circle background with deepCream color at 85% opacity
            Circle()
                .fill(Color.deepCream.opacity(0.85))
                .frame(width: size, height: size)

            // Count label
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}
