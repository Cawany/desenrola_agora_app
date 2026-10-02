import SwiftUI
import WebKit
import FirebaseAuth

/// Equivalente à `TelaConectarBanco.kt`.
struct ConnectBankView: View {
    let aoConectarComSucesso: (String) -> Void
    let aoFechar: () -> Void

    @State private var connectToken: String?
    @State private var erro: String?

    var body: some View {
        Group {
            if let erro {
                VStack(spacing: 16) {
                    Text(erro)
                    Button("Voltar", action: aoFechar)
                }
                .padding(24)
            } else if let connectToken {
                PluggyWebView(
                    connectToken: connectToken,
                    aoConectar: aoConectarComSucesso,
                    aoErrar: { erro = $0 },
                    aoFechar: aoFechar
                )
            } else {
                ProgressView()
            }
        }
        .task { await prepararConexao() }
    }

    /// Equivalente ao `LaunchedEffect(Unit)` do Android: `.task { }` roda
    /// uma única vez quando a View aparece, e é cancelado automaticamente
    /// se a View sair de tela — o Swift Concurrency resolve sozinho o que
    /// o Android precisava do `coroutineScope` pra cuidar manualmente.
    private func prepararConexao() async {
        do {
            let apiKey = try await PluggyAPIClient.shared.autenticar(
                clientId: Secrets.pluggyClientId,
                clientSecret: Secrets.pluggyClientSecret
            )
            // Equivalente exato ao FirebaseAuth.getInstance().currentUser?.uid.
            let uid = Auth.auth().currentUser?.uid

            connectToken = try await PluggyAPIClient.shared.criarConnectToken(
                apiKey: apiKey,
                clientUserId: uid
            )
        } catch {
            erro = "Erro ao preparar conexão: \(error.localizedDescription)"
        }
    }
}

/// Equivalente ao `AndroidView { WebView(...) }`. `UIViewRepresentable` é a
/// ponte oficial do SwiftUI para Views do UIKit — o mesmo papel que o
/// `AndroidView` cumpre para Views antigas do Android.
private struct PluggyWebView: UIViewRepresentable {
    let connectToken: String
    let aoConectar: (String) -> Void
    let aoErrar: (String) -> Void
    let aoFechar: () -> Void

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        let bridge = PluggyConnectBridge(aoConectar: aoConectar, aoErrar: aoErrar, aoFechar: aoFechar)
        controller.add(bridge, name: PluggyConnectBridge.nomeDoCanal)
        context.coordinator.bridge = bridge // mantém referência forte

        let config = WKWebViewConfiguration()
        config.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        if let url = Bundle.main.url(forResource: "pluggy_connect_ios", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(connectToken: connectToken)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let connectToken: String
        var bridge: PluggyConnectBridge?

        init(connectToken: String) {
            self.connectToken = connectToken
        }

        /// Equivalente ao `onPageFinished` + `evaluateJavascript(...)`.
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("iniciarConexao('\(connectToken)')")
        }
    }
}
