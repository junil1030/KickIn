//
//  EstateMarkerView.swift
//  KickIn
//
//  Created by 서준일 on 01/13/26.
//

import SwiftUI

struct EstateMarkerView: View {
    // MARK: - Constants
    private enum Layout {
        static let width: CGFloat = 60
        static let imageHeight: CGFloat = 60
        static let priceHeight: CGFloat = 18
        static let cornerRadius: CGFloat = 6
    }

    // MARK: - Properties
    let image: UIImage?
    let priceText: String

    var body: some View {
        VStack(spacing: 0) {
            // Property image (top)
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Layout.width, height: Layout.imageHeight)
                    .clipped()
                    .cornerRadius(Layout.cornerRadius, corners: [.topLeft, .topRight])
            } else {
                // Placeholder
                ZStack {
                    Color.gray30
                    Image(systemName: "house.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color.gray60)
                }
                .frame(width: Layout.width, height: Layout.imageHeight)
                .cornerRadius(Layout.cornerRadius, corners: [.topLeft, .topRight])
            }

            // Price label (bottom)
            Text(priceText)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: Layout.width, height: Layout.priceHeight)
                .background(Color.deepCoast)
                .cornerRadius(Layout.cornerRadius, corners: [.bottomLeft, .bottomRight])
        }
        .frame(width: Layout.width, height: Layout.imageHeight + Layout.priceHeight)
        .background(Color.white)
        .cornerRadius(Layout.cornerRadius)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        .padding(5)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
