//
//  InterestEstateCell.swift
//  KickIn
//
//  Created by 서준일 on 12/30/25.
//

import SwiftUI
import CachingKit

struct InterestEstateCell: View {
    @Environment(\.cachingKit) private var cachingKit

    let estate: InterestUIModel
    @State private var address: String = ""

    private let geocodeService = GeocodeService()

    var body: some View {
        HStack(spacing: 12) {
            // 썸네일 이미지 (4:3 비율)
            CachedAsyncImage(
                url: getThumbnailURL(from: estate.thumbnailURL),
                targetSize: CGSize(width: 120, height: 90),
                cachingKit: cachingKit
            ) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 90)
                    .clipped()
                    .cornerRadius(8)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray45)
                    .frame(width: 120, height: 90)
            }

            // 매물 정보
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(estate.title)
                    .font(.caption1(.pretendardMedium))
                    .foregroundColor(.gray75)
                    .lineLimit(1)

                // 가격
                Text(formatPrice())
                    .font(.body1(.pretendardBold))
                    .foregroundColor(.gray90)
                    .lineLimit(1)

                // 면적 & 층수
                Text(formatAreaAndFloors())
                    .font(.caption1(.pretendardMedium))
                    .foregroundColor(.gray75)
                    .lineLimit(1)

                // 주소
                Text(address)
                    .font(.caption1(.pretendardMedium))
                    .foregroundColor(.gray75)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .task {
            address = await geocodeService.getDetailedLocationString(
                latitude: estate.latitude,
                longitude: estate.longitude
            )
        }
    }

    private func getThumbnailURL(from thumbnail: String?) -> URL? {
        guard let thumbnail = thumbnail else { return nil }
        let urlString = APIConfig.baseURL + thumbnail
        return URL(string: urlString)
    }

    private func formatPrice() -> String {
        let depositInManWon = estate.deposit / 10000
        let rentInManWon = estate.monthlyRent / 10000

        if depositInManWon > 0 && rentInManWon > 0 {
            return "월세 \(depositInManWon)/\(rentInManWon)"
        } else if depositInManWon > 0 {
            return "보증금 \(depositInManWon)"
        } else if rentInManWon > 0 {
            return "월세 \(rentInManWon)"
        } else {
            return "가격 정보 없음"
        }
    }

    private func formatAreaAndFloors() -> String {
        var components: [String] = []

        if let area = estate.area {
            components.append(String(format: "%.1fm²", area))
        }

        if let floors = estate.floors {
            components.append("\(floors)층")
        }

        return components.isEmpty ? "" : components.joined(separator: " • ")
    }
}

#Preview {
    VStack {
        InterestEstateCell(estate: InterestUIModel(
            id: "1",
            title: "강남역 5분거리 신축 오피스텔",
            thumbnailURL: nil,
            deposit: 50000000,
            monthlyRent: 500000,
            area: 82.4,
            builtYear: "2023",
            floors: 12,
            longitude: 126.9025,
            latitude: 37.5326
        ))

        InterestEstateCell(estate: InterestUIModel(
            id: "2",
            title: "홍대입구역 도보 3분 원룸",
            thumbnailURL: nil,
            deposit: 10000000,
            monthlyRent: 600000,
            area: 20.0,
            builtYear: "2020",
            floors: 5,
            longitude: 126.9244,
            latitude: 37.5563
        ))
    }
    .environment(\.cachingKit, .shared)
}
