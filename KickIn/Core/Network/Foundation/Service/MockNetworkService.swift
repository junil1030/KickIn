//
//  MockNetworkService.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

#if DEBUG
import Foundation

final class MockNetworkService: NetworkServiceProtocol {
    var shouldSucceed = true
    var mockResponse: Any?
    var mockError: NetworkError?
    var requestCallCount = 0
    var uploadCallCount = 0

    func request<T: Decodable>(_ router: any APIRouter) async throws -> T {
        requestCallCount += 1

        if !shouldSucceed, let error = mockError {
            throw error
        }

        if let response = mockResponse as? T {
            return response
        }

        throw NetworkError.decodingError
    }
    
    func request(_ router: any APIRouter) async throws {
        requestCallCount += 1

        if !shouldSucceed, let error = mockError {
            throw error
        }

        throw NetworkError.decodingError
    }

    func upload<T: Decodable>(
        _ router: any APIRouter,
        files: [(data: Data, name: String, fileName: String, mimeType: String)]
    ) async throws -> T {
        uploadCallCount += 1

        if !shouldSucceed, let error = mockError {
            throw error
        }

        if let response = mockResponse as? T {
            return response
        }

        throw NetworkError.decodingError
    }

    func uploadWithProgress<T: Decodable>(
        _ router: any APIRouter,
        files: [(data: Data, name: String, fileName: String, mimeType: String)],
        progressHandler: @escaping (Double) -> Void
    ) async throws -> T {
        uploadCallCount += 1

        // Mock progress updates
        Task { @MainActor in
            progressHandler(0.0)
        }
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        Task { @MainActor in
            progressHandler(0.5)
        }
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        Task { @MainActor in
            progressHandler(1.0)
        }

        if !shouldSucceed, let error = mockError {
            throw error
        }

        if let response = mockResponse as? T {
            return response
        }

        throw NetworkError.decodingError
    }

    func reset() {
        shouldSucceed = true
        mockResponse = nil
        mockError = nil
        requestCallCount = 0
        uploadCallCount = 0
    }
}
#endif
