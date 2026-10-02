import SwiftUI

struct LoginView: View {
    let viewModel: AuthViewModel
    let aoClicarEmCriarConta: () -> Void

    @State private var email = ""
    @State private var senha = ""
    @State private var senhaVisivel = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Text("Entrar").font(.title2).bold()

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            HStack {
                Group {
                    if senhaVisivel {
                        TextField("Senha", text: $senha)
                    } else {
                        SecureField("Senha", text: $senha)
                    }
                }
                Button(action: { senhaVisivel.toggle() }) {
                    Image(systemName: senhaVisivel ? "eye" : "eye.slash")
                        .font(.system(size: 22))
                        .foregroundStyle(.gray)
                }
            }
            .textFieldStyle(.roundedBorder)

            if let mensagemErro = viewModel.erro {
                Text(mensagemErro).foregroundStyle(.red)
            }

            Button(action: { viewModel.login(email: email, senha: senha) }) {
                Text("Entrar").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button("Não tem conta? Criar agora", action: aoClicarEmCriarConta)

            Spacer()
        }
        .padding(24)
    }
}
