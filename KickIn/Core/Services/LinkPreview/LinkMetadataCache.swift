//
//  LinkMetadataCache.swift
//  KickIn
//
//  Created by 서준일 on 01/22/26.
//

import Foundation

/// 링크 메타데이터를 2단계(메모리 + 영구 저장소)로 캐싱하는 클래스
final class LinkMetadataCache {
    // MARK: - Properties

    private let memoryCache = NSCache<NSString, CacheEntry>()
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "LinkMetadataCache"
    private let maxItems = 200
    private let queue = DispatchQueue(label: "com.kickin.linkmetadata.cache", attributes: .concurrent)

    // MARK: - Initialization

    init() {
        memoryCache.countLimit = maxItems
    }

    // MARK: - Public Methods

    /// 캐시에서 메타데이터 조회
    /// - Parameter url: 조회할 URL
    /// - Returns: 캐시된 LinkMetadata, 없거나 만료되면 nil
    func get(url: String) -> LinkMetadata? {
        let key = url as NSString

        // 1. 메모리 캐시 확인
        if let entry = memoryCache.object(forKey: key) {
            return entry.metadata
        }

        // 2. UserDefaults 확인
        return queue.sync {
            let persistentCache = loadPersistentCache()
            guard let metadata = persistentCache[url] else {
                return nil
            }

            // 메모리 캐시에도 저장
            memoryCache.setObject(CacheEntry(metadata: metadata), forKey: key)
            return metadata
        }
    }

    /// 캐시에 메타데이터 저장
    /// - Parameters:
    ///   - url: 저장할 URL
    ///   - metadata: 저장할 메타데이터
    func set(url: String, metadata: LinkMetadata) {
        let key = url as NSString

        // 1. 메모리 캐시 저장
        memoryCache.setObject(CacheEntry(metadata: metadata), forKey: key)

        // 2. UserDefaults 저장
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            var persistentCache = self.loadPersistentCache()

            // FIFO: 최대 개수 초과 시 가장 오래된 항목 제거
            if persistentCache.count >= self.maxItems {
                let sortedByDate = persistentCache.sorted { $0.value.fetchedAt < $1.value.fetchedAt }
                if let oldestKey = sortedByDate.first?.key {
                    persistentCache.removeValue(forKey: oldestKey)
                }
            }

            persistentCache[url] = metadata
            self.savePersistentCache(persistentCache)
        }
    }

    /// 캐시 전체 삭제
    func clear() {
        memoryCache.removeAllObjects()
        queue.async(flags: .barrier) { [weak self] in
            self?.userDefaults.removeObject(forKey: self?.cacheKey ?? "")
        }
    }

    // MARK: - Private Methods

    /// UserDefaults에서 영구 캐시 로드
    private func loadPersistentCache() -> [String: LinkMetadata] {
        guard let data = userDefaults.data(forKey: cacheKey),
              let cache = try? JSONDecoder().decode([String: LinkMetadata].self, from: data) else {
            return [:]
        }
        return cache
    }

    /// UserDefaults에 영구 캐시 저장
    private func savePersistentCache(_ cache: [String: LinkMetadata]) {
        if let data = try? JSONEncoder().encode(cache) {
            userDefaults.set(data, forKey: cacheKey)
        }
    }
}

// MARK: - Cache Entry

/// NSCache에 저장하기 위한 래퍼 클래스
private final class CacheEntry {
    let metadata: LinkMetadata

    init(metadata: LinkMetadata) {
        self.metadata = metadata
    }
}
