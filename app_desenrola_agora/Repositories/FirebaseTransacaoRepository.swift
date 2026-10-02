import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
private final class ListenerBox {
    private var listener: ListenerRegistration?

    func set(_ listener: ListenerRegistration?) {
        self.listener?.remove()
        self.listener = listener
    }

    func cancel() {
        self.listener?.remove()
        self.listener = nil
    }
}

/// Equivalente ao `FirebaseTransacaoRepository.kt`.
final class FirebaseTransacaoRepository: TransacaoRepository {
    private let db: Firestore
    private let auth: Auth

    private var colecao: CollectionReference { db.collection("transacoes") }

    init(db: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
        self.db = db
        self.auth = auth
    }

    /// Esta implementação especificamente NUNCA lança erro pelo stream
    /// (mesmo comportamento do Kotlin original, que tem o `close(erro)`
    /// literalmente comentado — dead code proposital, deixado assim de
    /// propósito no arquivo original). O `AsyncThrowingStream` é o tipo
    /// exigido pelo protocolo (por causa do `PluggyTransacaoRepository`),
    /// mas aqui ele só encerra por erro se você reativar esse trecho.
    func observarTransacoes() -> AsyncThrowingStream<[Transacao], Error> {
        AsyncThrowingStream { continuation in
            let listenerBox = ListenerBox()
            let auth = self.auth

            let authHandle = auth.addStateDidChangeListener { _, usuarioFirebase in
                listenerBox.cancel()

                guard let uid = usuarioFirebase?.uid else {
                    continuation.yield([])
                    return
                }

                let listener = self.colecao
                    .whereField("userId", isEqualTo: uid)
                    .addSnapshotListener { snapshot, erro in
                        if erro != nil {
                            // if erro.code != .permissionDenied { /* continuation.finish(throwing: erro!) */ }
                            return
                        }
                        let transacoes: [Transacao] = snapshot?.documents.compactMap {
                            try? $0.data(as: Transacao.self)
                        } ?? []
                        continuation.yield(transacoes)
                    }
                listenerBox.set(listener)
            }

            continuation.onTermination = { _ in
                Task { @MainActor in
                    auth.removeStateDidChangeListener(authHandle)
                    listenerBox.cancel()
                }
            }
        }
    }

    func salvarTransacao(_ transacao: Transacao) async throws {
        guard let uid = auth.currentUser?.uid else {
            throw NSError(domain: "FirebaseTransacaoRepository", code: 0,
                           userInfo: [NSLocalizedDescriptionKey: "Usuário não autenticado"])
        }
        var transacaoComUsuario = transacao
        transacaoComUsuario.userId = uid
        try await colecao.addDocumentAsync(from: transacaoComUsuario)
    }

    /// Método extra, fora do protocolo `TransacaoRepository` — igual ao
    /// Kotlin, que também declara `salvarOuAtualizarComId` direto na classe
    /// concreta, sem passar pela interface. É quem o `SicronizadorPluggy`
    /// chama, e é ele que garante a idempotência (`.document(id).set(...)`,
    /// em vez de `.add()`).
    func salvarOuAtualizarComId(_ transacao: Transacao) async throws {
        guard let uid = auth.currentUser?.uid else { return }
        var transacaoComUsuario = transacao
        transacaoComUsuario.userId = uid
        try await colecao.document(transacao.id).setDataAsync(from: transacaoComUsuario)
    }
}
