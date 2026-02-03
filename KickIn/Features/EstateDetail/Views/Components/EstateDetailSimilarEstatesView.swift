//
//  EstateDetailSimilarEstatesView.swift
//  KickIn
//
//  Created by 서준일 on 12/29/25.
//

import SwiftUI
import CachingKit

struct EstateDetailSimilarEstatesView: View {
    @Environment(\.cachingKit) private var cachingKit

    let estates: [SimilarEstateUIModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 타이틀
            Text("유사한 매물")
                .font(.body2(.pretendardBold))
                .foregroundStyle(Color.gray75)
                .padding(.top, 10)
                .padding(.leading, 20)
                .padding(.bottom, 10)

            // 매물 리스트 (가로 스크롤)
            if estates.isEmpty {
                emptyView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(estates.indices, id: \.self) { index in
                            let estate = estates[index]
                            if let estateId = estate.estateId {
                                NavigationLink(destination: EstateDetailView(estateId: estateId)) {
                                    SimilarEstateCell(
                                        data: estate,
                                        cachingKit: cachingKit
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                SimilarEstateCell(
                                    data: estate,
                                    cachingKit: cachingKit
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            // AI 추천 안내
            HStack(spacing: 4) {
                Image("Icon/Safty")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 14, height: 14)
                    .foregroundStyle(Color.gray45)

                Text("새싹 AI 알고리즘 기반으로 추천된 매물입니다")
                    .font(.caption2(.pretendardMedium))
                    .foregroundStyle(Color.gray45)
            }
            .padding(.top, 12)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }

    // MARK: - Private Views

    private var emptyView: some View {
        Text("유사한 매물이 없습니다.")
            .font(.body2())
            .foregroundStyle(Color.gray60)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }
}

// MARK: - SimilarEstateCell

struct SimilarEstateCell: View {
    @State private var locationText: String = ""
    @State private var imageURL: URL?

    let data: SimilarEstateUIModel
    let cachingKit: CachingKit

    private let geocodeService = GeocodeService()

    var body: some View {
        HStack(spacing: 12) {
            // 왼쪽: 이미지
            if let imageURL = imageURL {
                CachedAsyncImage(
                    url: imageURL,
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
                            ProgressView()
                        }
                }
            } else {
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
                Text(data.category ?? "")
                    .font(.caption2(.pretendardMedium))
                    .foregroundColor(.deepWood)

                // 가격
                Text(priceText)
                    .font(.body3(.pretendardBold))
                    .foregroundColor(.gray90)

                // 동, 평수
                HStack(spacing: 8) {
                    Text(locationText)
                        .font(.caption1())
                        .foregroundColor(.gray60)

                    if !locationText.isEmpty {
                        Text("·")
                            .foregroundColor(.gray60)
                    }

                    Text(areaText)
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
        .task {
            imageURL = data.thumbnails?.first?.thumbnailURL
            locationText = await geocodeService.getSimpleLocationString(
                latitude: data.latitude,
                longitude: data.longitude
            )
        }
    }

    // MARK: - Computed Properties

    private var priceText: String {
        guard let deposit = data.deposit else {
            return "가격 미정"
        }

        let depositStr = (deposit / 10000).formattedManwon

        if let monthlyRent = data.monthlyRent, monthlyRent > 0 {
            let monthlyRentStr = (monthlyRent / 10000).formattedManwon
            return "월세 \(depositStr)/\(monthlyRentStr)"
        } else {
            return "전세 \(depositStr)"
        }
    }

    private var areaText: String {
        guard let area = data.area else {
            return ""
        }
        // m²를 평으로 변환 (1평 = 3.3058m²)
        let pyeong = area / 3.3058
        return String(format: "%.1f평", pyeong)
    }
}

#Preview {
    EstateDetailSimilarEstatesView(
        estates: [
            SimilarEstateUIModel(
                estateId: "1",
                category: "원룸",
                title: "깔끔한 원룸",
                introduction: "신축급",
                thumbnails: ["/data/estates/test.jpg"],
                deposit: 5000000,
                monthlyRent: 450000,
                area: 19.8,
                likeCount: 10,
                longitude: 126.889557,
                latitude: 37.51925
            ),
            SimilarEstateUIModel(
                estateId: "2",
                category: "투룸",
                title: "넓은 투룸",
                introduction: "채광 좋음",
                thumbnails: nil,
                deposit: 30000000,
                monthlyRent: 0,
                area: 33.0,
                likeCount: 5,
                longitude: 126.9780,
                latitude: 37.5665
            )
        ]
    )
    .defaultBackground()
}
