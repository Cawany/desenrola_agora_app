import Foundation
import FirebaseAuth

/// Equivalente ao `FirebaseAuthRepository.kt`.
final class FirebaseAuthRepository: AuthRepository {
    private let auth: Auth

    init(auth: Auth = Auth.auth()) {
        self.auth = auth
    }

    /// Equivalente ao `callbackFlow` + `FirebaseAuth.AuthStateListener`.
    /// `addStateDidChangeListener` é o mesmo mecanismo no SDK iOS.
    func observarUsuarioLogado() -> AsyncStream<Usuario?> {
        AsyncStream { continuation in
            let handle = auth.addStateDidChangeListener { _, usuarioFirebase in
                let usuario = usuarioFirebase.map { Usuario(uid: $0.uid, email: $0.email ?? "") }
                continuation.yield(usuario)
            }
            continuation.onTermination = { _ in
                self.auth.removeStateDidChangeListener(handle)
            }
        }
    }

    func criarConta(email: String, senha: String) async -> Result<Usuario, Error> {
        do {
            let resultado = try await auth.createUser(withEmail: email, password: senha)
            return .success(Usuario(uid: resultado.user.uid, email: email))
        } catch {
            return .failure(error)
        }
    }

    func login(email: String, senha: String) async -> Result<Usuario, Error> {
        do {
            let resultado = try await auth.signIn(withEmail: email, password: senha)
            return .success(Usuario(uid: resultado.user.uid, email: email))
        } catch {
            return .failure(error)
        }
    }

    func logout() {
        try? auth.signOut()
    }
}
