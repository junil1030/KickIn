//
//  HomeViewModel.swift
//  KickIn
//
//  Created by 서준일 on 12/21/25.
//

import Foundation
import Combine
import OSLog

final class HomeViewModel: ObservableObject {
    @Published var todayEstates: [TodayEstateUIModel] = []
    @Published var hotEstates: [HotEstateUIModel] = []
    @Published var todayTopics: [TopicUIModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let networkService = NetworkServiceFactory.shared.makeNetworkService()

    // MARK: - Public Methods

    func loadData() async {
        await loadTodayEstates()
        await loadHotEstates()
        await loadTopic()
    }
}

// MARK: - Load Data
extension HomeViewModel {
    
    /// Load today's estates
    private func loadTodayEstates() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let response: TodayEstatesResponseDTO = try await networkService.request(EstateRouter.todayEstates)

            let estates = response.data?.map { $0.toUIModel() } ?? []

            await MainActor.run {
                self.todayEstates = estates
                self.isLoading = false
            }

            Logger.network.info("✅ Loaded \(estates.count) today estates")

        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to load today estates: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        } catch {
            Logger.network.error("❌ Unknown error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Today 매물을 불러오는데 실패했습니다."
                self.isLoading = false
            }
        }
    }
    
    /// Load hot estates
    private func loadHotEstates() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let response: HotEstatesResponseDTO = try await networkService.request(EstateRouter.hotEstates)

            let estates = response.data?.map { $0.toUIModel() } ?? []

            await MainActor.run {
                self.hotEstates = estates
                self.isLoading = false
            }

            Logger.network.info("✅ Loaded \(estates.count) today estates")

        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to load Hot estates: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        } catch {
            Logger.network.error("❌ Unknown error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Hot 매물을 불러오는데 실패했습니다."
                self.isLoading = false
            }
        }
    }
    
    /// Load today topic
    private func loadTopic() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let response: TodayTopicResponseDTO = try await networkService.request(EstateRouter.todayTopic)

            let topics = response.data?.map { $0.toUIModel() } ?? []

            await MainActor.run {
                self.todayTopics = topics
                self.isLoading = false
            }

            Logger.network.info("✅ Loaded \(topics.count) today estates")

        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to load today topics: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        } catch {
            Logger.network.error("❌ Unknown error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "오늘의 토픽을 불러오는데 실패했습니다."
                self.isLoading = false
            }
        }
    }
}
