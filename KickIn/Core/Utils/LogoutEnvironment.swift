//
//  LogoutEnvironment.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import SwiftUI

// MARK: - Environment Key

struct LogoutActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var logoutAction: () -> Void {
        get { self[LogoutActionKey.self] }
        set { self[LogoutActionKey.self] = newValue }
    }
}
