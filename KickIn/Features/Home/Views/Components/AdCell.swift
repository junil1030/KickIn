//
//  AdCell.swift
//  KickIn
//
//  Created by 서준일 on 12/22/25.
//

import SwiftUI

struct AdCell: View {
    var body: some View {
        HStack {
            Spacer()
            Text("광고입니다.")
                .foregroundStyle(Color.gray100)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AdCell()
}
