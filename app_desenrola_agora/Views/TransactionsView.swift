import SwiftUI

struct TransactionsView: View {
    let viewModel: TransacaoViewModel

    @State private var periodoSelecionado: PeriodoFiltro = .mesAtual
    @State private var categoriaSelecionada: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Transações").font(.title2)
                Text("Acompanhe todos os seus gastos").foregroundStyle(.gray)

                switch viewModel.viewState {
                case .carregando:
                    ProgressView()
                case .erro(let mensagem):
                    Text(mensagem)
                case .sucesso(let todas):
                    let categorias = Array(Set(todas.map(\.categoria))).sorted()

                    HStack {
                        // Equivalente ao ExposedDropdownMenuBox de período.
                        Picker("Período", selection: $periodoSelecionado) {
                            Text("Este mês").tag(PeriodoFiltro.mesAtual)
                            Text("Mês passado").tag(PeriodoFiltro.mesPassado)
                            Text("Últimos 7 dias").tag(PeriodoFiltro.ultimos7Dias)
                            Text("Este ano").tag(PeriodoFiltro.anoAtual)
                            Text("Todas").tag(PeriodoFiltro.tudo)
                        }
                        .pickerStyle(.menu)

                        // Equivalente ao ExposedDropdownMenuBox de categoria.
                        Picker("Categoria", selection: $categoriaSelecionada) {
                            Text("Todas as categorias").tag(String?.none)
                            ForEach(categorias, id: \.self) { cat in
                                Text(cat).tag(String?.some(cat))
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    let porPeriodo = filtrar(todas, por: periodoSelecionado)
                    let filtradas = categoriaSelecionada.map { cat in
                        porPeriodo.filter { $0.categoria == cat }
                    } ?? porPeriodo

                    TransactionList(transacoes: filtradas)
                }
            }
            .padding(16)
        }
    }
}
