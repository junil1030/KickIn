//
//  TodayEstatesTopImageView.swift
//  KickIn
//
//  Created by 서준일 on 12/19/25.
//

import SwiftUI
import CachingKit

struct TodayEstatesTopImageView: View {
    @Environment(\.screenSize) private var screenSize

    let estates: [TodayEstateUIModel]
    let accessToken: String?

    private var imageWidth: CGFloat {
        screenSize.width
    }

    private var imageHeight: CGFloat {
        imageWidth * (2.0 / 3.0)
    }

    private var imageHeaders: [String: String] {
        var headers: [String: String] = [:]
        headers["SeSACKey"] = APIConfig.apikey
        if let token = accessToken {
            headers["Authorization"] = token
        }
        return headers
    }

    var body: some View {
        Group {
            if estates.isEmpty {
                placeholderView
            } else {
                estatesTabView
            }
        }
    }
}

// MARK: - SubViews
private extension TodayEstatesTopImageView {

    var estatesTabView: some View {
        TabView {
            ForEach(estates.indices, id: \.self) { index in
                estateImageView(estates[index])
            }
        }
        .frame(width: imageWidth, height: imageHeight)
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    func estateImageView(_ estate: TodayEstateUIModel) -> some View {
        let imageURL = estate.thumbnails?.first?.thumbnailURL

        return CachedAsyncImage(
            url: imageURL,
            targetSize: CGSize(width: imageWidth, height: imageHeight),
            headers: imageHeaders
        ) { image in
            ZStack(alignment: .bottomLeading) {
                imageContent(image)
                imageOverlayView(estate)
            }
        } placeholder: {
            placeholderView
        }
    }

    func imageContent(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFill()
            .frame(width: imageWidth, height: imageHeight)
            .clipped()
    }

    func imageOverlayView(_ estate: TodayEstateUIModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            locationCapsuleView()
            titleView(estate.title ?? "제목이 없습니다.")
            introductionView(estate.introduction ?? "소개가 없습니다.")
        }
        .padding(.leading, 16)
        .padding(.bottom, 44)
    }
}

// MARK: - Overlay Components
private extension TodayEstatesTopImageView {

    func locationCapsuleView() -> some View {
        HStack(spacing: 4) {
            Image("Icon/Location")
                .resizable()
                .frame(width: 10, height: 10)

            Text("서울 반포동")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.gray60.opacity(0.7))
        )
        .foregroundStyle(Color.gray15)
        .font(.caption2())
    }

    func titleView(_ title: String) -> some View {
        Text(title)
            .font(.title1(.yeongdeok))
            .foregroundStyle(Color.gray15)
            .lineLimit(2)
            .frame(
                maxWidth: imageWidth * 0.5,
                alignment: .leading
            )
    }

    func introductionView(_ introduction: String) -> some View {
        Text(introduction)
            .font(.caption1(.yeongdeok))
            .foregroundStyle(Color.gray60)
            .lineLimit(2)
    }
}

// MARK: - Placeholder
private extension TodayEstatesTopImageView {

    var placeholderView: some View {
        Rectangle()
            .fill(Color.gray30)
            .frame(width: imageWidth, height: imageHeight)
            .frame(maxWidth: .infinity)
            .overlay {
                ProgressView()
            }
    }
}

#Preview {
    TodayEstatesTopImageView(
        estates: [],
        accessToken: nil
    )
    .environment(\.screenSize, ScreenSize(width: 390, height: 844, safeAreaTop: 47, safeAreaBottom: 34))
}
