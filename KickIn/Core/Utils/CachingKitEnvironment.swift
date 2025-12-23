//
//  CachingKitEnvironment.swift
//  KickIn
//
//  Created by 서준일 on 12/23/25.
//

import SwiftUI
import CachingKit

// MARK: - Environment Key

struct CachingKitKey: EnvironmentKey {
    static let defaultValue: CachingKit = .shared
}

extension EnvironmentValues {
    var cachingKit: CachingKit {
        get { self[CachingKitKey.self] }
        set { self[CachingKitKey.self] = newValue }
    }
}
