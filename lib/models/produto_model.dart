class ProdutoModel {
  final int? id;
  final String nome;
  final String descricao;
  final double precoCusto;
  final double precoVenda;
  final double estoqueAtual;
  final String unidade;
  final int ativo;
  final String createdAt;
  final String? updatedAt;

  ProdutoModel({
    this.id,
    required this.nome,
    required this.descricao,
    required this.precoCusto,
    required this.precoVenda,
    required this.estoqueAtual,
    required this.unidade,
    required this.ativo,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'preco_custo': precoCusto,
      'preco_venda': precoVenda,
      'estoque_atual': estoqueAtual,
      'unidade': unidade,
      'ativo': ativo,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ProdutoModel.fromMap(Map<String, dynamic> map) {
    return ProdutoModel(
      id: map['id'],
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      precoCusto: (map['preco_custo'] ?? 0).toDouble(),
      precoVenda: (map['preco_venda'] ?? 0).toDouble(),
      estoqueAtual: (map['estoque_atual'] ?? 0).toDouble(),
      unidade: map['unidade'] ?? 'UN',
      ativo: map['ativo'] ?? 1,
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'],
    );
  }

  ProdutoModel copyWith({
    int? id,
    String? nome,
    String? descricao,
    double? precoCusto,
    double? precoVenda,
    double? estoqueAtual,
    String? unidade,
    int? ativo,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProdutoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      precoCusto: precoCusto ?? this.precoCusto,
      precoVenda: precoVenda ?? this.precoVenda,
      estoqueAtual: estoqueAtual ?? this.estoqueAtual,
      unidade: unidade ?? this.unidade,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
