import Foundation

/// Equivalente ao `data class Categoria` do Android — agora com os campos
/// reais de `Categoria.kt` (o palpite do lote anterior só tinha id/nome).
struct Categoria: Identifiable, Codable, Equatable {
    var id: String = ""
    var userId: String = ""
    var nome: String = ""
    var icone: String = ""
    var cor: String = ""
}
