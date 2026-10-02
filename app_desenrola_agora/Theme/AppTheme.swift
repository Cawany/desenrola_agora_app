import SwiftUI

/// Equivalente ao Theme.kt (`Finance_appTheme`).
///
/// Diferença de arquitetura importante: o Android decide em runtime, dentro
/// do código, qual esquema de cor usar (`darkColorScheme` vs
/// `lightColorScheme`), porque o Compose não tem um sistema de assets visual
/// equivalente ao Asset Catalog do Xcode. O jeito mais idiomático no SwiftUI
/// seria criar "Color Sets" no Asset Catalog (variantes "Any"/"Dark") e deixar
/// o sistema trocar sozinho, sem nenhum `if/else`. Aqui replico a lógica
/// explícita do Android para manter a tradução 1:1 — migrar essas cores para
/// o Asset Catalog é uma melhoria recomendada para depois.
struct AppTheme {
    let primary: Color
    let onPrimary: Color
    let secondary: Color
    let onSecondary: Color
    let surface: Color

    static let light = AppTheme(
        primary: AppColors.purplePrimary,
        onPrimary: Color(hex: 0x330066),
        secondary: AppColors.purple40,
        onSecondary: .white,
        surface: .white
    )

    static let dark = AppTheme(
        primary: AppColors.purple80,
        onPrimary: .black,
        secondary: AppColors.purpleGrey80,
        onSecondary: .black,
        surface: AppColors.blackPrimary
    )
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.light
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

private struct FinanceThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.environment(\.appTheme, colorScheme == .dark ? .dark : .light)
    }
}

extension View {
    /// Equivalente a envolver o app inteiro com `Finance_appTheme { content() }`.
    func financeAppTheme() -> some View {
        modifier(FinanceThemeModifier())
    }
}
