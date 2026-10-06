import Foundation
import FirebaseAuth

/// Erro de rede HTTP lançado nas requisições do aplicativo.
struct PluggyHTTPError: Error {
    let statusCode: Int
}

/// Cliente de comunicação com o backend Firebase Cloud Functions (v2) para a integração Pluggy.
/// Nenhuma credencial privada (`clientId` ou `clientSecret`) reside no cliente iOS.
actor PluggyBackendClient {
    static let shared = PluggyBackendClient()

    private let baseURL = URL(string: "https://southamerica-east1-desenrola-agora.cloudfunctions.net")!

    /// Solicita ao backend Firebase a geração de um Connect Token para o widget Pluggy.
    func gerarConnectToken(clientUserId: String? = nil) async throws -> String {
        var request = URLRequest(url: baseURL.appendingPathComponent("gerarConnectToken"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any?] = ["clientUserId": clientUserId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })

        let (data, response) = try await URLSession.shared.data(for: request)
        try verificarStatus(response)

        let resposta: PluggyConnectTokenResponse = try Self.decodificar(data)
        return resposta.accessToken
    }

    /// Solicita ao backend Firebase a busca das contas associadas a um Item.
    func buscarContas(itemId: String) async throws -> [PluggyContaDto] {
        var componentes = URLComponents(url: baseURL.appendingPathComponent("buscarContas"), resolvingAgainstBaseURL: false)
        componentes?.queryItems = [URLQueryItem(name: "itemId", value: itemId)]

        guard let url = componentes?.url else { return [] }
        var request = URLRequest(url: url)

        if let token = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        try verificarStatus(response)

        let resposta: PluggyContasResponse = try Self.decodificar(data)
        return resposta.results
    }

    /// Solicita ao backend Firebase a busca das transações relativas a uma conta.
    func buscarTransacoes(accountId: String) async throws -> [PluggyTransacaoDto] {
        var componentes = URLComponents(url: baseURL.appendingPathComponent("buscarTransacoes"), resolvingAgainstBaseURL: false)
        componentes?.queryItems = [URLQueryItem(name: "accountId", value: accountId)]

        guard let url = componentes?.url else { return [] }
        var request = URLRequest(url: url)

        if let token = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        try verificarStatus(response)

        let resposta: PluggyTransacaoResponse = try Self.decodificar(data)
        return resposta.results
    }

    private static nonisolated func decodificar<T: Decodable>(_ data: Data) throws -> T {
        try JSONDecoder().decode(T.self, from: data)
    }

    private func verificarStatus(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            throw PluggyHTTPError(statusCode: http.statusCode)
        }
    }
}
