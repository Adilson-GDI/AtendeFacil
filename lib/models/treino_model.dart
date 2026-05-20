class TreinoModel {
  final int? id;
  final int? clienteId;
  final String nome;
  final String? divisao;
  final String? objetivo;
  final String? observacoes;
  final int ativo;
  final String createdAt;
  final String? updatedAt;

  TreinoModel({
    this.id,
    this.clienteId,
    required this.nome,
    this.divisao,
    this.objetivo,
    this.observacoes,
    this.ativo = 1,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'nome': nome,
      'divisao': divisao,
      'objetivo': objetivo,
      'observacoes': observacoes,
      'ativo': ativo,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory TreinoModel.fromMap(Map<String, dynamic> map) {
    return TreinoModel(
      id: map['id'] as int?,
      clienteId: map['cliente_id'] as int?,
      nome: map['nome']?.toString() ?? '',
      divisao: map['divisao']?.toString(),
      objetivo: map['objetivo']?.toString(),
      observacoes: map['observacoes']?.toString(),
      ativo: (map['ativo'] as int?) ?? 1,
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString(),
    );
  }

  TreinoModel copyWith({
    int? id,
    int? clienteId,
    String? nome,
    String? divisao,
    String? objetivo,
    String? observacoes,
    int? ativo,
    String? createdAt,
    String? updatedAt,
  }) {
    return TreinoModel(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      nome: nome ?? this.nome,
      divisao: divisao ?? this.divisao,
      objetivo: objetivo ?? this.objetivo,
      observacoes: observacoes ?? this.observacoes,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
