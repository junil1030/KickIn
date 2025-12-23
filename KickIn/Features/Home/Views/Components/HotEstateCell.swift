//
//  HotEstateCell.swift
//  KickIn
//
//  Created by 서준일 on 12/19/25.
//

import SwiftUI
import CachingKit

struct HotEstateCell: View {
    @State private var locationText: String = "동 정보가 없습니다."

    let data: HotEstateUIModel
    let cachingKit: CachingKit

    private let geocodeService = GeocodeService()

    var body: some View {
        ZStack {
            // 배경 이미지
            CachedAsyncImage(
                url: getThumbnailURL(from: data.thumbnails?.first),
                targetSize: CGSize(width: 300, height: 100),
                cachingKit: cachingKit
            ) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 100)
                    .clipped()
                    .cornerRadius(12)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray90)
                    .frame(width: 300, height: 100)
                    .cornerRadius(12)
                    .overlay {
                        ProgressView()
                    }
            }
            
            VStack {
                HStack {
                    // 왼쪽: Fire 아이콘
                    fireIcon()
                    
                    Spacer()
                    
                    // 오른쪽: 소개와 가격
                    introduce()
                }
                .padding(.horizontal, 10)
                
                Spacer()
                
                HStack {
                    // 왼쪽: 함께 보는 중 뱃지
                    viewCount()
                    
                    Spacer()
                    
                    // 오른쪽: 동네와 방 크기
                    location()
                }
                .padding(.horizontal, 10)
            }
            .padding(.vertical, 10)
        }
        .frame(width: 300, height: 100)
    }
}

// MARK: - Cell Components
extension HotEstateCell {
    private func fireIcon() -> some View {
        Image("Icon/Fire")
            .resizable()
            .renderingMode(.template)
            .foregroundColor(.gray0)
            .frame(width: 24, height: 24)
    }
    
    private func introduce() -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(data.introduction ?? "소개 정보가 없습니다.")
                .font(.caption1(.yeongdeok))
                .foregroundColor(.gray0)
                .lineLimit(1)
            
            Text(formatPrice(deposit: data.deposit, monthlyRent: data.monthlyRent))
                .font(.body1(.yeongdeok))
                .foregroundColor(.gray0)
                .fontWeight(.bold)
        }
    }
    
    private func viewCount() -> some View {
        Text("\(data.likeCount ?? 0)명이 함께 보는 중")
            .font(.caption3())
            .foregroundColor(.gray0)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray60.opacity(0.7))
            .cornerRadius(4)
    }
    
    private func location() -> some View {
        HStack(spacing: 2) {
            Text(locationText)
                .font(.caption2())
                .foregroundColor(.gray45)
                .task {
                    locationText = await geocodeService.getLocationString(latitude: data.latitude, longitude: data.longitude)
                }
            
            Text("·")
                .foregroundColor(.gray45)
            
            Text(formatArea(data.area))
                .font(.caption2())
                .foregroundColor(.gray45)
        }
    }
}

extension HotEstateCell {
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
