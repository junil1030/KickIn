//
//  MediaDrawerViewModel.swift
//  KickIn
//
//  Created by 서준일 on 01/29/26
//

import Foundation
import Combine

@MainActor
final class MediaDrawerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedTab: MediaTab = .all
    @Published var selectedMedia: MediaItem?
    @Published var showFullscreenViewer = false

    // MARK: - MediaTab Enum

    enum MediaTab: String, CaseIterable {
        case all = "전체"
        case images = "사진"
        case videos = "동영상"
        case files = "파일"

        var iconName: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .images: return "photo"
            case .videos: return "play.rectangle"
            case .files: return "doc"
            }
        }
    }

    // MARK: - Public Methods

    /// 선택된 탭에 따라 미디어 필터링
    func filteredItems(from items: [MediaItem]) -> [MediaItem] {
        switch selectedTab {
        case .all:
            return items
        case .images:
            return items.filter { $0.type == .image }
        case .videos:
            return items.filter { $0.type == .video }
        case .files:
            return items.filter { $0.type == .pdf }
        }
    }

    /// 날짜별로 미디어 그룹화 (최신순)
    func groupedByDate(items: [MediaItem]) -> [(date: String, items: [MediaItem])] {
        // 날짜별로 그룹화
        let grouped = Dictionary(grouping: items) { item -> String in
            item.createdAt.toDateHeaderText() ?? "날짜 미상"
        }

        // 날짜 키를 정렬 (최신순)
        let sortedKeys = grouped.keys.sorted { first, second in
            // ISO8601 문자열로 직접 비교 (최신순 = 내림차순)
            let firstDate = items.first { ($0.createdAt.toDateHeaderText() ?? "") == first }?.createdAt ?? ""
            let secondDate = items.first { ($0.createdAt.toDateHeaderText() ?? "") == second }?.createdAt ?? ""
            return firstDate > secondDate
        }

        // 정렬된 키로 배열 생성
        return sortedKeys.compactMap { key in
            guard let items = grouped[key] else { return nil }
            // 각 섹션 내에서도 최신순 정렬
            let sortedItems = items.sorted { $0.createdAt > $1.createdAt }
            return (date: key, items: sortedItems)
        }
    }
}
