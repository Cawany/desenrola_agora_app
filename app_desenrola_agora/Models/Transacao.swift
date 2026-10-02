import Foundation

/// Equivalente ao `data class Transacao` do Android — reescrito a partir do
/// arquivo real `Transacao.kt`. Duas correções em relação ao lote anterior:
///
/// 1. `data` é um `Long` (milissegundos desde epoch), não um `Timestamp` do
///    Firestore — o Firestore grava um campo `Long` do Kotlin como número
///    simples. O equivalente correto em Swift é `Int64`, com uma
///    propriedade de conveniência (`dataComoDate`) para quando eu precisar
///    de `Date` de verdade nas contas de período.
/// 2. `isReceita` agora replica EXATAMENTE a lógica original — inclusive a
///    assimetria proposital entre `categoria` (4 termos: salary, salário,
///    salario, renda) e `loja` (só 2 termos: salario, salário — sem
///    "renda" nem "salary"). Não é bug de tradução, é fiel ao Kotlin.
struct Transacao: Codable, Identifiable, Equatable {
    var id: String = ""
    var userId: String = ""
    var valor: Double = 0.0
    var loja: String = ""
    var categoria: String = ""
    var banco: String = ""
    var formaPagamento: String = ""
    var data: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    var tipo: String = "DESPESA"

    /// Conveniência que não existe no Kotlin original (lá vocês usam o
    /// `Long` cru direto, como em `java.util.Date(it.data)`).
    var dataComoDate: Date {
        Date(timeIntervalSince1970: Double(data) / 1000)
    }

    /// Equivalente exato ao `fun isReceita(): Boolean` do Kotlin.
    var isReceita: Bool {
        if tipo.caseInsensitiveCompare("RECEITA") == .orderedSame
            || tipo.caseInsensitiveCompare("ENTRADA") == .orderedSame {
            return true
        }
        let c = categoria.lowercased()
        let l = loja.lowercased()
        return c.contains("salary") || c.contains("salário") || c.contains("salario") || c.contains("renda")
            || l.contains("salario") || l.contains("salário")
    }
}
