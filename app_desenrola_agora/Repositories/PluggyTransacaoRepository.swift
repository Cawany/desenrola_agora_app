import Foundation

/// Equivalente às mensagens de erro tratadas em `PluggyTransacaoRepository.kt`
/// (o `when (e.code()) { 410 -> ...; 401 -> ...; 404 -> ... }`).
enum PluggyRepositoryError: LocalizedError {
    case somenteLeitura
    case httpErro(codigo: Int)

    var errorDescription: String? {
        switch self {
        case .somenteLeitura:
            return "Não é possível criar transações via Open Finance - essa fonte é somente leitura"
        case .httpErro(let codigo):
            switch codigo {
            case 410: return "A conta informada no Pluggy não foi encontrada ou foi removida (HTTP 410 Gone)."
            case 401: return "Falha na autenticação com o Pluggy. Verifique as credenciais (HTTP 401 Unauthorized)."
            case 404: return "Recurso não encontrado no Pluggy (HTTP 404 Not Found)."
            default: return "Erro na requisição ao Pluggy: HTTP \(codigo)"
            }
        }
    }
}

/// Implementação do repositório de transações do Pluggy.
/// Todas as requisições são delegadas ao `PluggyBackendClient` (Firebase Cloud Functions v2)
/// garantindo que nenhuma credencial ou API token exista no dispositivo do usuário.
final class PluggyTransacaoRepository: TransacaoRepository {
    private let accountId: String
    private let userId: String?

    init(accountId: String, userId: String?) {
        self.accountId = accountId
        self.userId = userId
    }

    func observarTransacoes() -> AsyncThrowingStream<[Transacao], Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let dtos = try await PluggyBackendClient.shared.buscarTransacoes(accountId: self.accountId)
                    let transacoes = dtos.map { $0.paraTransacao(userId: self.userId ?? "") }
                    continuation.yield(transacoes)
                    continuation.finish()
                } catch let erro as PluggyHTTPError {
                    continuation.finish(throwing: PluggyRepositoryError.httpErro(codigo: erro.statusCode))
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func salvarTransacao(_ transacao: Transacao) async throws {
        throw PluggyRepositoryError.somenteLeitura
    }
}
