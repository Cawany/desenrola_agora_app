import Foundation
import WebKit

/// Equivalente à `PluggyConnectBridge.kt`.
///
/// Diferença importante: `@JavascriptInterface` no Android expõe TRÊS
/// métodos separados que o JavaScript chama diretamente. O WKWebView tem UM
/// ÚNICO ponto de entrada — `userContentController(_:didReceive:)` — que
/// recebe todas as mensagens; cabe a nós distinguir qual evento é qual. Por
/// isso o HTML do widget (veja `pluggy_connect_ios.html`) manda um payload
/// com um campo "evento", em vez de chamar três funções diferentes.
final class PluggyConnectBridge: NSObject, WKScriptMessageHandler {
    private let aoConectar: (String) -> Void
    private let aoErrar: (String) -> Void
    private let aoFechar: () -> Void

    /// Precisa ser IDÊNTICO ao nome usado em
    /// `window.webkit.messageHandlers.<nome>.postMessage(...)` no HTML —
    /// o mesmo papel do nome `"AndroidBridge"` no `addJavascriptInterface`.
    static let nomeDoCanal = "pluggyBridge"

    init(
        aoConectar: @escaping (String) -> Void,
        aoErrar: @escaping (String) -> Void,
        aoFechar: @escaping () -> Void
    ) {
        self.aoConectar = aoConectar
        self.aoErrar = aoErrar
        self.aoFechar = aoFechar
    }

    /// Equivalente conjunto às três funções `@JavascriptInterface` do Android.
    /// Diferente de lá, não precisamos de `Handler(Looper.getMainLooper())`
    /// aqui — o WKWebView já garante que este método roda na main thread.
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let corpo = message.body as? [String: Any],
              let evento = corpo["evento"] as? String else { return }

        switch evento {
        case "sucesso":
            if let itemId = corpo["itemId"] as? String {
                aoConectar(itemId)
            }
        case "erro":
            aoErrar(corpo["mensagem"] as? String ?? "Erro desconhecido")
        case "fechar":
            aoFechar()
        default:
            break
        }
    }
}
