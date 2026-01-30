//
//  MediaDrawerView.swift
//  KickIn
//
//  Created by 서준일 on 01/29/26
//

import SwiftUI
import CachingKit

struct MediaDrawerView: View {
    @Environment(\.cachingKit) private var cachingKit
    @StateObject private var viewModel = MediaDrawerViewModel()
    @Binding var isPresented: Bool

    let mediaItems: [MediaItem]

    // Fullscreen viewer states
    @State private var showImageViewer = false
    @State private var selectedMediaIndex = 0
    @State private var selectedPDF: PDFInfo?

    struct PDFInfo: Identifiable {
        let id = UUID()
        let url: URL
        let fileName: String
    }

    private var filteredItems: [MediaItem] {
        viewModel.filteredItems(from: mediaItems)
    }

    private var groupedItems: [(date: String, items: [MediaItem])] {
        viewModel.groupedByDate(items: filteredItems)
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // 반투명 배경 (탭하면 닫기)
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }

            // 서랍 컨테이너
            VStack(spacing: 0) {
                header
                tabBar
                Divider()

                if groupedItems.isEmpty {
                    emptyState
                } else {
                    mediaGrid
                }
            }
            .frame(width: UIScreen.main.bounds.width * 0.85)
            .background(Color.white)
            .ignoresSafeArea(edges: .bottom)
        }
        .sheet(isPresented: $showImageViewer) {
            FullScreenImageViewer(
                mediaItems: filteredItems,
                initialIndex: selectedMediaIndex,
                isPresented: $showImageViewer
            )
        }
        .sheet(item: $selectedPDF) { pdfInfo in
            PDFViewerSheet(
                pdfURL: pdfInfo.url,
                fileName: pdfInfo.fileName,
                isPresented: Binding(
                    get: { selectedPDF != nil },
                    set: { if !$0 { selectedPDF = nil } }
                )
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("미디어")
                .font(.body1(.pretendardBold))
                .foregroundColor(.black)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray75)
                    .frame(width: 32, height: 32)
                    .background(Color.gray30)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MediaDrawerViewModel.MediaTab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func tabButton(for tab: MediaDrawerViewModel.MediaTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedTab = tab
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 14))
                Text(tab.rawValue)
                    .font(.caption1(.pretendardMedium))
            }
            .foregroundColor(viewModel.selectedTab == tab ? .white : .gray75)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(viewModel.selectedTab == tab ? Color.black : Color.gray30)
            .cornerRadius(16)
        }
    }

    // MARK: - Media Grid

    private var mediaGrid: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: .sectionHeaders) {
                ForEach(groupedItems, id: \.date) { group in
                    mediaSection(for: group)
                }
            }
            .padding(.top, 8)
        }
    }

    private func mediaSection(for group: (date: String, items: [MediaItem])) -> some View {
        Section {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2)
                ],
                spacing: 2
            ) {
                ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                    MediaThumbnailCell(
                        item: item,
                        cachingKit: cachingKit,
                        onTap: {
                            handleMediaTap(item: item, index: index, in: group.items)
                        }
                    )
                }
            }
        } header: {
            Text(group.date)
                .font(.caption1())
                .foregroundColor(.gray75)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(.gray60)

            Text("미디어가 없습니다")
                .font(.body1(.pretendardMedium))
                .foregroundColor(.gray75)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Helper Methods

    private func handleMediaTap(item: MediaItem, index: Int, in items: [MediaItem]) {
        switch item.type {
        case .image, .video:
            // 이미지/비디오 뷰어 표시
            selectedMediaIndex = index
            showImageViewer = true

        case .pdf:
            // PDF 뷰어 표시
            if let url = item.url.thumbnailURL {
                selectedPDF = PDFInfo(
                    url: url,
                    fileName: item.fileName ?? "document.pdf"
                )
            }
        }
    }
}

// MARK: - MediaThumbnailCell

struct MediaThumbnailCell: View {
    let item: MediaItem
    let cachingKit: CachingKit
    let onTap: () -> Void

    private var thumbnailURL: URL? {
        if let thumbnailURLString = item.thumbnailURL {
            return thumbnailURLString.thumbnailURL
        } else {
            return item.url.thumbnailURL
        }
    }

    var body: some View {
        GeometryReader { geometry in
            Button(action: onTap) {
                ZStack {
                    // 썸네일 이미지
                    if let url = thumbnailURL {
                        CachedAsyncImage(
                            url: url,
                            targetSize: CGSize(width: 300, height: 300),
                            cachingKit: cachingKit
                        ) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.width)
                                .clipped()
                        } placeholder: {
                            Color.gray30
                                .frame(width: geometry.size.width, height: geometry.size.width)
                                .overlay {
                                    ProgressView()
                                }
                        }
                    } else {
                        Color.gray30
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray60)
                            }
                    }

                    // 타입별 오버레이 아이콘
                    if item.type == .video {
                        // 비디오 재생 아이콘
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                    } else if item.type == .pdf {
                        // PDF 아이콘
                        VStack(spacing: 4) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)

                            if let fileName = item.fileName {
                                Text(fileName)
                                    .font(.caption2(.pretendardMedium))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 4)
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .background(Color.black.opacity(0.6))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
