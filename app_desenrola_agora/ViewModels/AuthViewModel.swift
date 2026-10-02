import Foundation
import Observation

/// Equivalente à `AuthViewModel` do Android.
///
/// Nota: no Android, a `AuthViewModelFactory.kt` existe porque o
/// `ViewModelProvider` do sistema exige um construtor sem argumentos para
/// poder recriar o ViewModel sozinho (ex.: rotação de tela). No SwiftUI,
/// quem guarda o ciclo de vida é a própria View (via `@State`), então um
/// `init` recebendo o repositório por injeção de dependência já resolve —
/// não existe (nem é necessário) um `AuthViewModelFactory.swift`.
@Observable
final class AuthViewModel {
    private let repository: AuthRepository

    private(set) var usuario: Usuario?
    private(set) var erro: String?

    private var tarefaObservacao: Task<Void, Never>?

    init(repository: AuthRepository) {
        self.repository = repository
        observarUsuario()
    }

    deinit {
        tarefaObservacao?.cancel()
    }

    private func observarUsuario() {
        tarefaObservacao = Task {
            for await usuarioAtual in repository.observarUsuarioLogado() {
                usuario = usuarioAtual
            }
        }
    }

    func criarConta(email: String, senha: String) {
        Task {
            erro = nil
            if case .failure(let e) = await repository.criarConta(email: email, senha: senha) {
                erro = e.localizedDescription
            }
        }
    }

    func login(email: String, senha: String) {
        Task {
            erro = nil
            if case .failure(let e) = await repository.login(email: email, senha: senha) {
                erro = e.localizedDescription
            }
        }
    }

    func logout() {
        repository.logout()
    }
}
