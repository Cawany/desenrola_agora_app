import Foundation

/// Equivalente ao `BuildConfig` que o Android gera sozinho a partir do
/// `local.properties`. No Xcode, essa "ponte" não existe pronta — o `.xcconfig`
/// só injeta valores no Info.plist; quem lê esses valores em Swift é este arquivo.
///
/// Fluxo completo (equivalente ao seu `local.properties` -> `BuildConfig`):
///
///   Config-Secrets.xcconfig (fora do Git)
///        ↓ referenciado nas Build Settings do projeto (Debug e Release)
///   Info.plist (usa a sintaxe $(NOME_DA_VARIAVEL))
///        ↓ lido em runtime por
///   Secrets.swift  ← este arquivo
///
enum Secrets {

    /// `fatalError` aqui é proposital: se a chave não existir, é sinal de que o
    /// .xcconfig não foi configurado — melhor travar o app imediatamente em
    /// desenvolvimento do que deixar uma chamada de API falhar silenciosamente
    /// mais tarde com uma mensagem de erro confusa.
    static var pluggyClientId: String {
        guard let valor = Bundle.main.object(forInfoDictionaryKey: "PluggyClientId") as? String,
              !valor.isEmpty else {
            fatalError("PLUGGY_CLIENT_ID não encontrado no Info.plist — confira o .xcconfig e o Build Setting.")
        }
        return valor
    }

    static var pluggyClientSecret: String {
        guard let valor = Bundle.main.object(forInfoDictionaryKey: "PluggyClientSecret") as? String,
              !valor.isEmpty else {
            fatalError("PLUGGY_CLIENT_SECRET não encontrado no Info.plist — confira o .xcconfig e o Build Setting.")
        }
        return valor
    }
}
