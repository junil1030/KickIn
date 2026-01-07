//
//  EstateDetailViewModel.swift
//  KickIn
//
//  Created by 서준일 on 12/23/25.
//

import Foundation
import Combine
import OSLog

final class EstateDetailViewModel: ObservableObject {
    @Published var estate: EstateDetailUIModel?
    @Published var similarEstates: [SimilarEstateUIModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    private let estateId: String

    // MARK: - Initialization

    init(estateId: String) {
        self.estateId = estateId
    }

    // MARK: - Public Methods
    func loadData() async {
        await loadDetail()
        await loadSimilarEstates()
    }

    func toggleLike() async {
        let currentLikeStatus = estate?.isLiked ?? false
        let nextLikeStatus = !currentLikeStatus

        do {
            let response: EstateLikeResponseDTO = try await networkService.request(
                EstateRouter.likeEstate(
                    estateId: estateId,
                    EstateLikeRequestDTO(likeStatus: nextLikeStatus)
                )
            )

            let updatedStatus = response.likeStatus ?? nextLikeStatus

            await MainActor.run {
                self.estate = self.estate?.updating(isLiked: updatedStatus)
            }

            Logger.network.info("✅ Updated estate like status: \(updatedStatus)")
        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to update like status: \(error.localizedDescription)")
        } catch {
            Logger.network.error("❌ Unknown error updating like status: \(error.localizedDescription)")
        }
    }
}

// MARK: - Load Data
extension EstateDetailViewModel {
    private func loadDetail() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let response: EstateDetailResponseDTO = try await networkService.request(
                EstateRouter.estateDetail(estateId: estateId)
            )

            let estateUIModel = response.toUIModel()

            await MainActor.run {
                self.estate = estateUIModel
                self.isLoading = false
            }

            Logger.network.info("✅ Loaded estate detail for ID: \(self.estateId)")

        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to load estate detail: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        } catch {
            Logger.network.error("❌ Unknown error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "매물 상세 정보를 불러오는데 실패했습니다."
                self.isLoading = false
            }
        }
    }

    private func loadSimilarEstates() async {
        do {
            let response: SimilarEstatesResponseDTO = try await networkService.request(
                EstateRouter.similarEstates
            )

            let estates = response.data?.map { $0.toUIModel() } ?? []

            await MainActor.run {
                self.similarEstates = estates
            }

            Logger.network.info("✅ Loaded similar estates: \(estates.count) items")

        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to load similar estates: \(error.localizedDescription)")
        } catch {
            Logger.network.error("❌ Unknown error loading similar estates: \(error.localizedDescription)")
        }
    }
}
