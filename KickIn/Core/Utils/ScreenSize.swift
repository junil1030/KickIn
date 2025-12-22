//
//  ScreenSize.swift
//  KickIn
//
//  Created by 서준일 on 12/19/25.
//

import SwiftUI

// MARK: - ScreenSize Model

struct ScreenSize {
    let width: CGFloat
    let height: CGFloat
    let safeAreaTop: CGFloat
    let safeAreaBottom: CGFloat
}

// MARK: - Environment Key

struct ScreenSizeKey: EnvironmentKey {
    static let defaultValue = ScreenSize(
        width: 0,
        height: 0,
        safeAreaTop: 0,
        safeAreaBottom: 0
    )
}

extension EnvironmentValues {
    var screenSize: ScreenSize {
        get { self[ScreenSizeKey.self] }
        set { self[ScreenSizeKey.self] = newValue }
    }
}
