//
//  Color+Extension.swift
//  KickIn
//
//  Created by 서준일 on 12/19/25.
//

import SwiftUI

extension Color {
    init(hex: String, opacity: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (
                (int >> 16) & 0xFF,
                (int >> 8) & 0xFF,
                int & 0xFF
            )
        default:
            (r, g, b) = (0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: opacity
        )
    }
    
    // MARK: - Brand Color
    static let deepCream   = Color(hex: "#8FAADC")
    static let brightCream = Color(hex: "#E6EEF8")
    static let deepCoast   = Color(hex: "#5E6E75")
    static let brightCoast = Color(hex: "#DDE3E6")
    static let deepWood    = Color(hex: "#1C1F24")
    static let brightWood  = Color(hex: "#6B7280")
    
    // MARK: - Gray Scale Color
    static let gray0 = Color(hex: "#FFFFFF")
    static let gray15 = Color(hex: "#F9F9F9")
    static let gray30 = Color(hex: "#EAEAEA")
    static let gray45 = Color(hex: "#D8D6D7")
    static let gray60 = Color(hex: "#ABABAE")
    static let gray75 = Color(hex: "#6A6A6E")
    static let gray90 = Color(hex: "#434347")
    static let gray100 = Color(hex: "#0B0B0B")
}
