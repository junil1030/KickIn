//
//  ToastView.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.body3(.pretendardMedium))
            .foregroundColor(.gray75)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.gray0)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        ToastView(message: "토스트 메시지 예시입니다")
    }
}
