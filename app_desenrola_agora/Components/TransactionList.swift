import SwiftUI

/// Equivalente à `ListaDeTransacoes` do Android — componente compartilhado
/// entre a Home e a tela de Transações, igual no Kotlin original.
struct TransactionList: View {
    let transacoes: [Transacao]

    var body: some View {
        if transacoes.isEmpty {
            Text("Nenhuma transação nesse período").foregroundStyle(.gray)
        } else {
            VStack(spacing: 8) {
                ForEach(transacoes) { transacao in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(transacao.loja).fontWeight(.medium)
                            Text(transacao.categoria).font(.caption).foregroundStyle(.gray)
                        }
                        Spacer()
                        // Nota de sintaxe: `isReceita` aqui não leva `()` —
                        // no Swift ela virou uma computed property, não uma
                        // função, então é acessada como um campo comum.
                        Text("\(transacao.isReceita ? "+" : "-")\(formatarMoeda(transacao.valor))")
                            .foregroundStyle(transacao.isReceita ? Color(hex: 0x2E7D32) : .red)
                            .fontWeight(.semibold)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
                }
            }
        }
    }
}
