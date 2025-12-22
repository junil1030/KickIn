//
//  HotEstateSection.swift
//  KickIn
//
//  Created by 서준일 on 12/19/25.
//

import SwiftUI

struct HotEstateSection: View {

    let estates: [HotEstateUIModel]
    let accessToken: String?

    private var imageHeaders: [String: String] {
        var headers: [String: String] = [:]
        headers["SeSACKey"] = APIConfig.apikey
        if let token = accessToken {
            headers["Authorization"] = token
        }
        return headers
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 섹션 헤더
            SectionHeader(title: "HOT 매물") {
                print("HOT 매물 View All tapped")
            }

            // 매물 리스트 (가로 스크롤)
            if estates.isEmpty {
                emptyView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(estates.indices, id: \.self) { index in
                            let estate = estates[index]
                            HotEstateCell(
                                thumbnailURL: getThumbnailURL(from: estate.thumbnails?.first),
                                introduction: estate.introduction ?? "소개가 없습니다.",
                                price: formatPrice(deposit: estate.deposit, monthlyRent: estate.monthlyRent),
                                viewerCount: estate.likeCount ?? 0,
                                dong: "서울 반포동",
                                area: formatArea(estate.area),
                                imageHeaders: imageHeaders
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Private Views

    private var emptyView: some View {
        Text("HOT 매물이 없습니다.")
            .font(.body2())
            .foregroundStyle(Color.gray60)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }

    // MARK: - Private Methods

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

#Preview {
    HotEstateSection(
        estates: [],
        accessToken: nil
    )
    .defaultBackground()
}
