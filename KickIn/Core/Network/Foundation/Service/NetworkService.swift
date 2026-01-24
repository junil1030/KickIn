//
//  NetworkService.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation
import Alamofire
import OSLog

final class NetworkService: NetworkServiceProtocol {
    private let session: Session
    private let tokenStorage: any TokenStorageProtocol
    private let interceptor: AuthenticationInterceptor<KickInAuthenticator>

    init(tokenStorage: any TokenStorageProtocol) {
        self.tokenStorage = tokenStorage

        let authenticator = KickInAuthenticator(tokenStorage: tokenStorage)
        let emptyCredential = KickInAuthenticationCredential(
            accessToken: "",
            refreshToken: "",
            expiration: Date.distantFuture
        )
        self.interceptor = AuthenticationInterceptor(
            authenticator: authenticator,
            credential: emptyCredential
        )

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30

        self.session = Session(
            configuration: configuration,
            interceptor: interceptor
        )
    }

    func updateCredential(accessToken: String, refreshToken: String) {
        let credential = KickInAuthenticationCredential(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiration: Date.distantFuture
        )
        interceptor.credential = credential
    }

    // MARK: - NetworkServiceProtocol

    func request<T: Decodable>(_ router: any APIRouter) async throws -> T {
        Logger.network.debug("Request started: \(String(describing: router))")

        return try await withCheckedThrowingContinuation { continuation in
            do {
#if DEBUG
                let urlRequest = try router.asURLRequest()
                Logger.network.debug("URL: \(urlRequest.url?.absoluteString ?? "nil")")
                Logger.network.debug("Method: \(urlRequest.method?.rawValue ?? "nil")")
                Logger.network.debug("Headers: \(urlRequest.headers.dictionary)")

                if let body = urlRequest.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                    Logger.network.debug("Body: \(bodyString)")
                }
#endif

                session.request(router)
                    .validate()
                    .responseDecodable(of: T.self) { response in
                        Logger.network.debug("Response received")
                        Logger.network.debug("Status Code: \(response.response?.statusCode ?? 0)")

#if DEBUG
                        if let data = response.data, let dataString = String(data: data, encoding: .utf8) {
                            Logger.network.debug("Response Data: \(dataString)")
                        }
#endif

                        switch response.result {
                        case .success(let value):
                            Logger.network.info("Request succeeded")
                            continuation.resume(returning: value)
                        case .failure(let error):
                            Logger.network.error("Request failed: \(error.localizedDescription)")
                            let networkError = self.mapError(error, data: response.data, statusCode: response.response?.statusCode)
                            Logger.network.error("Mapped error: \(networkError.localizedDescription)")
                            continuation.resume(throwing: networkError)
                        }
                    }
            } catch {
                Logger.network.error("Failed to create URLRequest: \(error.localizedDescription)")
                continuation.resume(throwing: NetworkError.invalidURL)
            }
        }
    }
    
    func request(_ router: any APIRouter) async throws {
        Logger.network.debug("Request started: \(String(describing: router))")
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                
#if DEBUG
                let urlRequest = try router.asURLRequest()
                Logger.network.debug("URL: \(urlRequest.url?.absoluteString ?? "nil")")
                Logger.network.debug("Method: \(urlRequest.method?.rawValue ?? "nil")")
                Logger.network.debug("Headers: \(urlRequest.headers.dictionary)")
                
                if let body = urlRequest.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                    Logger.network.debug("Body: \(bodyString)")
                }
#endif
                
                session.request(router)
                    .validate()
                    .response { response in
                        Logger.network.debug("Response received")
                        Logger.network.debug("Status Code: \(response.response?.statusCode ?? 0)")

#if DEBUG
                        if let data = response.data, let dataString = String(data: data, encoding: .utf8) {
                            Logger.network.debug("Response Data: \(dataString)")
                        }
#endif
                        switch response.result {
                        case .success:
                            continuation.resume()
                        case .failure(let error):
                            let networkError = self.mapError(
                                error,
                                data: response.data,
                                statusCode: response.response?.statusCode
                            )
                            continuation.resume(throwing: networkError)
                        }
                    }
            } catch {
                Logger.network.error("Failed to create URLRequest: \(error.localizedDescription)")
                continuation.resume(throwing: NetworkError.invalidURL)
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

    func uploadWithProgress<T: Decodable>(
        _ router: any APIRouter,
        files: [(data: Data, name: String, fileName: String, mimeType: String)],
        progressHandler: @escaping (Double) -> Void
    ) async throws -> T {
        Logger.network.debug("Upload with progress started: \(String(describing: router))")

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
            .uploadProgress { progress in
                Task { @MainActor in
                    Logger.network.debug("Upload progress: \(progress.fractionCompleted)")
                    progressHandler(progress.fractionCompleted)
                }
            }
            .validate()
            .responseDecodable(of: T.self) { response in
                Logger.network.debug("Upload response received")
                Logger.network.debug("Status Code: \(response.response?.statusCode ?? 0)")

#if DEBUG
                if let data = response.data, let dataString = String(data: data, encoding: .utf8) {
                    Logger.network.debug("Response Data: \(dataString)")
                }
#endif

                switch response.result {
                case .success(let value):
                    Logger.network.info("Upload succeeded")
                    continuation.resume(returning: value)
                case .failure(let error):
                    Logger.network.error("Upload failed: \(error.localizedDescription)")
                    let networkError = self.mapError(
                        error,
                        data: response.data,
                        statusCode: response.response?.statusCode
                    )
                    Logger.network.error("Mapped error: \(networkError.localizedDescription)")
                    continuation.resume(throwing: networkError)
                }
            }
        }
    }

    func downloadPDF(
        from url: URL,
        to destinationURL: URL,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        Logger.network.debug("PDF download started: \(url.absoluteString)")

        return try await withCheckedThrowingContinuation { continuation in
            let destination: DownloadRequest.Destination = { _, _ in
                return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
            }

            session.download(url, to: destination)
                .downloadProgress { progress in
                    Task { @MainActor in
                        Logger.network.debug("Download progress: \(progress.fractionCompleted)")
                        progressHandler(progress.fractionCompleted)
                    }
                }
                .validate()
                .response { response in
                    Logger.network.debug("Download response received")
                    Logger.network.debug("Status Code: \(response.response?.statusCode ?? 0)")

                    switch response.result {
                    case .success(let fileURL):
                        guard let fileURL = fileURL else {
                            Logger.network.error("Downloaded file URL is nil")
                            continuation.resume(throwing: NetworkError.unknown)
                            return
                        }
                        Logger.network.info("PDF download succeeded: \(fileURL.lastPathComponent)")
                        continuation.resume(returning: fileURL)
                    case .failure(let error):
                        Logger.network.error("PDF download failed: \(error.localizedDescription)")
                        if let statusCode = response.response?.statusCode {
                            Logger.network.error("HTTP Status Code: \(statusCode)")
                        }
                        let networkError = self.mapError(
                            error,
                            data: nil,
                            statusCode: response.response?.statusCode
                        )
                        continuation.resume(throwing: networkError)
                    }
                }
        }
    }

    // MARK: - Private Methods

    private func mapError(_ error: AFError, data: Data?, statusCode: Int?) -> NetworkError {
        // 먼저 에러 메시지 추출 시도
        let message = extractErrorMessage(from: data)

        if let statusCode = statusCode {
            switch statusCode {
            case 400:
                return .badRequest(message: message)
            case 401:
                return .unauthorized
            case 403:
                return .forbidden(message: message)
            case 404:
                return .notFound
            case 500...599:
                return .serverError(message: message)
            default:
                // 그 외 HTTP 상태 코드 (예: 445)
                return .httpError(statusCode: statusCode, message: message)
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
