//
//  RecentEstateCell.swift
//  KickIn
//
//  Created by 서준일 on 12/19/25.
//

import SwiftUI
import CachingKit

struct RecentEstateCell: View {
    @State private var locationText: String = "동 정보가 없습니다."

    let data: RecentEstateUIModel
    let cachingKit: CachingKit

    private let geocodeService = GeocodeService()

    var body: some View {
        HStack(spacing: 12) {
            // 왼쪽: 이미지
            CachedAsyncImage(
                url: getThumbnailURL(from: data.thumbnailURL),
                targetSize: CGSize(width: 80, height: 80),
                cachingKit: cachingKit
            ) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray45)
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray60)
                    }
            }

            // 오른쪽: 정보
            VStack(alignment: .leading, spacing: 6) {
                // 카테고리
                Text(data.category ?? "매물")
                    .font(.caption2(.pretendardMedium))
                    .foregroundColor(.deepWood)

                // 가격
                Text(formatPrice(deposit: data.deposit, monthlyRent: data.monthlyRent))
                    .font(.body3(.pretendardBold))
                    .foregroundColor(.gray90)

                // 동, 평수
                HStack(spacing: 8) {
                    Text(locationText)
                        .font(.caption1())
                        .foregroundColor(.gray60)
                        .task {
                            locationText = await geocodeService.getSimpleLocationString(
                                latitude: data.latitude,
                                longitude: data.longitude
                            )
                        }

                    Text("·")
                        .foregroundColor(.gray60)

                    Text(formatArea(data.area))
                        .font(.caption1())
                        .foregroundColor(.gray60)
                }
            }

            Spacer()
        }
        .padding(12)
        .frame(width: 280)
        .background(Color.gray0)
        .cornerRadius(12)
    }
}

// MARK: - Helper Methods
extension RecentEstateCell {
    private func getThumbnailURL(from thumbnail: String?) -> URL? {
        guard let thumbnail = thumbnail else { return nil }
        let urlString = APIConfig.baseURL + thumbnail
        return URL(string: urlString)
    }

    private func formatPrice(deposit: Int?, monthlyRent: Int?) -> String {
        guard let deposit = deposit else { return "가격 정보 없음" }

        if let monthlyRent = monthlyRent, monthlyRent > 0 {
            // 월세
            let depositInMan = deposit / 10000
            let monthlyRentInMan = monthlyRent / 10000
            return "월세 \(depositInMan)/\(monthlyRentInMan)"
        } else {
            // 전세
            let depositInMan = deposit / 10000
            return "전세 \(depositInMan)만원"
        }
    }

    private func formatArea(_ area: Double?) -> String {
        guard let area = area else { return "면적 정보 없음" }
        // Convert square meters to pyeong (1 pyeong = 3.3058 m²)
        let pyeong = Int(area / 3.3058)
        return "\(pyeong)평"
    }
}
