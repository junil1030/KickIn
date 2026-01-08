//
//  VideoPromoCell.swift
//  KickIn
//
//  Created by 서준일 on 01/08/26.
//

import SwiftUI
import CachingKit

struct VideoPromoCell: View {
    let video: VideoUIModel
    let cachingKit: CachingKit

    private let cellWidth: CGFloat = 220
    private let cellHeight: CGFloat = 124

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            CachedAsyncImage(
                url: getThumbnailURL(from: video.thumbnailUrl),
                targetSize: CGSize(width: cellWidth * 2, height: cellHeight * 2),
                cachingKit: cachingKit
            ) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: cellWidth, height: cellHeight)
                    .clipped()
                    .cornerRadius(12)
                    .overlay {
                        playOverlay
                    }
            } placeholder: {
                Rectangle()
                    .fill(Color.gray90)
                    .frame(width: cellWidth, height: cellHeight)
                    .cornerRadius(12)
                    .overlay {
                        ProgressView()
                    }
            }

            if let durationText = formattedDuration(video.duration) {
                Text(durationText)
                    .font(.caption3())
                    .foregroundStyle(Color.gray0)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.gray90.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(8)
            }
        }
        .frame(width: cellWidth, height: cellHeight)
    }

    private var playOverlay: some View {
        Image(systemName: "play.fill")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(Color.gray0)
            .padding(10)
            .background(Color.black.opacity(0.45))
            .clipShape(Circle())
    }

    private func getThumbnailURL(from thumbnail: String?) -> URL? {
        guard let thumbnail = thumbnail else { return nil }
        let urlString = APIConfig.baseURL + thumbnail
        return URL(string: urlString)
    }

    private func formattedDuration(_ duration: Double?) -> String? {
        guard let duration = duration else { return nil }
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
