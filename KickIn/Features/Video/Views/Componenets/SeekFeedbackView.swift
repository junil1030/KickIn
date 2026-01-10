//
//  SeekFeedbackView.swift
//  KickIn
//
//  Created by 서준일 on 01/10/26.
//

import SwiftUI

struct SeekFeedbackView: View {
    let feedback: SeekFeedback

    var body: some View {
        HStack(spacing: 8) {
            if feedback.direction == .backward {
                Image(systemName: "gobackward.5")
                    .font(.system(size: 24, weight: .bold))
                Text("\(abs(feedback.accumulatedSeconds))초")
                    .font(.system(size: 20, weight: .bold))
            } else {
                Text("+\(feedback.accumulatedSeconds)초")
                    .font(.system(size: 20, weight: .bold))
                Image(systemName: "goforward.5")
                    .font(.system(size: 24, weight: .bold))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }
}
