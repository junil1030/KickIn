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
    @Published var paymentOrder: PaymentOrderInfo?

    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    private let recentEstateRepository: RecentEstateRepositoryProtocol
    private let estateId: String

    // MARK: - Initialization

    init(estateId: String,
         recentEstateRepository: RecentEstateRepositoryProtocol = RecentEstateRepository()) {
        self.estateId = estateId
        self.recentEstateRepository = recentEstateRepository
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

    func createOrder() async {
        guard let reservationPrice = estate?.reservationPrice else {
            await MainActor.run {
                self.errorMessage = "예약금 정보를 불러올 수 없습니다."
            }
            return
        }

        await MainActor.run {
            errorMessage = nil
        }

        do {
            let response: CreateOrderResponseDTO = try await networkService.request(
                OrderRouter.createOrder(
                    CreateOrderRequestDTO(
                        estateId: estateId,
                        totalPrice: reservationPrice
                    )
                )
            )
            
            let profile: UserProfileResponseDTO = try await networkService.request(UserRouter.myProfile)

            let orderCode = response.orderCode ?? "kickin_\(Int(Date().timeIntervalSince1970))"
            let amount = response.totalPrice ?? reservationPrice

            await MainActor.run {
                guard let estate = estate else {
                    self.errorMessage = "매물 정보를 불러올 수 없습니다."
                    return
                }
                self.paymentOrder = PaymentOrderInfo(
                    title: estate.title ?? "알 수 없는 매물",
                    buyerName: profile.email ?? "알 수 없는 이메일",
                    orderCode: orderCode,
                    amount: amount
                )
            }

            Logger.network.info("✅ Created order for estate ID: \(self.estateId), orderCode: \(orderCode)")
        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to create order: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        } catch {
            Logger.network.error("❌ Unknown error creating order: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "예약 요청에 실패했습니다."
            }
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

            // Save to recent estates
            await saveToRecentEstates(estateUIModel)

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

    private func saveToRecentEstates(_ estate: EstateDetailUIModel) async {
        do {
            try await recentEstateRepository.saveEstate(
                estateId: estate.estateId ?? UUID().uuidString,
                category: estate.category,
                deposit: estate.deposit,
                monthlyRent: estate.monthlyRent,
                latitude: estate.geolocation?.latitude,
                longitude: estate.geolocation?.longitude,
                area: estate.area,
                thumbnailURL: estate.thumbnails?.first
            )
            Logger.database.info("💾 Saved estate to recent: \(estate.estateId ?? "unknown")")
        } catch {
            Logger.database.error("❌ Failed to save recent estate: \(error.localizedDescription)")
        }
    }
}
