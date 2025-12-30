//
//  EstateDetailTopImageView.swift
//  KickIn
//
//  Created by 서준일 on 12/26/25.
//

import SwiftUI
import CachingKit

struct EstateDetailTopImageView: View {
    @Environment(\.screenSize) private var screenSize
    @Environment(\.cachingKit) private var cachingKit

    let thumbnails: [String]?

    private var imageWidth: CGFloat {
        screenSize.width
    }

    private var imageHeight: CGFloat {
        imageWidth * (2.0 / 3.0)
    }

    var body: some View {
        Group {
            if let thumbnails = thumbnails, !thumbnails.isEmpty {
                imagesTabView(thumbnails: thumbnails)
            } else {
                placeholderView
            }
        }
    }
}

// MARK: - SubViews
private extension EstateDetailTopImageView {

    func imagesTabView(thumbnails: [String]) -> some View {
        TabView {
            ForEach(thumbnails, id: \.self) { thumbnail in
                imageView(thumbnail)
            }
        }
        .frame(width: imageWidth, height: imageHeight)
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    func imageView(_ thumbnail: String) -> some View {
        CachedAsyncImage(
            url: thumbnail.thumbnailURL,
            targetSize: CGSize(width: imageWidth, height: imageHeight),
            cachingKit: cachingKit
        ) { image in
            imageContent(image)
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
}

// MARK: - Placeholder
private extension EstateDetailTopImageView {

    var placeholderView: some View {
        Rectangle()
            .fill(Color.gray60)
            .frame(width: imageWidth, height: imageHeight)
            .frame(maxWidth: .infinity)
            .overlay {
                Text("사진이 없습니다.")
                    .font(.body1())
                    .foregroundStyle(Color.gray15)
            }
    }
}

#Preview {
    EstateDetailTopImageView(thumbnails: nil)
        .environment(\.screenSize, ScreenSize(width: 390, height: 844, safeAreaTop: 47, safeAreaBottom: 34))
}
