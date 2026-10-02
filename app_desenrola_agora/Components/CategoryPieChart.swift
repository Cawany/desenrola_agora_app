import SwiftUI

/// Equivalente ao `GraficoPizzaCategoria` (Canvas + drawArc) do Android.
/// SwiftUI também tem um `Canvas` nativo com API bem parecida — o
/// `drawArc(startAngle, sweepAngle, useCenter)` do Compose vira um
/// `Path.addArc` desenhado com `context.fill` aqui.
struct CategoryPieChart: View {
    let dados: [(categoria: String, valor: Double)]
    
    // cor fixa por categoria
    private let coresPorCategoria: [String: Color] = [
        "Mercado": Color(hex: 0x4A90D9), "Alimentação": Color(hex: 0x4A90D9), "Transporte": Color(hex: 0x2E8B57),
        "Moradia": Color(hex: 0xD9A441), "Contas de casa": Color(hex: 0xD9A441), "Celular/Internet": Color(hex: 0x8E44AD),
        "Lazer": Color(hex: 0xE74C3C), "Saúde": Color(hex: 0x16A085), "Cartão de crédito": Color(hex: 0x7F8C8D), "Outros": Color(hex: 0xB0AFAF)
    ]
    
    // cor reserva
    private let paletaReserva: [Color] = [
        Color(hex: 0xCCCCFF), Color(hex: 0xB3B3E6), Color(hex: 0x9999CC),
        Color(hex: 0x8080B3), Color(hex: 0x666699),
    ]
    
    private func cor(paraCategoria categoria: String) -> Color {
        if let corFixa = coresPorCategoria[categoria] {
            return corFixa
        }
        let indice = abs(categoria.hashValue) % paletaReserva.count
        return paletaReserva[indice]
    }

    var body: some View {
        let total = dados.reduce(0) { $0 + $1.valor }

        if dados.isEmpty || total <= 0 {
            Text("Sem dados no período")
                .foregroundStyle(.gray)
        } else {
            HStack(alignment: .center, spacing: 16) {
                Canvas { context, size in
                    var anguloInicial = Angle.degrees(-90)
                    let raio = min(size.width, size.height) / 2
                    let centro = CGPoint(x: size.width / 2, y: size.height / 2)

                    for item in dados {
                        let angulo = Angle.degrees(item.valor / total * 360)
                        var path = Path()
                        path.move(to: centro)
                        path.addArc(
                            center: centro,
                            radius: raio,
                            startAngle: anguloInicial,
                            endAngle: anguloInicial + angulo,
                            clockwise: false
                        )
                        path.closeSubpath()
                        context.fill(path, with: .color(cor(paraCategoria: item.categoria)))
                        anguloInicial += angulo
                    }
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(dados.enumerated()), id: \.offset) { _, item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(cor(paraCategoria: item.categoria))
                                .frame(width: 10, height: 10)
                            Text("\(item.categoria): \(formatarMoeda(item.valor))")
                                .font(.caption)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
