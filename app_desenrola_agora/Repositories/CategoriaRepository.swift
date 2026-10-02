import Foundation

/// Equivalente exato ao `CategoriaRepository.kt` real. Só renomeei o
/// parâmetro de `atualizarCategoria` (`novoNome` -> `nome`) para bater com
/// a assinatura real.
protocol CategoriaRepository {
    func observarCategorias() -> AsyncStream<[Categoria]>
    func salvarCategoria(_ categoria: Categoria) async throws
    func atualizarCategoria(id: String, nome: String) async throws
    func excluirCategoria(id: String) async throws
}
