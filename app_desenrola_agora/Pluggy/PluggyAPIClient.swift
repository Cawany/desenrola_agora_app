import Foundation

/// Erro de rede com o status HTTP — equivalente ao `HttpException` que o
/// Retrofit lança sozinho, e que o `PluggyTransacaoRepository.kt` inspeciona
/// (`e.code()`) para dar mensagens específicas por status (410, 401, 404).
struct PluggyHTTPError: Error {
    let statusCode: Int
}

/// Equivalente ao `PluggyApi` (interface Retrofit) + `PluggyApiClient` do
/// Android, usando `URLSession` nativo em vez de Retrofit. Uso `actor` pelo
/// mesmo motivo do singleton (`object`) no Kotlin, com a garantia extra do
/// Swift Concurrency de que chamadas concorrentes não pisam uma na outra.
actor PluggyAPIClient {
    static let shared = PluggyAPIClient()

    private let baseURL = URL(string: "https://api.pluggy.ai")!

    func autenticar(clientId: String, clientSecret: String) async throws -> String {
        let resposta: PluggyAuthResponse = try await post(
            caminho: "auth",
            corpo: PluggyAuthRequest(clientId: clientId, clientSecret: clientSecret)
        )
        return resposta.apiKey
    }

    func criarConnectToken(apiKey: String, clientUserId: String?) async throws -> String {
        let resposta: PluggyConnectTokenResponse = try await post(
            caminho: "connect_token",
            corpo: PluggyConnectTokenRequest(clientUserId: clientUserId),
            apiKey: apiKey
        )
        return resposta.accessToken
    }

    func buscarContas(apiKey: String, itemId: String) async throws -> [PluggyContaDto] {
        var componentes = URLComponents(url: baseURL.appendingPathComponent("accounts"), resolvingAgainstBaseURL: false)
        componentes?.queryItems = [URLQueryItem(name: "itemId", value: itemId)]

        let resposta: PluggyContasResponse = try await get(url: componentes!.url!, apiKey: apiKey)
        return resposta.results
    }

    /// Equivalente ao `buscarTransacoes()`, no endpoint `v2/transactions` —
    /// o mesmo que precisou ser migrado do `/transactions` antigo (HTTP 410
    /// Gone) durante a integração original no Android.
    func buscarTransacoes(apiKey: String, accountId: String) async throws -> [PluggyTransacaoDto] {
        var componentes = URLComponents(url: baseURL.appendingPathComponent("v2/transactions"), resolvingAgainstBaseURL: false)
        componentes?.queryItems = [URLQueryItem(name: "accountId", value: accountId)]

        let resposta: PluggyTransacaoResponse = try await get(url: componentes!.url!, apiKey: apiKey)
        return resposta.results
    }

    // MARK: - Infraestrutura privada

    private func post<Corpo: Encodable, Resposta: Decodable>(
        caminho: String,
        corpo: Corpo,
        apiKey: String? = nil
    ) async throws -> Resposta {
        var request = URLRequest(url: baseURL.appendingPathComponent(caminho))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey { request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY") }
        request.httpBody = try JSONEncoder().encode(corpo)

        let (data, response) = try await URLSession.shared.data(for: request)
        try verificarStatus(response)
        return try JSONDecoder().decode(Resposta.self, from: data)
    }

    private func get<Resposta: Decodable>(url: URL, apiKey: String) async throws -> Resposta {
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")

        let (data, response) = try await URLSession.shared.data(for: request)
        try verificarStatus(response)
        return try JSONDecoder().decode(Resposta.self, from: data)
    }

    /// URLSession, ao contrário do Retrofit, NÃO lança erro sozinho quando
    /// o servidor responde 4xx/5xx — só em falha de rede/conexão. Aqui
    /// replicamos manualmente o que o Retrofit fazia de graça.
    private func verificarStatus(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            throw PluggyHTTPError(statusCode: http.statusCode)
        }
    }
}
