import Foundation

/// Equivalente à `sealed class Tela` do Kotlin.
/// Cada "objeto" do sealed class só carregava uma String (a rota) — um enum
/// com `rawValue: String` cobre exatamente o mesmo papel, sem precisar de
/// uma classe separada por caso.
enum Route: String, Hashable {
    case home
    case transacoes
    case dashboard
    case categoria
    case conectarBanco
}
