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

/// Equivalente ao `FirebaseContaConectadaRepository.kt`. Mesma modelagem do
/// Android: subcoleção `usuarios/{uid}/contasConectadas`, não um array
/// dentro do documento do usuário — permite múltiplos bancos, cada um como
/// escrita isolada.
///
/// Regra de segurança equivalente no Firestore (adicione junto com as de
/// `/transacoes` e `/categorias`):
/// ```
/// match /usuarios/{uid}/contasConectadas/{accountId} {
///   allow read, write: if request.auth != null && request.auth.uid == uid;
/// }
/// ```
final class FirebaseContaConectadaRepository: ContaConectadaRepository {
    private let db: Firestore
    private let auth: Auth

    init(db: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
        self.db = db
        self.auth = auth
    }

    private func colecaoDoUsuario(_ uid: String) -> CollectionReference {
        db.collection("usuarios").document(uid).collection("contasConectadas")
    }

    /// `.document(accountId).set(...)` — idempotente, mesmo padrão do
    /// `salvarOuAtualizarComId` da `FirebaseTransacaoRepository`: conectar o
    /// mesmo banco duas vezes atualiza o mesmo documento, não duplica.
    func salvar(_ conta: ContaConectada) async throws {
        guard let uid = auth.currentUser?.uid else { return }
        try await colecaoDoUsuario(uid).document(conta.accountId).setDataAsync(from: conta)
    }

    func observarContas() -> AsyncStream<[ContaConectada]> {
        AsyncStream { continuation in
            let listenerBox = ListenerBox()
            let auth = self.auth

            let authHandle = auth.addStateDidChangeListener { _, usuarioFirebase in
                listenerBox.cancel()

                guard let uid = usuarioFirebase?.uid else {
                    continuation.yield([])
                    return
                }

                let listener = self.colecaoDoUsuario(uid)
                    .addSnapshotListener { snapshot, erro in
                        if erro != nil { return }
                        let contas: [ContaConectada] = snapshot?.documents.compactMap {
                            try? $0.data(as: ContaConectada.self)
                        } ?? []
                        continuation.yield(contas)
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

    func remover(accountId: String) async throws {
        guard let uid = auth.currentUser?.uid else { return }
        try await colecaoDoUsuario(uid).document(accountId).delete()
    }
}
