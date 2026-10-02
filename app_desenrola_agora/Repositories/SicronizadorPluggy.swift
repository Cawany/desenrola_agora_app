import Foundation

/// Equivalente ao `SicronizadorPluggy.kt`.
final class SicronizadorPluggy {
    private let pluggyRepository: PluggyTransacaoRepository
    private let firebaseRepository: FirebaseTransacaoRepository

    init(pluggyRepository: PluggyTransacaoRepository, firebaseRepository: FirebaseTransacaoRepository) {
        self.pluggyRepository = pluggyRepository
        self.firebaseRepository = firebaseRepository
    }

    /// Equivalente ao `.first()` do Kotlin (pega só o primeiro valor
    /// emitido pelo Flow, e propaga a exceção se o Flow lançar uma antes
    /// disso). `AsyncThrowingStream` não tem esse operador pronto — o
    /// `for try await` com `break` no primeiro item cumpre o mesmo papel, e
    /// o `try` na frente garante que um erro do Pluggy (ex.: HTTP 410)
    /// propaga pra quem chamou `sincronizar()`, exatamente como no Kotlin.
    func sincronizar() async throws -> Int {
        var transacoesDaPluggy: [Transacao] = []
        for try await lista in pluggyRepository.observarTransacoes() {
            transacoesDaPluggy = lista
            break
        }

        for transacao in transacoesDaPluggy {
            try await firebaseRepository.salvarOuAtualizarComId(transacao)
        }
        return transacoesDaPluggy.count
    }
}
