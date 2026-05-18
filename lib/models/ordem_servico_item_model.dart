class OrdemServicoItemModel {
  final int? id;
  final int ordemServicoId;
  final String tipo;
  final int? servicoId;
  final int? produtoId;
  final String descricao;
  final double quantidade;
  final double valorUnitario;
  final double valorTotal;
  final String createdAt;

  OrdemServicoItemModel({
    this.id,
    required this.ordemServicoId,
    required this.tipo,
    this.servicoId,
    this.produtoId,
    required this.descricao,
    required this.quantidade,
    required this.valorUnitario,
    required this.valorTotal,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ordem_servico_id': ordemServicoId,
      'tipo': tipo,
      'servico_id': servicoId,
      'produto_id': produtoId,
      'descricao': descricao,
      'quantidade': quantidade,
      'valor_unitario': valorUnitario,
      'valor_total': valorTotal,
      'created_at': createdAt,
    };
  }

  factory OrdemServicoItemModel.fromMap(Map<String, dynamic> map) {
    return OrdemServicoItemModel(
      id: map['id'],
      ordemServicoId: map['ordem_servico_id'],
      tipo: map['tipo'] ?? 'SERVICO',
      servicoId: map['servico_id'],
      produtoId: map['produto_id'],
      descricao: map['descricao'] ?? '',
      quantidade: (map['quantidade'] ?? 1).toDouble(),
      valorUnitario: (map['valor_unitario'] ?? 0).toDouble(),
      valorTotal: (map['valor_total'] ?? 0).toDouble(),
      createdAt: map['created_at'] ?? '',
    );
  }

  OrdemServicoItemModel copyWith({
    int? id,
    int? ordemServicoId,
    String? tipo,
    int? servicoId,
    int? produtoId,
    String? descricao,
    double? quantidade,
    double? valorUnitario,
    double? valorTotal,
    String? createdAt,
  }) {
    return OrdemServicoItemModel(
      id: id ?? this.id,
      ordemServicoId: ordemServicoId ?? this.ordemServicoId,
      tipo: tipo ?? this.tipo,
      servicoId: servicoId ?? this.servicoId,
      produtoId: produtoId ?? this.produtoId,
      descricao: descricao ?? this.descricao,
      quantidade: quantidade ?? this.quantidade,
      valorUnitario: valorUnitario ?? this.valorUnitario,
      valorTotal: valorTotal ?? this.valorTotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
