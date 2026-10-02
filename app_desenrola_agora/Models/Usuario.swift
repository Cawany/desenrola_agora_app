import Foundation

/// Equivalente ao `data class Usuario` do Android — agora com o campo
/// `email`, que o palpite do lote anterior não tinha.
struct Usuario: Equatable {
    var uid: String = ""
    var email: String = ""
}
