import Foundation

/// Equivalente exato ao `AuthRepository.kt` real. Diferença em relação ao
/// palpite do lote anterior: `criarConta`/`login` devolvem o `Usuario` em
/// caso de sucesso (equivalente ao `Result<Usuario>` do Kotlin), não só
/// confirmação de que deu certo.
protocol AuthRepository {
    func observarUsuarioLogado() -> AsyncStream<Usuario?>
    func criarConta(email: String, senha: String) async -> Result<Usuario, Error>
    func login(email: String, senha: String) async -> Result<Usuario, Error>
    func logout()
}
