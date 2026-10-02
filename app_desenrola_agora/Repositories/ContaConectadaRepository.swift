import Foundation

/// Equivalente ao `ContaConectadaRepository.kt`.
protocol ContaConectadaRepository {
    func salvar(_ conta: ContaConectada) async throws
    func observarContas() -> AsyncStream<[ContaConectada]>
    func remover(accountId: String) async throws
}
