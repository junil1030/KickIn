//
//  AuthHeaderProvider.swift
//  KickIn
//
//  Created by 서준일 on 12/23/25.
//

import Foundation
import CachingKit

/// Header provider that injects API key for CachingKit
final class AuthHeaderProvider: HeaderProvider {
    func headers() async -> [String: String] {
        ["SeSACKey": APIConfig.apikey]
    }
}
