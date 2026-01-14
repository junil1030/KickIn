//
//  View+Image.swift
//  KickIn
//
//  Created by 서준일 on 01/13/26.
//

import SwiftUI

extension View {
    /// Renders the SwiftUI View as a UIImage
    /// - Parameter size: The size of the rendered image
    /// - Returns: UIImage representation of the view, or nil if rendering fails
    @MainActor
    func asUIImage(size: CGSize) -> UIImage? {
        // 1. UIHostingController 생성
        let controller = UIHostingController(rootView: self.edgesIgnoringSafeArea(.all))
        let view = controller.view

        // 2. 투명 배경 설정
        view?.backgroundColor = .clear

        // 3. 전달받은 size를 사용하여 레이아웃 (intrinsicContentSize는 SwiftUI .frame()을 반영하지 않을 수 있음)
        view?.frame = CGRect(origin: .zero, size: size)

        // 4. 레이아웃 강제 업데이트
        view?.layoutIfNeeded()

        // 5. 렌더링
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            // afterScreenUpdates: true는 필수입니다.
            view?.drawHierarchy(in: view?.bounds ?? .zero, afterScreenUpdates: true)
        }
    }
}
