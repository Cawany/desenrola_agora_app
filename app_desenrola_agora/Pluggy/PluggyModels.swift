import Foundation

// MARK: - Autenticação (PluggyApi.kt)

struct PluggyAuthRequest: Encodable {
    let clientId: String
    let clientSecret: String
}

struct PluggyAuthResponse: Decodable {
    let apiKey: String
}

// MARK: - Transações (PluggyAuthResponse.kt no Android — nome do arquivo mantido por herança histórica, os DTOs de transação vivem lá)

struct PluggyTransacaoDto: Decodable {
    let id: String
    let description: String
    let amount: Double
    let date: String
    let category: String?
    let paymentData: PluggyPaymentDataDto?
}

struct PluggyPaymentDataDto: Decodable {
    let paymentMethod: String?
}

struct PluggyTransacaoResponse: Decodable {
    let results: [PluggyTransacaoDto]
}

// MARK: - Connect Token / Contas (PluggyConnectTokenRequest.kt)

struct PluggyConnectTokenRequest: Encodable {
    let clientUserId: String?
}

struct PluggyConnectTokenResponse: Decodable {
    let accessToken: String
}

struct PluggyContaDto: Decodable {
    let id: String
    let type: String
    let subtype: String?
    let name: String
}

struct PluggyContasResponse: Decodable {
    let results: [PluggyContaDto]
}

// MARK: - Mapeamento DTO -> modelo do app

extension PluggyTransacaoDto {
    /// Equivalente à função de extensão privada `PluggyTransacaoDto.paraTransacao()`
    /// do `PluggyTransacaoRepository.kt`.
    func paraTransacao(userId: String) -> Transacao {
        let formatoData = DateFormatter()
        formatoData.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatoData.locale = Locale(identifier: "en_US_POSIX") // equivalente ao Locale.US do Kotlin
        formatoData.timeZone = TimeZone(identifier: "UTC")

        let dataEmMillis: Int64
        if let dataConvertida = formatoData.date(from: date) {
            dataEmMillis = Int64(dataConvertida.timeIntervalSince1970 * 1000)
        } else {
            dataEmMillis = Int64(Date().timeIntervalSince1970 * 1000)
        }

        let tipo = amount >= 0 ? "RECEITA" : "DESPESA"

        return Transacao(
            id: id,
            userId: userId,
            valor: abs(amount),
            loja: description,
            categoria: category ?? "Outros",
            banco: "Conectado via Open Finance",
            formaPagamento: paymentData?.paymentMethod ?? "",
            data: dataEmMillis,
            tipo: tipo
        )
    }
}
