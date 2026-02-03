//
//  MessageImageGrid.swift
//  KickIn
//
//  Created by 서준일 on 01/11/26
//

import SwiftUI
import OSLog
import CachingKit

struct MessageImageGrid: View {
    @Environment(\.cachingKit) private var cachingKit

    let mediaItems: [MediaItem]
    let isSentByMe: Bool
    let onImageTap: (MediaItem, Int) -> Void

    // 채팅 버블의 최대 너비
    private var maxWidth: CGFloat {
        UIScreen.main.bounds.width * 0.55
    }

    var body: some View {
        Group {
            switch mediaItems.count {
            case 1:
                singleImageLayout
            case 2:
                twoImagesLayout
            case 3:
                threeImagesLayout
            case 4:
                fourImagesLayout
            case 5:
                fiveImagesLayout
            default:
                EmptyView()
            }
        }
    }

    // MARK: - 1장: 원본 비율 유지
    private var singleImageLayout: some View {
        imageView(at: 0)
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: maxWidth)
            .cornerRadius(8)
    }

    // MARK: - 2장: 1:1 정사각형 2개, 가로 나란히
    private var twoImagesLayout: some View {
        HStack(spacing: 4) {
            ForEach(0..<2, id: \.self) { index in
                imageView(at: index)
                    .frame(width: (maxWidth - 4) / 2, height: (maxWidth - 4) / 2)
                    .clipped()
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - 3장: 왼쪽 큰 이미지 + 오른쪽 2개 스택
    private var threeImagesLayout: some View {
        HStack(spacing: 4) {
            // 왼쪽: 큰 이미지 (전체 높이)
            imageView(at: 0)
                .frame(width: (maxWidth - 4) / 2, height: (maxWidth - 4) / 2)
                .clipped()
                .cornerRadius(8)

            // 오른쪽: 2개 스택
            VStack(spacing: 4) {
                imageView(at: 1)
                    .frame(width: (maxWidth - 4) / 2, height: (maxWidth - 8) / 4)
                    .clipped()
                    .cornerRadius(8)

                imageView(at: 2)
                    .frame(width: (maxWidth - 4) / 2, height: (maxWidth - 8) / 4)
                    .clipped()
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - 4장: 2x2 그리드
    private var fourImagesLayout: some View {
        VStack(spacing: 4) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<2, id: \.self) { col in
                        let index = row * 2 + col
                        imageView(at: index)
                            .frame(width: (maxWidth - 4) / 2, height: (maxWidth - 4) / 2)
                            .clipped()
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - 5장: 상단 3개 + 하단 2개
    private var fiveImagesLayout: some View {
        let imageHeight = maxWidth / 3

        return VStack(spacing: 4) {
            // 상단: 3개
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    imageView(at: index)
                        .frame(width: (maxWidth - 8) / 3, height: imageHeight)
                        .clipped()
                        .cornerRadius(8)
                }
            }

            // 하단: 2개
            HStack(spacing: 4) {
                ForEach(3..<5, id: \.self) { index in
                    imageView(at: index)
                        .frame(width: (maxWidth - 4) / 2, height: imageHeight)
                        .clipped()
                        .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Helper: 이미지 뷰 생성
    @ViewBuilder
    private func imageView(at index: Int) -> some View {
        if index < mediaItems.count {
            let item = mediaItems[index]

            if item.type == .pdf {
                // PDF: PDFAttachmentCell 표시
                PDFAttachmentCell(
                    fileName: item.fileName ?? "document.pdf",
                    fileSize: item.fileSize,
                    isSentByMe: isSentByMe,
                    onTap: {
                        onImageTap(item, index)
                    }
                )
            } else if item.type == .video {
                // 비디오: 서버 썸네일 표시
                if let thumbnailURL = item.thumbnailURL?.thumbnailURL {
                    ZStack {
                        // 서버에서 제공하는 썸네일 이미지
                        CachedAsyncImage(
                            url: thumbnailURL,
                            targetSize: CGSize(width: 400, height: 400),
                            cachingKit: cachingKit
                        ) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray30)
                        }

                        // Play 버튼 오버레이
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                    }
                    .onTapGesture {
                        // 비디오 탭 시 전체화면 재생으로 이동
                        onImageTap(item, index)
                    }
                    .onAppear {
                        Logger.ui.info("🎬 Video file: \(item.url)")
                        Logger.ui.info("🖼️ Thumbnail URL: \(item.thumbnailURL ?? "nil")")
                        Logger.ui.info("🔗 Full URL: \(thumbnailURL.absoluteString)")
                    }
                }
            } else {
                // 이미지: CachedAsyncImage 사용
                if let imageURL = item.url.thumbnailURL {
                    CachedAsyncImage(
                        url: imageURL,
                        targetSize: CGSize(width: 400, height: 400),
                        cachingKit: cachingKit
                    ) { image in
                        image
                            .resizable()
                            .scaledToFill()  // aspectFill (crop)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray30)
                    }
                    .onTapGesture {
                        onImageTap(item, index)
                    }
                }
            }
        }
    }
}
