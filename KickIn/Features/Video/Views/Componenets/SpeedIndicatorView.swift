//
//  SpeedIndicatorView.swift
//  KickIn
//
//  Created by 서준일 on 01/10/26.
//

import SwiftUI

struct SpeedIndicatorView: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "forward.fill")
                .font(.system(size: 16, weight: .bold))
            Text("2x")
                .font(.system(size: 18, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.deepCoast)
        .cornerRadius(6)
    }
}
