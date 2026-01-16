//
//  ProfileEditViewModel.swift
//  KickIn
//
//  Created by 서준일 on 01/16/26
//

import Foundation
import Combine
import OSLog

@MainActor
final class ProfileEditViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var nick: String = ""
    @Published var introduction: String = ""
    @Published var phoneNum: String = ""
    @Published var profileImage: String?
    @Published var selectedImageData: Data?

    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var showSuccessMessage: Bool = false

    // MARK: - Private Properties
    private let networkService: NetworkServiceProtocol

    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol = NetworkServiceFactory.shared.makeNetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Public Methods

    /// 프로필 정보 로드
    func loadProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: MyProfileResponseDTO = try await networkService.request(UserRouter.myProfile)

            nick = response.nick ?? ""
            introduction = response.introduction ?? ""
            phoneNum = response.phoneNum ?? ""
            profileImage = response.profileImage

            Logger.profile.info("프로필 로드 성공")
        } catch {
            let networkError = error as? NetworkError ?? .unknown
            errorMessage = networkError.localizedDescription
            Logger.profile.error("프로필 로드 실패: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// 프로필 저장
    func saveProfile() async -> Bool {
        isSaving = true
        errorMessage = nil

        do {
            // 1. 이미지가 선택된 경우 이미지 업로드
            var uploadedImagePath: String? = profileImage

            if let imageData = selectedImageData {
                uploadedImagePath = try await uploadProfileImage(imageData)
            }

            // 2. 프로필 정보 업데이트
            let requestDTO = UpdateProfileRequestDTO(
                nick: nick.isEmpty ? nil : nick,
                introduction: introduction.isEmpty ? nil : introduction,
                phoneNum: phoneNum.isEmpty ? nil : phoneNum,
                profileImage: uploadedImagePath
            )

            let _: MyProfileResponseDTO = try await networkService.request(
                UserRouter.updateMyProfile(requestDTO)
            )

            Logger.profile.info("프로필 저장 성공")
            showSuccessMessage = true
            isSaving = false
            return true

        } catch {
            let networkError = error as? NetworkError ?? .unknown
            errorMessage = networkError.localizedDescription
            Logger.profile.error("프로필 저장 실패: \(error.localizedDescription)")
            isSaving = false
            return false
        }
    }

    // MARK: - Private Methods

    /// 프로필 이미지 업로드
    private func uploadProfileImage(_ imageData: Data) async throws -> String {
        let fileSizeKB = Double(imageData.count) / 1024.0

        let files = [(
            data: imageData,
            name: "profile",
            fileName: "profile.jpg",
            mimeType: "image/jpeg"
        )]

        let response: ProfileImageResponseDTO = try await networkService.uploadWithProgress(
            UserRouter.uploadProfileImage,
            files: files
        ) { [weak self] progress in
            self?.uploadProgress = progress
            Logger.profile.debug("업로드 진행률: \(String(format: "%.1f", progress * 100))%")
        }

        guard let imagePath = response.profileImage else {
            Logger.profile.error("응답에 이미지 경로 없음")
            throw NetworkError.decodingError
        }

        Logger.profile.info("이미지 업로드 성공: \(imagePath)")
        return imagePath
    }
}
