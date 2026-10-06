import SwiftUI

/// Grafo de navegação principal do aplicativo.
struct RootView: View {
    @State private var authViewModel: AuthViewModel
    @State private var transacaoViewModel: TransacaoViewModel
    @State private var categoriaViewModel: CategoriaViewModel
    @State private var contaConectadaViewModel: ContaConectadaViewModel

    private let contaConectadaRepository: ContaConectadaRepository

    @State private var telaAuth: TelaAuth = .login
    @State private var rotaAtual: Route = .home
    @State private var mostrandoConectarBanco = false
    @State private var mostrandoConfiguracoes = false

    enum TelaAuth { case login, cadastro }

    init(
        authRepository: AuthRepository,
        transacaoRepository: TransacaoRepository,
        categoriaRepository: CategoriaRepository,
        contaConectadaRepository: ContaConectadaRepository
    ) {
        _authViewModel = State(initialValue: AuthViewModel(repository: authRepository))
        _transacaoViewModel = State(initialValue: TransacaoViewModel(repository: transacaoRepository))
        _categoriaViewModel = State(initialValue: CategoriaViewModel(repository: categoriaRepository))
        _contaConectadaViewModel = State(initialValue: ContaConectadaViewModel(repository: contaConectadaRepository))
        self.contaConectadaRepository = contaConectadaRepository
    }

    var body: some View {
        Group {
            if authViewModel.usuario == nil {
                switch telaAuth {
                case .login:
                    LoginView(viewModel: authViewModel, aoClicarEmCriarConta: { telaAuth = .cadastro })
                case .cadastro:
                    SignUpView(viewModel: authViewModel, aoClicarEmJaTenhoConta: { telaAuth = .login })
                }
            } else {
                ZStack(alignment: .bottom) {
                    telaPrincipal
                        .padding(.bottom, 70) // espaço reservado pra barra flutuante

                    BottomNavigationBar(
                        rotaAtual: rotaAtual,
                        aoNavegar: { rotaAtual = $0 },
                        aoClicarEmAdicionar: { /* mesmo placeholder vazio do Android original */ }
                    )
                    .padding(16)
                }
                .fullScreenCover(isPresented: $mostrandoConectarBanco) {
                    ConnectBankView(
                        aoConectarComSucesso: { itemId in
                            Task {
                                do {
                                    var contas: [PluggyContaDto] = []
                                    for _ in 0..<3 {
                                        contas = try await PluggyBackendClient.shared.buscarContas(itemId: itemId)
                                        if !contas.isEmpty { break }
                                        try await Task.sleep(nanoseconds: 1_000_000_000)
                                    }
                                    
                                    for conta in contas {
                                        try await contaConectadaRepository.salvar(
                                            ContaConectada(
                                                accountId: conta.id,
                                                itemId: itemId,
                                                tipo: conta.type,
                                                nomeInstituicao: conta.name
                                            )
                                        )
                                    }
                                } catch {
                                    print("PluggyConnect: falha ao salvar conta conectada — \(error.localizedDescription)")
                                }
                                mostrandoConectarBanco = false
                            }
                        },
                        aoFechar: { mostrandoConectarBanco = false }
                    )
                }
                .sheet(isPresented: $mostrandoConfiguracoes) {
                    SettingsView(
                        authViewModel: authViewModel,
                        contaConectadaViewModel: contaConectadaViewModel,
                        aoConectarNovoBanco: {
                            mostrandoConfiguracoes = false
                            mostrandoConectarBanco = true
                        }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var telaPrincipal: some View {
        switch rotaAtual {
        case .home:
            HomeView(
                viewModel: transacaoViewModel,
                authViewModel: authViewModel,
                contaConectadaViewModel: contaConectadaViewModel,
                aoAbrirConfiguracoes: { mostrandoConfiguracoes = true }
            )
        case .transacoes:
            TransactionsView(viewModel: transacaoViewModel)
        case .dashboard:
            DashboardView(viewModel: transacaoViewModel)
        case .categoria:
            CategoriesView(viewModel: categoriaViewModel)
        case .conectarBanco:
            EmptyView() // não faz parte da barra — acessado via fullScreenCover
        }
    }
}
