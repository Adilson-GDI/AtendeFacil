class PagamentoModel {
  final int? id;
  final int ordemServicoId;
  final double valor;
  final String formaPagamento;
  final String status;
  final String dataPagamento;
  final String observacoes;
  final String createdAt;

  PagamentoModel({
    this.id,
    required this.ordemServicoId,
    required this.valor,
    required this.formaPagamento,
    required this.status,
    required this.dataPagamento,
    required this.observacoes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ordem_servico_id': ordemServicoId,
      'valor': valor,
      'forma_pagamento': formaPagamento,
      'status': status,
      'data_pagamento': dataPagamento,
      'observacoes': observacoes,
      'created_at': createdAt,
    };
  }

  factory PagamentoModel.fromMap(Map<String, dynamic> map) {
    return PagamentoModel(
      id: map['id'],
      ordemServicoId: map['ordem_servico_id'],
      valor: (map['valor'] ?? 0).toDouble(),
      formaPagamento: map['forma_pagamento'] ?? '',
      status: map['status'] ?? 'PAGO',
      dataPagamento: map['data_pagamento'] ?? '',
      observacoes: map['observacoes'] ?? '',
      createdAt: map['created_at'] ?? '',
    );
  }
}
