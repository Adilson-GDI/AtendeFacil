class ServicoModel {
  final int? id;
  final String nome;
  final String descricao;
  final double valorPadrao;
  final int ativo;
  final String createdAt;
  final String? updatedAt;

  ServicoModel({
    this.id,
    required this.nome,
    required this.descricao,
    required this.valorPadrao,
    required this.ativo,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'valor_padrao': valorPadrao,
      'ativo': ativo,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ServicoModel.fromMap(Map<String, dynamic> map) {
    return ServicoModel(
      id: map['id'],
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      valorPadrao: (map['valor_padrao'] ?? 0).toDouble(),
      ativo: map['ativo'] ?? 1,
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'],
    );
  }
}
