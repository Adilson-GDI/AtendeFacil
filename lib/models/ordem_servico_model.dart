class OrdemServicoModel {
  final int? id;
  final int? clienteId;
  final String titulo;
  final String descricao;
  final String status;
  final String dataAbertura;
  final String? dataPrevisao;
  final String? dataConclusao;
  final double subtotal;
  final double desconto;
  final double acrescimo;
  final double total;
  final double valorPago;
  final double valorPendente;
  final String observacoes;
  final String createdAt;
  final String? updatedAt;

  OrdemServicoModel({
    this.id,
    this.clienteId,
    required this.titulo,
    required this.descricao,
    required this.status,
    required this.dataAbertura,
    this.dataPrevisao,
    this.dataConclusao,
    required this.subtotal,
    required this.desconto,
    required this.acrescimo,
    required this.total,
    required this.valorPago,
    required this.valorPendente,
    required this.observacoes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'titulo': titulo,
      'descricao': descricao,
      'status': status,
      'data_abertura': dataAbertura,
      'data_previsao': dataPrevisao,
      'data_conclusao': dataConclusao,
      'subtotal': subtotal,
      'desconto': desconto,
      'acrescimo': acrescimo,
      'total': total,
      'valor_pago': valorPago,
      'valor_pendente': valorPendente,
      'observacoes': observacoes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory OrdemServicoModel.fromMap(Map<String, dynamic> map) {
    return OrdemServicoModel(
      id: map['id'],
      clienteId: map['cliente_id'],
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'] ?? '',
      status: map['status'] ?? 'ORCAMENTO',
      dataAbertura: map['data_abertura'] ?? '',
      dataPrevisao: map['data_previsao'],
      dataConclusao: map['data_conclusao'],
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      desconto: (map['desconto'] ?? 0).toDouble(),
      acrescimo: (map['acrescimo'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      valorPago: (map['valor_pago'] ?? 0).toDouble(),
      valorPendente: (map['valor_pendente'] ?? 0).toDouble(),
      observacoes: map['observacoes'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'],
    );
  }
}
