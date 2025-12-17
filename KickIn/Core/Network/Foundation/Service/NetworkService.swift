//
//  NetworkService.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation
import Alamofire

final class NetworkService: NetworkServiceProtocol {
    private let session: Session
    private let tokenStorage: any TokenStorageProtocol

    init(tokenStorage: any TokenStorageProtocol) {
        self.tokenStorage = tokenStorage

        let interceptor = AuthenticationInterceptor(tokenStorage: tokenStorage)
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30

        self.session = Session(
            configuration: configuration,
            interceptor: interceptor
        )
    }

    // MARK: - NetworkServiceProtocol

    func request<T: Decodable>(_ router: any APIRouter) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            session.request(router)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let value):
                        continuation.resume(returning: value)
                    case .failure(let error):
                        let networkError = self.mapError(error, data: response.data, statusCode: response.response?.statusCode)
                        continuation.resume(throwing: networkError)
                    }
                }
        }
    }

    func upload<T: Decodable>(
        _ router: any APIRouter,
        files: [(data: Data, name: String, fileName: String, mimeType: String)]
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(multipartFormData: { multipartFormData in
                for file in files {
                    multipartFormData.append(
                        file.data,
                        withName: file.name,
                        fileName: file.fileName,
                        mimeType: file.mimeType
                    )
                }
            }, with: router)
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    let networkError = self.mapError(error, data: response.data, statusCode: response.response?.statusCode)
                    continuation.resume(throwing: networkError)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func mapError(_ error: AFError, data: Data?, statusCode: Int?) -> NetworkError {
        if let statusCode = statusCode {
            switch statusCode {
            case 400:
                let message = extractErrorMessage(from: data)
                return .badRequest(message: message)
            case 401:
                return .unauthorized
            case 403:
                return .forbidden
            case 404:
                return .notFound
            case 500...599:
                return .serverError
            default:
                break
            }
        }

        if error.isResponseSerializationError {
            return .decodingError
        }

        return .networkFailure(error)
    }

    private func extractErrorMessage(from data: Data?) -> String? {
        guard let data = data else { return nil }

        do {
            let errorResponse = try JSONDecoder().decode(ErrorResponseDTO.self, from: data)
            return errorResponse.message
        } catch {
            return nil
        }
    }
}
