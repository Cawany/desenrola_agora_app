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

/// Equivalente ao `FirebaseCategoriaRepository.kt`.
final class FirebaseCategoriaRepository: CategoriaRepository {
    private let db: Firestore
    private let auth: Auth

    private var colecao: CollectionReference { db.collection("categorias") }

    init(db: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
        self.db = db
        self.auth = auth
    }

    /// Mesmo padrão de "listener dentro de listener" do Android: o listener
    /// do Firestore é recriado toda vez que o estado de autenticação muda,
    /// evitando a condição de corrida documentada lá na Aula 4.
    ///
    /// Assim como no Kotlin (`Categoria` não usa nenhuma anotação de
    /// document-ID), o `id` não vem preenchido pela desserialização — ele é
    /// atribuído manualmente a partir de `doc.documentID`, igual ao
    /// `.copy(id = it.id)` do original.
    func observarCategorias() -> AsyncStream<[Categoria]> {
        AsyncStream { continuation in
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
                        // Igual ao original: erro de permissão logo após o
                        // login é esperado (token ainda propagando) — nesse
                        // caso, e em qualquer outro erro aqui, simplesmente
                        // ignoramos essa atualização e aguardamos a próxima.
                        if erro != nil { return }

                        let categorias: [Categoria] = snapshot?.documents.compactMap { doc in
                            var categoria = try? doc.data(as: Categoria.self)
                            categoria?.id = doc.documentID
                            return categoria
                        } ?? []
                        continuation.yield(categorias)
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

    func salvarCategoria(_ categoria: Categoria) async throws {
        guard let uid = auth.currentUser?.uid else {
            throw NSError(domain: "FirebaseCategoriaRepository", code: 0,
                           userInfo: [NSLocalizedDescriptionKey: "Usuário não autenticado"])
        }
        var categoriaComUsuario = categoria
        categoriaComUsuario.userId = uid
        try await colecao.addDocumentAsync(from: categoriaComUsuario)
    }

    func atualizarCategoria(id: String, nome: String) async throws {
        try await colecao.document(id).updateData(["nome": nome])
    }

    func excluirCategoria(id: String) async throws {
        try await colecao.document(id).delete()
    }
}
