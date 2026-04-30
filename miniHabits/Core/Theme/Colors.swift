import SwiftUI

extension Color {
    static let background = Color(hex: "#000000")
    static let card = Color(hex: "#0a0a0a")
    static let secondaryBg = Color(hex: "#1a1a1a")
    static let muted = Color(hex: "#262626")
    static let mutedForeground = Color(hex: "#a3a3a3")
    static let borderColor = Color(hex: "#262626")
    static let destructive = Color(hex: "#ef4444")
    static let accentBg = Color(hex: "#171717")
    static let inputBg = Color(hex: "#1a1a1a")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

func hexColor(_ hex: String) -> Color { Color(hex: hex) }
