import SwiftUI

/// Pequeno helper que falta nativamente no SwiftUI: criar uma Color a partir
/// de um hex, do mesmo jeito que `Color(0xFFCCCCFF)` funciona direto no Compose.
extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Equivalente ao Color.kt do Android.
enum AppColors {
    static let blackPrimary = Color(hex: 0x000000)
    static let purplePrimary = Color(hex: 0xCCCCFF)
    static let purple80 = Color(hex: 0xD0BCFF)
    static let purpleGrey80 = Color(hex: 0xCCC2DC)
    static let pink80 = Color(hex: 0xEFB8C8)
    static let purple40 = Color(hex: 0x6650A4)
    static let purpleGrey40 = Color(hex: 0x625B71)
    static let pink40 = Color(hex: 0x7D5260)
}
