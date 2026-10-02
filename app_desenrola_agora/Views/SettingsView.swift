import SwiftUI

/// Equivalente à `TelaConfiguracoes.kt` do Android.
///
/// Nota de arquitetura: no Android, o logout precisa de
/// `popUpTo(0) { inclusive = true }` pra limpar a pilha de navegação —
/// senão o botão "voltar" do celular levaria de volta pra Home deslogado.
/// Aqui isso não é necessário: o `RootView` decide "Login vs. app" apenas
/// observando `authViewModel.usuario`. Assim que `logout()` zera esse
/// valor, o `RootView` troca de tela sozinho — não existe pilha pra limpar.
struct SettingsView: View {
    let authViewModel: AuthViewModel
    let contaConectadaViewModel: ContaConectadaViewModel
    let aoConectarNovoBanco: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var mensagemMigracao: String?
    @State private var migrando = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Contas conectadas") {
                    if contaConectadaViewModel.contas.isEmpty {
                        Text("Nenhum banco conectado ainda.")
                            .foregroundStyle(.gray)
                    } else {
                        ForEach(contaConectadaViewModel.contas) { conta in
                            HStack {
                                Image(systemName: "building.columns")
                                VStack(alignment: .leading) {
                                    Text(conta.nomeInstituicao)
                                    Text(conta.tipo).font(.caption).foregroundStyle(.gray)
                                }
                            }
                        }
                        .onDelete { indices in
                            indices.forEach { indice in
                                let conta = contaConectadaViewModel.contas[indice]
                                contaConectadaViewModel.remover(accountId: conta.accountId)
                            }
                        }
                    }

                    Button("Conectar novo banco", action: aoConectarNovoBanco)
                }

                Section {
                    Button(role: .destructive) {	
                        authViewModel.logout()
                        dismiss()
                    } label: {
                        Label {
                            Text("Sair da conta")
                        } icon: {
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 22))
                        }
                    }
                }
            }
            .navigationTitle("Configurações")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar", action: { dismiss() })
                }
            }
        }
    }
}
