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
        
        // 3. SwiftUI 뷰의 실제 필요한 크기를 계산 (Padding 등이 포함된 크기)
        let targetSize = controller.view.intrinsicContentSize
        if targetSize.width <= 0 || targetSize.height <= 0 { return nil }
        
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        
        // 4. 렌더링
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            // afterScreenUpdates: true는 필수입니다.
            view?.drawHierarchy(in: view?.bounds ?? .zero, afterScreenUpdates: true)
        }
    }
}
