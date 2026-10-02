import SwiftUI

/// Equivalente à `BarraNavegacaoInferior.kt`.
///
/// Nota de arquitetura: o `TabView` nativo do SwiftUI desenha uma barra no
/// estilo padrão da Apple e NÃO permite o formato de pill flutuante nem o
/// botão "+" destacado do design original (extraído do CSS React). Por isso
/// a navegação principal do app não usa `TabView` — usa um estado simples
/// (`Route` selecionada) com esta barra desenhada por cima do conteúdo via
/// `ZStack`, cumprindo o mesmo papel do `Scaffold(bottomBar = {...})`.
struct BottomNavigationBar: View {
    let rotaAtual: Route
    let aoNavegar: (Route) -> Void
    let aoClicarEmAdicionar: () -> Void

    private let corFundoBotaoAdicionar = Color(hex: 0xD0BCFF)
    private let corIconeAdicionar = Color(hex: 0x5B5B9E)
    private let corIconeInativo = Color(hex: 0xBDBDBD)
    private let corIconeSelecionado = Color(hex: 0xD0BCFF)

    var body: some View {
        ZStack {
            HStack(spacing: 4) {
                item(icone: "house", descricao: "Início", rota: .home)
                item(icone: "list.bullet", descricao: "Transações", rota: .transacoes)
                item(icone: "square.grid.2x2", descricao: "Dashboard", rota: .dashboard)
                item(icone: "tag", descricao: "Categorias", rota: .categoria)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white).shadow(radius: 8))

            HStack {
                Spacer()
                Button(action: aoClicarEmAdicionar) {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(corIconeAdicionar)
                        .frame(width: 54, height: 54)
                        .background(Circle().fill(corFundoBotaoAdicionar))
                        .shadow(radius: 8)
                }
            }
        }
    }

    @ViewBuilder
    private func item(icone: String, descricao: String, rota: Route) -> some View {
        Button(action: { aoNavegar(rota) }) {
            Image(systemName: icone)
                .font(.system(size: 26))
                .foregroundStyle(rotaAtual == rota ? corIconeSelecionado : corIconeInativo)
                .frame(width: 48, height: 44)
        }
        .accessibilityLabel(descricao)
    }
}
