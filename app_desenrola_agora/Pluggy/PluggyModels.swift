import Foundation

// MARK: - Transações

nonisolated struct PluggyTransacaoDto: Decodable, Sendable {
    let id: String
    let description: String
    let amount: Double
    let date: String
    let category: String?
    let paymentData: PluggyPaymentDataDto?
}

nonisolated struct PluggyPaymentDataDto: Decodable, Sendable {
    let paymentMethod: String?
}

nonisolated struct PluggyTransacaoResponse: Decodable, Sendable {
    let results: [PluggyTransacaoDto]
}

// MARK: - Connect Token / Contas

nonisolated struct PluggyConnectTokenRequest: Encodable, Sendable {
    let clientUserId: String?
}

nonisolated struct PluggyConnectTokenResponse: Decodable, Sendable {
    let accessToken: String
}

nonisolated struct PluggyContaDto: Decodable, Sendable {
    let id: String
    let type: String
    let subtype: String?
    let name: String
}

nonisolated struct PluggyContasResponse: Decodable, Sendable {
    let results: [PluggyContaDto]
}

// MARK: - Mapeamento DTO -> modelo do app

extension PluggyTransacaoDto {
    func paraTransacao(userId: String) -> Transacao {
        let formatoData = DateFormatter()
        formatoData.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatoData.locale = Locale(identifier: "en_US_POSIX")
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
