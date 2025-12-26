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
}
