import Foundation
import Observation

@Observable
final class CategoriaViewModel {
    private let repository: CategoriaRepository

    private(set) var categorias: [Categoria] = []
    private var tarefaObservacao: Task<Void, Never>?

    init(repository: CategoriaRepository) {
        self.repository = repository
        observarCategorias()
    }

    deinit { tarefaObservacao?.cancel() }

    private func observarCategorias() {
        tarefaObservacao = Task {
            for await lista in repository.observarCategorias() {
                categorias = lista
            }
        }
    }

    func adicionarCategoria(nome: String) {
        Task { try? await repository.salvarCategoria(Categoria(nome: nome)) }
    }

    func atualizarCategoria(id: String, novoNome: String) {
        Task { try? await repository.atualizarCategoria(id: id, nome: novoNome) }
    }

    func excluirCategoria(id: String) {
        Task { try? await repository.excluirCategoria(id: id) }
    }
}
