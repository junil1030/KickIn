//
//  AdCell.swift
//  KickIn
//
//  Created by 서준일 on 12/22/25.
//

import SwiftUI
import CachingKit

struct AdCell: View {
    @Environment(\.screenSize) private var screenSize
    @Environment(\.cachingKit) private var cachingKit

    let imageURL: URL?
    var action: (() -> Void)?

    private var imageWidth: CGFloat {
        screenSize.width - 32
    }

    var body: some View {
        Button(action: { action?() }) {
            CachedAsyncImage(
                url: imageURL,
                targetSize: CGSize(width: imageWidth, height: 90),
                cachingKit: cachingKit
            ) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(height: 90)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray90)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    AdCell(imageURL: nil)
}
