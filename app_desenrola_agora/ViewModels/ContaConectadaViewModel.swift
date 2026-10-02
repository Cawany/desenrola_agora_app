import Foundation
import Observation

@Observable
final class ContaConectadaViewModel {
    private let repository: ContaConectadaRepository

    private(set) var contas: [ContaConectada] = []
    private var tarefaObservacao: Task<Void, Never>?

    init(repository: ContaConectadaRepository) {
        self.repository = repository
        observarContas()
    }

    deinit { tarefaObservacao?.cancel() }

    private func observarContas() {
        tarefaObservacao = Task {
            for await lista in repository.observarContas() {
                contas = lista
            }
        }
    }

    func remover(accountId: String) {
        Task { try? await repository.remover(accountId: accountId) }
    }
}
