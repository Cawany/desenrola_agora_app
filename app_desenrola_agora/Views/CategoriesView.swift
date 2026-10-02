import SwiftUI

struct CategoriesView: View {
    let viewModel: CategoriaViewModel

    @State private var categoriaEditando: Categoria?
    @State private var dialogAberto = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Categorias").font(.title2).bold()
                        Text("Organize seus gastos").foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: {
                        categoriaEditando = nil
                        dialogAberto = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                    }
                }

                VStack(spacing: 8) {
                    ForEach(viewModel.categorias) { categoria in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(categoria.nome)
                                Text("Categoria de gasto").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(action: {
                                categoriaEditando = categoria
                                dialogAberto = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 24))
                                    .frame(width: 36, height: 36)
                            }
                            Button(action: { viewModel.excluirCategoria(id: categoria.id) }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 24))
                                    .frame(width: 36, height: 36)
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
                    }
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $dialogAberto) {
            CategoryFormSheet(
                categoriaInicial: categoriaEditando,
                aoSalvar: { nome in
                    if let categoriaEditando {
                        viewModel.atualizarCategoria(id: categoriaEditando.id, novoNome: nome)
                    } else {
                        viewModel.adicionarCategoria(nome: nome)
                    }
                    dialogAberto = false
                },
                aoCancelar: { dialogAberto = false }
            )
        }
    }
}

/// Equivalente ao `AlertDialog` do Android (`DialogFormularioCategoria`).
/// No iOS, o padrão nativo para um FORMULÁRIO modal é `.sheet`, não um
/// alerta — `Alert`/`.alert()` no SwiftUI é reservado para mensagens curtas
/// de confirmação, sem campo de texto.
private struct CategoryFormSheet: View {
    let categoriaInicial: Categoria?
    let aoSalvar: (String) -> Void
    let aoCancelar: () -> Void

    @State private var nome: String

    init(categoriaInicial: Categoria?, aoSalvar: @escaping (String) -> Void, aoCancelar: @escaping () -> Void) {
        self.categoriaInicial = categoriaInicial
        self.aoSalvar = aoSalvar
        self.aoCancelar = aoCancelar
        _nome = State(initialValue: categoriaInicial?.nome ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome", text: $nome)
            }
            .navigationTitle(categoriaInicial != nil ? "Editar categoria" : "Nova categoria")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", action: aoCancelar)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { aoSalvar(nome) }
                }
            }
        }
    }
}
