//  ChatInitiateButton.swift
//  KickIn
//  Created by 서준일 on 01/22/26

import SwiftUI

struct ChatInitiateButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray90))
                } else {
                    Image(systemName: "message.fill")
                        .font(.body2(.pretendardBold))
                        .foregroundColor(.gray90)

                    Text("채팅하기")
                        .font(.body2(.pretendardBold))
                        .foregroundColor(.gray90)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.deepCream)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}
