//
//  InterestViewModel.swift
//  KickIn
//
//  Created by 서준일 on 12/30/25.
//

import Foundation
import Combine
import OSLog

enum FilterType: String, CaseIterable {
    case area = "면적 순"
    case deposit = "보증금 순"
    case monthlyRent = "월세 순"
    case newBuilding = "신축 순"
}

final class InterestViewModel: ObservableObject {
    @Published var estates: [InterestUIModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: FilterType = .monthlyRent
    @Published var isDescending: Bool = true

    private var rawEstates: [InterestUIModel] = []
    private var nextCursor: String? = nil
    private var hasMoreData = true
    private let networkService = NetworkServiceFactory.shared.makeNetworkService()

    // MARK: - Public Methods

    func loadData() async {
        await fetchEstates(cursor: nil)
    }

    func loadMoreIfNeeded(currentItem: InterestUIModel) async {
        guard let lastItem = estates.last else { return }
        guard currentItem.id == lastItem.id else { return }
        guard hasMoreData && !isLoading else { return }

        await fetchEstates(cursor: nextCursor)
    }

    func toggleSortOrder() {
        isDescending.toggle()
        sortEstates()
    }

    func selectFilter(_ filter: FilterType) {
        selectedFilter = filter
        sortEstates()
    }
}

// MARK: - Load Data
extension InterestViewModel {

    private func fetchEstates(cursor: String?) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let response: EstateLikesResponseDTO = try await networkService.request(
                EstateRouter.myLikes(category: nil, next: cursor, limit: "5")
            )

            let newEstates = response.data?.map { $0.toUIModel() } ?? []

            await MainActor.run {
                if cursor == nil {
                    // 첫 로드
                    self.rawEstates = newEstates
                } else {
                    // 추가 로드
                    self.rawEstates.append(contentsOf: newEstates)
                }

                // nextCursor가 0이면 더 이상 데이터가 없음
                if let nextCursor = response.nextCursor, nextCursor != "0" {
                    self.nextCursor = nextCursor
                    self.hasMoreData = true
                } else {
                    self.nextCursor = nil
                    self.hasMoreData = false
                }

                self.sortEstates()
                self.isLoading = false
            }

            Logger.network.info("✅ Loaded \(newEstates.count) interest estates (total: \(self.rawEstates.count))")

        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to load interest estates: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        } catch {
            Logger.network.error("❌ Unknown error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "관심 매물을 불러오는데 실패했습니다."
                self.isLoading = false
            }
        }
    }
}

// MARK: - Sorting
extension InterestViewModel {

    private func sortEstates() {
        switch selectedFilter {
        case .area:
            sortByArea()
        case .deposit:
            sortByDeposit()
        case .monthlyRent:
            sortByMonthlyRent()
        case .newBuilding:
            sortByBuiltYear()
        }
    }

    private func sortByArea() {
        estates = rawEstates.sorted { lhs, rhs in
            guard let lhsArea = lhs.area else { return false }
            guard let rhsArea = rhs.area else { return true }
            return isDescending ? lhsArea > rhsArea : lhsArea < rhsArea
        }
    }

    private func sortByDeposit() {
        estates = rawEstates.sorted { lhs, rhs in
            let lhsDeposit = lhs.deposit
            let rhsDeposit = rhs.deposit
            return isDescending ? lhsDeposit > rhsDeposit : lhsDeposit < rhsDeposit
        }
    }

    private func sortByMonthlyRent() {
        // 월세와 전세를 분리
        let monthlyRentEstates = rawEstates.filter { $0.monthlyRent > 0 }
        let jeonseEstates = rawEstates.filter { $0.monthlyRent == 0 }

        // 월세는 monthlyRent로 정렬
        let sortedMonthlyRent = monthlyRentEstates.sorted { lhs, rhs in
            return isDescending ? lhs.monthlyRent > rhs.monthlyRent : lhs.monthlyRent < rhs.monthlyRent
        }

        // 전세는 deposit으로 정렬
        let sortedJeonse = jeonseEstates.sorted { lhs, rhs in
            return isDescending ? lhs.deposit > rhs.deposit : lhs.deposit < rhs.deposit
        }

        // 월세 먼저, 그 다음 전세
        estates = sortedMonthlyRent + sortedJeonse
    }

    private func sortByBuiltYear() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        estates = rawEstates.sorted { lhs, rhs in
            guard let lhsYearString = lhs.builtYear,
                  let lhsDate = dateFormatter.date(from: lhsYearString) else { return false }
            guard let rhsYearString = rhs.builtYear,
                  let rhsDate = dateFormatter.date(from: rhsYearString) else { return true }
            return isDescending ? lhsDate > rhsDate : lhsDate < rhsDate
        }
    }
}
