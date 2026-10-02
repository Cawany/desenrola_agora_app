import SwiftUI
import FirebaseAuth

/// Equivalente à `TelaHome.kt` já com os ajustes da Aula 10: engrenagem em
/// vez de carteira (abre `SettingsView`), sincronização usando as contas
/// persistidas no Firestore em vez do `accountId` fixo, e sem o botão
/// "Conectar novo banco" solto (agora vive nas Configurações).
struct HomeView: View {
    let viewModel: TransacaoViewModel
    let authViewModel: AuthViewModel
    let contaConectadaViewModel: ContaConectadaViewModel
    let aoAbrirConfiguracoes: () -> Void

    @State private var sincronizando = false
    @State private var mensagemSincronizacao: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Bom dia").font(.subheadline).foregroundStyle(.gray)
                        Text("Suas finanças").font(.headline)
                    }
                    Spacer()
                    Button(action: aoAbrirConfiguracoes) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.accentColor.opacity(0.15)))
                    }
                    .accessibilityLabel("Configurações")
                }

                switch viewModel.viewState {
                case .carregando:
                    ProgressView()
                case .erro(let mensagem):
                    Text(mensagem)
                case .sucesso(let transacoes):
                    let totalGasto = viewModel.totalGasto(no: transacoes)
                    let gastoPorCategoria = viewModel.valorPorCategoria(transacoes)
                    let recentes = Array(
                        transacoes.sorted { $0.dataComoDate > $1.dataComoDate }.prefix(5)
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gasto do mês").font(.caption).foregroundStyle(.black.opacity(0.7))
                        Text(formatarMoeda(totalGasto)).font(.system(size: 32, weight: .bold)).foregroundStyle(.black)
                        Text("Veja onde seu dinheiro está indo").font(.caption).foregroundStyle(.black.opacity(0.7))
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.accentColor))

                    VStack(alignment: .leading) {
                        Text("Gasto por categoria").fontWeight(.semibold)
                        
                        VStack {
                            CategoryPieChart(dados: gastoPorCategoria)
                        }
                        .padding(26)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray, lineWidth: 1))
                    }

                    VStack(alignment: .leading) {
                        Text("Últimas transações").fontWeight(.semibold)
                        TransactionList(transacoes: recentes)
                    }
                }

                Button(action: sincronizarPluggy) {
                    if sincronizando {
                        HStack {
                            ProgressView().tint(.white)
                            Text("Sincronizando...")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Sincronizar Pluggy").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(sincronizando)

                if let mensagemSincronizacao {
                    Text(mensagemSincronizacao)
                        .font(.caption)
                        .foregroundStyle(mensagemSincronizacao.hasPrefix("Erro") ? .red : Color.accentColor)
                }
            }
            .padding(16)
        }
    }

    private func sincronizarPluggy() {
        Task {
            sincronizando = true
            mensagemSincronizacao = nil
            defer { sincronizando = false }

            let contas = contaConectadaViewModel.contas
            if contas.isEmpty {
                mensagemSincronizacao = "Nenhum banco conectado ainda."
                return
            }

            do {
                let firebaseRepository = FirebaseTransacaoRepository()
                var totalSincronizado = 0

                // Uma conta hoje, várias no futuro — o loop já suporta as
                // duas situações, igual do lado Android.
                for conta in contas {
                    let pluggyRepository = PluggyTransacaoRepository(
                        clientId: Secrets.pluggyClientId,
                        clientSecret: Secrets.pluggyClientSecret,
                        accountId: conta.accountId,
                        userId: Auth.auth().currentUser?.uid
                    )
                    let sincronizador = SicronizadorPluggy(
                        pluggyRepository: pluggyRepository,
                        firebaseRepository: firebaseRepository
                    )
                    totalSincronizado += try await sincronizador.sincronizar()
                }

                mensagemSincronizacao = "Sincronizadas \(totalSincronizado) transações com sucesso!"
            } catch {
                mensagemSincronizacao = "Erro ao sincronizar: \(error.localizedDescription)"
            }
        }
    }
}
