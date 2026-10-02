import Foundation

/// Equivalente exato ao `TransacaoRepository.kt` real.
///
/// Correção em relação ao lote anterior: `observarTransacoes()` agora
/// devolve `AsyncThrowingStream`, não `AsyncStream`. Motivo: o
/// `PluggyTransacaoRepository.kt` usa `flow { ... throw Exception(...) }`,
/// e um `Flow` que pode lançar exceção internamente só tem equivalente
/// fiel em Swift Concurrency no `AsyncThrowingStream` — `AsyncStream` puro
/// não tem como propagar erro nenhum.
protocol TransacaoRepository {
    func observarTransacoes() -> AsyncThrowingStream<[Transacao], Error>
    func salvarTransacao(_ transacao: Transacao) async throws
}
