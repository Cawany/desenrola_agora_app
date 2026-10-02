import Foundation
import FirebaseFirestore

/// Por que este arquivo existe: descobrimos que a versão do Firebase SDK
/// instalada não tem a variante `async throws` nativa de `setData(from:)` /
/// `addDocument(from:)` — só a antiga, baseada em `completion:`, que
/// "dispara e esquece" sem reportar erro de rede/permissão pra quem chamou.
///
/// `withCheckedThrowingContinuation` é a ponte padrão do Swift Concurrency
/// pra transformar qualquer API de callback (completion handler) numa
/// função `async throws` de verdade: ela suspende a execução até você
/// chamar `continuation.resume(...)` de dentro do callback, e só então o
/// `await` de quem chamou continua. Isso garante que erros de escrita
/// (como "permission denied") realmente cheguem no `catch` de quem chamou,
/// em vez de morrerem em silêncio.
extension DocumentReference {
    func setDataAsync<T: Encodable>(from value: T, merge: Bool = false) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let completion: (Error?) -> Void = { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }

            do {
                if merge {
                    try self.setData(from: value, merge: true, completion: completion)
                } else {
                    try self.setData(from: value, completion: completion)
                }
            } catch {
                // Erro de CODIFICAÇÃO (Codable falhou)
                continuation.resume(throwing: error)
            }
        }
    }
}

extension CollectionReference {
    @discardableResult
    func addDocumentAsync<T: Encodable>(from value: T) async throws -> DocumentReference {
        let docRef = self.document()
        try await docRef.setDataAsync(from: value)
        return docRef
    }
}
