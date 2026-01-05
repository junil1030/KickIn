//
//  ProfileViewModel.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import Foundation
import Combine
import OSLog

final class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfileUIModel?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let networkService = NetworkServiceFactory.shared.makeNetworkService()

    // MARK: - Public Methods

    func loadMyProfile() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let response: UserProfileResponseDTO = try await networkService.request(UserRouter.myProfile)

            let profile = response.toUIModel()

            await MainActor.run {
                self.userProfile = profile
                self.isLoading = false
            }

            Logger.network.info("✅ Loaded user profile")

        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to load user profile: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        } catch {
            Logger.network.error("❌ Unknown error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "프로필을 불러오는데 실패했습니다."
                self.isLoading = false
            }
        }
    }
}
