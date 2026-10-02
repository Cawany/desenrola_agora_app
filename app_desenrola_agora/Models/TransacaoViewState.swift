import Foundation

/// Equivalente à `sealed class TransacaoUIState` do Android.
/// Em Swift, um `enum` com "associated values" cumpre o mesmo papel de um
/// sealed class cujas subclasses carregam dados diferentes entre si.
enum TransacaoViewState {
    case carregando
    case sucesso(transacoes: [Transacao])
    case erro(mensagem: String)
}
