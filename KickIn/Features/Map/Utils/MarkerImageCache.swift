//
//  MarkerImageCache.swift
//  KickIn
//
//  Created by 서준일 on 01/13/26.
//

import UIKit
import SwiftUI
import OSLog
import CachingKit

// Notification for marker image updates
extension Notification.Name {
    static let markerImageDidLoad = Notification.Name("markerImageDidLoad")
}

final class MarkerImageCache {
    // MARK: - Singleton
    static let shared = MarkerImageCache()

    // MARK: - Cache Storage
    private var clusterCache: [Int: UIImage] = [:] // count -> image
    private var estateCache: [String: UIImage] = [:] // priceText -> image

    private let cacheQueue = DispatchQueue(label: "com.kickin.markerCache", attributes: .concurrent)
    private let maxCacheSize = 150 // Limit estate cache entries

    // CachingKit instance
    private let cachingKit: CachingKit

    // MARK: - Initialization
    private init() {
        self.cachingKit = NetworkServiceFactory.shared.getCachingKit()
    }

    // MARK: - Public Methods

    /// Get or create cluster marker image
    /// - Parameter count: Number of points in cluster
    /// - Returns: Cached or newly created cluster marker image
    @MainActor
    func clusterImage(count: Int) -> UIImage {
        // Read from cache
        if let cached = cacheQueue.sync(execute: { clusterCache[count] }) {
            return cached
        }

        // Create new image from SwiftUI View
        let view = ClusterMarkerView(count: count)
        let size = CGSize(width: 40, height: 40)

        guard let image = view.asUIImage(size: size) else {
            Logger().error("Failed to render cluster marker for count: \(count)")
            return createFallbackClusterImage()
        }

        // Write to cache
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.clusterCache[count] = image
        }

        Logger().debug("Cached cluster marker: count=\(count)")
        return image
    }

    /// Get or create estate marker image (synchronous - uses placeholder if image not cached)
    /// - Parameters:
    ///   - priceText: Formatted price string (cache key)
    ///   - imageURL: Property image URL (optional)
    /// - Returns: Cached or newly created estate marker image with placeholder
    @MainActor
    func estateImage(priceText: String, imageURL: String?) -> UIImage {
        // Use price as cache key (same price = reuse image)
        if let cached = cacheQueue.sync(execute: { estateCache[priceText] }) {
            return cached
        }

        // Create marker with placeholder (image will be loaded asynchronously)
        let view = EstateMarkerView(image: nil, priceText: priceText)
        let size = CGSize(width: 60, height: 78)

        guard let image = view.asUIImage(size: size) else {
            Logger().error("Failed to render estate marker for price: \(priceText)")
            return createFallbackEstateImage()
        }

        // Write placeholder to cache
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.estateCache[priceText] = image
        }

        // Load actual image asynchronously and update cache
        Task { @MainActor [weak self] in
            await self?.loadAndCacheEstateImage(priceText: priceText, imageURL: imageURL)
        }

        Logger().debug("Cached estate marker (placeholder): price=\(priceText)")
        return image
    }

    /// Load estate image asynchronously and update cache
    /// - Parameters:
    ///   - priceText: Formatted price string (cache key)
    ///   - imageURL: Property image URL (optional)
    @MainActor
    private func loadAndCacheEstateImage(priceText: String, imageURL: String?) async {
        // Load image using CachingKit
        var propertyImage: UIImage?
        if let urlString = imageURL,
           let url = URL(string: APIConfig.baseURL + urlString) {
            propertyImage = await cachingKit.loadImage(
                url: url,
                targetSize: CGSize(width: 60, height: 60)
            )
        }

        // Only update cache if we actually loaded an image
        guard let propertyImage = propertyImage else { return }

        // Create new marker with loaded image
        let view = EstateMarkerView(image: propertyImage, priceText: priceText)
        let size = CGSize(width: 60, height: 78)

        guard let image = view.asUIImage(size: size) else {
            Logger().error("Failed to render estate marker with loaded image: \(priceText)")
            return
        }

        // Update cache with image
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            self.estateCache[priceText] = image

            // Limit cache size - evict oldest entries if needed
            if self.estateCache.count > self.maxCacheSize {
                let keysToRemove = Array(self.estateCache.keys.prefix(10))
                keysToRemove.forEach { self.estateCache.removeValue(forKey: $0) }
            }

            // Notify that marker image has been loaded
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .markerImageDidLoad,
                    object: nil,
                    userInfo: ["priceText": priceText]
                )
            }
        }

        Logger().debug("Updated estate marker cache with loaded image: price=\(priceText)")
    }

    /// Clear all cached images
    func clearCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.clusterCache.removeAll()
            self?.estateCache.removeAll()
            Logger().info("Marker image cache cleared")
        }
    }

    // MARK: - Private Helpers

    private func createFallbackClusterImage() -> UIImage {
        // Simple gray circle as fallback
        let size: CGFloat = 40
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            UIColor.gray.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
    }

    private func createFallbackEstateImage() -> UIImage {
        // Simple gray rectangle as fallback
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 60, height: 78))
        return renderer.image { context in
            UIColor.lightGray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 60, height: 78))
        }
    }
}
