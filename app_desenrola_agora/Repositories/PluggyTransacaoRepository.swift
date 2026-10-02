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

/// Equivalente ao `PluggyTransacaoRepository.kt`.
final class PluggyTransacaoRepository: TransacaoRepository {
    private let clientId: String
    private let clientSecret: String
    private let accountId: String
    private let userId: String?

    init(clientId: String, clientSecret: String, accountId: String, userId: String?) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.accountId = accountId
        self.userId = userId
    }

    /// Nota: no Kotlin isso é um `flow { emit(...) }` que produz UM valor só
    /// (diferente do `callbackFlow` do Firestore, que fica escutando pra
    /// sempre). O equivalente fiel aqui é um `AsyncThrowingStream` que faz
    /// `yield` uma única vez e termina — inclusive terminando com erro
    /// quando a requisição falha, que é exatamente o que permite ao
    /// `SicronizadorPluggy` (e ao `TransacaoViewModel`) saberem que algo deu
    /// errado, em vez de silenciosamente ver uma lista vazia.
    func observarTransacoes() -> AsyncThrowingStream<[Transacao], Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let apiKey = try await PluggyAPIClient.shared.autenticar(
                        clientId: clientId, clientSecret: clientSecret
                    )
                    let dtos = try await PluggyAPIClient.shared.buscarTransacoes(
                        apiKey: apiKey, accountId: accountId
                    )
                    let transacoes = dtos.map { $0.paraTransacao(userId: userId ?? "") }
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
