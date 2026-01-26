//
//  OrientationManager.swift
//  KickIn
//
//  Created by 서준일 on 01/26/26.
//

import UIKit
import Combine

final class OrientationManager: ObservableObject {
    static let shared = OrientationManager()

    @Published var lockedOrientation: UIInterfaceOrientationMask = .portrait

    private init() {}

    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        lockedOrientation = orientation
    }

    func unlockOrientation() {
        lockedOrientation = .all
    }

    func setOrientation(_ orientation: UIInterfaceOrientation) {
        let orientationMask: UIInterfaceOrientationMask

        switch orientation {
        case .landscapeRight:
            orientationMask = .landscapeRight
        case .landscapeLeft:
            orientationMask = .landscapeLeft
        case .portrait:
            orientationMask = .portrait
        default:
            orientationMask = .portrait
        }

        lockOrientation(orientationMask)

        // 실제 기기 회전 요청
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }

        let geometryPreferences: UIWindowScene.GeometryPreferences
        switch orientation {
        case .landscapeRight:
            geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeRight)
        case .landscapeLeft:
            geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeLeft)
        case .portrait:
            geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
        default:
            geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
        }

        windowScene.requestGeometryUpdate(geometryPreferences) { error in
            print("❌ Failed to update geometry: \(error.localizedDescription)")
        }
    }
}
