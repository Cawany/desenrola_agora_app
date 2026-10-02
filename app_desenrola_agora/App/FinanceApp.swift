import SwiftUI
import FirebaseCore

@main
struct FinanceApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                authRepository: FirebaseAuthRepository(),
                transacaoRepository: FirebaseTransacaoRepository(),
                categoriaRepository: FirebaseCategoriaRepository(),
                contaConectadaRepository: FirebaseContaConectadaRepository()
            )
            .tint(AppColors.purple80)
            .financeAppTheme()
        }
    }
}
