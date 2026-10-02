import Foundation
import Observation

enum PeriodoFiltro {
    case mesAtual, mesPassado, ultimos7Dias, anoAtual, tudo
}

@Observable
final class TransacaoViewModel {
    private let repository: TransacaoRepository

    private(set) var viewState: TransacaoViewState = .carregando
    private(set) var categorias: [Categoria] = [
        Categoria(id: "1", nome: "Alimentação"),
        Categoria(id: "2", nome: "Transporte"),
        Categoria(id: "3", nome: "Lazer"),
        Categoria(id: "4", nome: "Saúde"),
        Categoria(id: "5", nome: "Moradia")
    ]

    private var tarefaObservacao: Task<Void, Never>?

    init(repository: TransacaoRepository) {
        self.repository = repository
        observarTransacoes()
    }

    deinit { tarefaObservacao?.cancel() }

    private func observarTransacoes() {
        // Agora que o protocolo usa `AsyncThrowingStream` (corrigido neste
        // lote), este `do/catch` cumpre exatamente o papel do `.catch { }`
        // do Kotlin: qualquer erro lançado dentro do stream (ex.: uma falha
        // HTTP do PluggyTransacaoRepository) cai aqui.
        tarefaObservacao = Task {
            do {
                for try await lista in repository.observarTransacoes() {
                    viewState = .sucesso(transacoes: lista)
                }
            } catch {
                viewState = .erro(mensagem: error.localizedDescription)
            }
        }
    }

    func adicionarTransacao(_ transacao: Transacao) {
        Task {
            do {
                try await repository.salvarTransacao(transacao)
                // Não precisa fazer nada aqui — observarTransacoes() já
                // recebe a atualização sozinho, é tempo real.
            } catch {
                viewState = .erro(mensagem: error.localizedDescription)
            }
        }
    }

    func adicionarCategoria(nome: String) {
        categorias.append(Categoria(id: UUID().uuidString, nome: nome))
    }

    func atualizarCategoria(id: String, novoNome: String) {
        if let index = categorias.firstIndex(where: { $0.id == id }) {
            categorias[index].nome = novoNome
        }
    }

    func excluirCategoria(id: String) {
        categorias.removeAll { $0.id == id }
    }

    // MARK: - Métricas
    // Nota de nomenclatura: removi o prefixo "get" (getTotalGastoNoPeriodo
    // -> totalGasto). Em Swift, esse prefixo não é idiomático — o padrão da
    // própria Apple é nomear como se fosse uma frase (`total(no:)`).

    func totalGasto(no transacoes: [Transacao]) -> Double {
        transacoes.filter { !$0.isReceita }.reduce(0) { $0 + $1.valor }
    }

    //agrupa pelo id e nao pelo texto cru
    func valorPorCategoria(_ transacoes: [Transacao]) -> [(categoria: String, valor: Double)] {
        let despesas = transacoes.filter { !$0.isReceita }
        let agrupadoPorId = Dictionary(grouping: despesas) {
            CategoryCatalog.categoriaEfetiva(nomeSalvo: $0.categoria, descricaoDaTransacao: $0.loja).id
        }
        
        return agrupadoPorId.map { _, lista in
            let definicao = CategoryCatalog.categoriaEfetiva(
                nomeSalvo: lista[0].categoria,
                descricaoDaTransacao: lista[0].loja
            )
            let total = lista.reduce(0) { $0 + $1.valor }
            return (categoria: definicao.nomeExibicao, valor: total)
        }
    }

    func gastoPorDia(_ transacoes: [Transacao]) -> [(dia: String, valor: Double)] {
        let formato = DateFormatter()
        formato.dateFormat = "dd/MM"
        formato.locale = Locale(identifier: "pt_BR")

        let agrupado = Dictionary(grouping: transacoes.filter { !$0.isReceita }) {
            formato.string(from: $0.dataComoDate)
        }
        return agrupado.map { (dia: $0.key, valor: $0.value.reduce(0) { $0 + $1.valor }) }
    }

    func topLojas(_ transacoes: [Transacao], limite: Int = 5) -> [(loja: String, valor: Double)] {
        let agrupado = Dictionary(grouping: transacoes.filter { !$0.isReceita }) { $0.loja }
        return agrupado
            .map { (loja: $0.key, valor: $0.value.reduce(0) { $0 + $1.valor }) }
            .sorted { $0.valor > $1.valor }
            .prefix(limite)
            .map { $0 }
    }
}

/// Equivalente à função solta `filtrarPorPeriodo` do Kotlin (que também
/// vivia fora da classe do ViewModel, como top-level function).
func filtrar(_ transacoes: [Transacao], por periodo: PeriodoFiltro) -> [Transacao] {
    let calendario = Calendar.current
    let agora = Date()

    switch periodo {
    case .mesAtual:
        return transacoes.filter {
            calendario.isDate($0.dataComoDate, equalTo: agora, toGranularity: .month)
        }
    case .mesPassado:
        guard let mesPassado = calendario.date(byAdding: .month, value: -1, to: agora) else { return [] }
        return transacoes.filter {
            calendario.isDate($0.dataComoDate, equalTo: mesPassado, toGranularity: .month)
        }
    case .ultimos7Dias:
        guard let seteDiasAtras = calendario.date(byAdding: .day, value: -7, to: agora) else { return [] }
        return transacoes.filter { $0.dataComoDate >= seteDiasAtras }
    case .anoAtual:
        return transacoes.filter {
            calendario.isDate($0.dataComoDate, equalTo: agora, toGranularity: .year)
        }
    case .tudo:
        return transacoes
    }
}
