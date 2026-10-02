import SwiftUI

struct DashboardView: View {
    let viewModel: TransacaoViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dashboard").font(.title2).bold()
                    Text("Análise dos seus gastos no mês")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                switch viewModel.viewState {
                case .carregando:
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                case .erro(let mensagem):
                    Text(mensagem)
                        .foregroundStyle(.red)
                case .sucesso(let transacoes):
                    let total = viewModel.totalGasto(no: transacoes)
                    let porCategoria = viewModel.valorPorCategoria(transacoes)
                    let porDia = viewModel.gastoPorDia(transacoes)
                    let topLojas = viewModel.topLojas(transacoes)

                    HStack(spacing: 12) {
                        MetricCard(titulo: "Total gasto", valor: formatarMoeda(total))
                        MetricCard(titulo: "Transações", valor: "\(transacoes.count)")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gasto por dia").fontWeight(.semibold)
                        
                        VStack{
                            DailyBarChart(dados: porDia)
                        }
                        .padding(26)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray, lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gasto por categoria").fontWeight(.semibold)
                        
                        VStack {
                            CategoryPieChart(dados: porCategoria)
                        }
                        .padding(26)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top lojas").fontWeight(.semibold)
                        
                        VStack {
                            StoreRanking(dados: topLojas)
                        }
                        .padding(26)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray, lineWidth: 1))
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct MetricCard: View {
    let titulo: String
    let valor: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titulo).font(.caption).foregroundStyle(.secondary)
            Text(valor)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }
}

private struct StoreRanking: View {
    let dados: [(loja: String, valor: Double)]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(dados.enumerated()), id: \.offset) { index, item in
                HStack {
                    Text("\(index + 1). \(item.loja)")
                        .lineLimit(1)
                    Spacer()
                    Text(formatarMoeda(item.valor))
                        .fontWeight(.medium)
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct DailyBarChart: View {
    let dados: [(dia: String, valor: Double)]

    var body: some View {
        if dados.isEmpty {
            Text("Sem dados no período.")
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
        } else {
            let maximo = dados.map(\.valor).max() ?? 1
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(dados, id: \.dia) { item in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.accentColor)
                                .frame(width: 22, height: max(8, CGFloat(item.valor / maximo) * 100))
                            Text(item.dia)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            .frame(height: 140)
        }
    }
}
