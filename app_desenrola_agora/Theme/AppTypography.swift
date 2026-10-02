import SwiftUI

/// Equivalente ao Type.kt. SwiftUI não tem um objeto de tipografia central
/// como o Material3 — aqui replicamos o mesmo papel com estáticos de `Font`.
enum AppTypography {
    static let bodyLarge = Font.system(size: 16, weight: .regular)

    // Estilos que estavam comentados no Kotlin original, mantidos como
    // referência para quando forem realmente usados:
    // static let titleLarge = Font.system(size: 22, weight: .regular)
    // static let labelSmall = Font.system(size: 11, weight: .medium)
}
