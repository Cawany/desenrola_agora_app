import SwiftUI

// catalogo com os nomes dos topicos para ficar melhor para mudar em um lugar so

struct CategoriaDefinicao {
    let id: String
    var nomeExibicao: String
    var palavrasChave: [String]
    var aliasesAntigos: [String]
    var cor: Color
    var icone: String
}

// enum para centralizar as cores dos topicos do grafico
enum CategoryCatalog {
    static let todas: [CategoriaDefinicao] = [
        CategoriaDefinicao(
            id: "mercado",
            nomeExibicao: "Mercado",
            palavrasChave: ["mercado", "supermercado", "hortifruti", "atacado", "hiper"],
            aliasesAntigos: ["Alimentação"],
            cor: Color(hex: 0x4A90D9),
            icone: "cart.fill"
        ),
        CategoriaDefinicao(
            id: "transporte",
            nomeExibicao: "Transporte",
            palavrasChave: ["uber", "99", "combustível", "combustivel", "posto", "estacimento"],
            aliasesAntigos: [],
            cor: Color(hex: 0x2E8B57),
            icone: "car.fill"
        ),
        CategoriaDefinicao(
            id: "moradia",
            nomeExibicao: "Moradia",
            palavrasChave: ["condomínio", "condominio", "aluguel", "imobiliaria", "impobiliária"],
            aliasesAntigos: [],
            cor: Color(hex: 0xD9A441),
            icone: "house.fill"
        ),
        CategoriaDefinicao(
            id: "contas_de_casa",
            nomeExibicao: "Contas de casa",
            palavrasChave: ["luz", "energia", "eletricidade", "sabesp","cemig", "copel", "enel"],
            aliasesAntigos: [],
            cor: Color(hex: 0xD9A441),
            icone: "bolt.fill"
        ),
        CategoriaDefinicao(
            id: "celular_internet",
            nomeExibicao: "Celular/Internet",
            palavrasChave: ["vivo", "claro", "tim", "oi","internet", "telefone", "net"],
            aliasesAntigos: ["Telecomunicações"],
            cor: Color(hex: 0x8E44AD),
            icone: "wifi"
        ),
        CategoriaDefinicao(
            id: "lazer",
            nomeExibicao: "Lazer",
            palavrasChave: ["netflix", "spotify", "cinema", "ingresso", "disney", "hbo", "prime video"],
            aliasesAntigos: [],
            cor: Color(hex: 0xE74C3C),
            icone: "gamecontroller.fill"
        ),
        CategoriaDefinicao(
            id: "saude",
            nomeExibicao: "Saúde",
            palavrasChave: ["farmácia", "farmacia", "drogaria", "hospital", "clínica", "clinica"],
            aliasesAntigos: [],
            cor: Color(hex: 0x16A085),
            icone: "heart.fill"
        ),
        CategoriaDefinicao(
            id: "cartao_credito",
            nomeExibicao: "Cartao de crédito",
            palavrasChave: ["cartão", "cartao", "fatura"],
            aliasesAntigos: [],
            cor: Color(hex: 0x7F8C8D),
            icone: "creditcard.fill"
        ),
        CategoriaDefinicao(
            id: "outros",
            nomeExibicao: "Outros",
            palavrasChave: [],
            aliasesAntigos: [],
            cor: Color(hex: 0xB0AFAF),
            icone: "questiomark.circle.fill"
        )
    ]
    
    private static var padraoOutros: CategoriaDefinicao {
        todas.first(where: { $0.id == "outros" })!
    }
    
    // usada apenas quando a pluggy nao classificar a transação -> devolve CategoriaDefinicao
    static func inferirDaDescricao(_ descricao: String) -> CategoriaDefinicao {
        let texto = descricao.lowercased()
        for definicao in todas where definicao.palavrasChave.contains(where: { texto.contains($0) }) {
            return definicao
        }
        return padraoOutros
    }
    
    // coração da solução resolve qq texto salvo no firestore(seja atual, antigo ou algo desconhecido)
    static func resolver(_ textoSalvo: String) -> CategoriaDefinicao {
        if let porNomeAtual = todas.first(where: { $0.nomeExibicao == textoSalvo }) {
            return porNomeAtual
        }
        if let porApelido = todas.first(where: { $0.aliasesAntigos.contains(textoSalvo) }) {
            return porApelido
        }
        // caso vc criar uma categoria desconhecida e ainda nao colocou ela aqui, vai mostra um texto proprio e cor definida
        return CategoriaDefinicao(
            id: textoSalvo,
            nomeExibicao: textoSalvo,
            palavrasChave: [],
            aliasesAntigos: [],
            cor: corReserva(paraTexto: textoSalvo),
            icone: "tag.fill"
        )
    }
    
    // resolve a categoria de "vdd" para exibição, sem escrever no firestore
    static func categoriaEfetiva(nomeSalvo: String, descricaoDaTransacao: String) -> CategoriaDefinicao {
        let resolvida = resolver(nomeSalvo)
        guard resolvida.id == "outros" else { return resolvida }
        return inferirDaDescricao(descricaoDaTransacao)
    }
    
    private static func corReserva(paraTexto texto: String) -> Color {
        let paleta: [Color] = [
            Color(hex: 0xCCCCFF), Color(hex: 0xB3B3E6), Color(hex: 0x9999CC),
            Color(hex: 0x8080B3), Color(hex: 0x666699)
        ]
        return paleta[abs(texto.hashValue) % paleta.count]
    }
}
