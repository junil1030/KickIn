//
//  EstateDetailInfoHeaderView.swift
//  KickIn
//
//  Created by 서준일 on 12/26/25.
//

import SwiftUI

struct EstateDetailInfoHeaderView: View {
    let isSafeEstate: Bool?
    let updatedAt: String?

    var body: some View {
        HStack(spacing: 4) {
            if isSafeEstate == true {
                safeEstateLabel
            }

            Spacer()

            if let updatedAt = updatedAt,
               let timeAgo = updatedAt.timeAgoFromNow {
                timeAgoLabel(timeAgo)
            }
        }
        .padding(20)
    }
}

// MARK: - SubViews
private extension EstateDetailInfoHeaderView {

    var safeEstateLabel: some View {
        HStack(spacing: 4) {
            Image("Icon/Safty")
                .resizable()
                .renderingMode(.template)
                .frame(width: 16, height: 16)
                .foregroundStyle(Color.deepCoast)

            Text("구매자 안심매물")
                .font(.caption1(.pretendardMedium))
                .foregroundStyle(Color.deepCoast)
        }
        .padding(8)
        .overlay(
            Capsule()
                .stroke(Color.deepCoast, lineWidth: 1)
        )
    }

    func timeAgoLabel(_ timeAgo: String) -> some View {
        Text(timeAgo)
            .font(.body3(.pretendardMedium))
            .foregroundStyle(Color.gray45)
    }
}

#Preview {
    VStack(spacing: 20) {
        EstateDetailInfoHeaderView(
            isSafeEstate: true,
            updatedAt: "2025-12-26T10:30:00.000Z"
        )

        EstateDetailInfoHeaderView(
            isSafeEstate: false,
            updatedAt: "2025-12-25T14:20:00.000Z"
        )

        EstateDetailInfoHeaderView(
            isSafeEstate: nil,
            updatedAt: nil
        )
    }
    .background(Color.gray15)
}
