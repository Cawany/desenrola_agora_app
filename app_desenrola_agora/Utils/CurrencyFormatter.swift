import Foundation

/// Equivalente à função solta `formatarMoeda` do TelaHome.kt (usada também
/// pela TelaDashboard.kt no original, por estarem no mesmo pacote).
func formatarMoeda(_ valor: Double) -> String {
    let formato = NumberFormatter()
    formato.numberStyle = .currency
    formato.locale = Locale(identifier: "pt_BR")
    return formato.string(from: NSNumber(value: valor)) ?? "R$ 0,00"
}
