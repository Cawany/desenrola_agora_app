import Foundation

/// Equivalente ao `ContaConectada.kt` (Aula 10 do lado Android).
struct ContaConectada: Codable, Equatable, Identifiable {
    var accountId: String = ""
    var itemId: String = ""
    var tipo: String = ""              // "BANK" ou "CREDIT"
    var nomeInstituicao: String = ""
    var conectadoEm: Double = Date().timeIntervalSince1970 * 1000

    /// `Identifiable` pede uma propriedade `id` — o próprio `accountId` já
    /// cumpre esse papel, do mesmo jeito que ele é usado como ID do
    /// documento no Firestore.
    var id: String { accountId }
}
