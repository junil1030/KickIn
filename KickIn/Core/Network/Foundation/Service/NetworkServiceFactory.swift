//
//  NetworkServiceFactory.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation
import Alamofire
import CachingKit

final class NetworkServiceFactory {
    static let shared = NetworkServiceFactory()

    private let tokenStorage: any TokenStorageProtocol
    private let interceptor: AuthenticationInterceptor
    private let session: Session
    private let cachingKit: CachingKit
    private lazy var networkService: NetworkServiceProtocol = {
        NetworkService(tokenStorage: tokenStorage)
    }()

    // Production용 private init (Singleton)
    private convenience init() {
        self.init(
            tokenStorage: KeychainTokenStorage(),
            sessionConfiguration: .default
        )
    }

    // 테스트용 public init (의존성 주입)
    init(
        tokenStorage: any TokenStorageProtocol,
        sessionConfiguration: URLSessionConfiguration = .default
    ) {
        self.tokenStorage = tokenStorage
        self.interceptor = AuthenticationInterceptor(tokenStorage: tokenStorage)

        // Session 설정
        let config = sessionConfiguration
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        config.requestCachePolicy = .reloadRevalidatingCacheData

        // URLCache 설정
        let urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,  // 50MB
            diskCapacity: 200 * 1024 * 1024,   // 200MB
            diskPath: "KickInNetworkCache"
        )
        config.urlCache = urlCache

        // Session 생성 (Interceptor 포함)
        self.session = Session(
            configuration: config,
            interceptor: interceptor
        )

        // CachingKit 설정 (AuthHeaderProvider 사용)
        let authHeaderProvider = AuthHeaderProvider(tokenStorage: tokenStorage)
        let cacheConfiguration = CacheConfiguration(
            headerProvider: authHeaderProvider
        )
        self.cachingKit = CachingKit(configuration: cacheConfiguration)
    }

    // MARK: - Public Methods

    func makeNetworkService() -> NetworkServiceProtocol {
        networkService
    }

    func getTokenStorage() -> any TokenStorageProtocol {
        tokenStorage
    }

    func getInterceptor() -> AuthenticationInterceptor {
        interceptor
    }

    func getCachingKit() -> CachingKit {
        cachingKit
    }
}
