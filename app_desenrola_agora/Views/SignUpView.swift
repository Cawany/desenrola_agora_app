import SwiftUI

struct SignUpView: View {
    let viewModel: AuthViewModel
    let aoClicarEmJaTenhoConta: () -> Void

    @State private var email = ""
    @State private var senha = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Text("Criar conta").font(.title2).bold()

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Senha (mínimo 6 caracteres)", text: $senha)
                .textFieldStyle(.roundedBorder)

            if let mensagemErro = viewModel.erro {
                Text(mensagemErro).foregroundStyle(.red)
            }

            Button(action: { viewModel.criarConta(email: email, senha: senha) }) {
                Text("Criar conta").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button("Já tenho conta", action: aoClicarEmJaTenhoConta)

            Spacer()
        }
        .padding(24)
    }
}
