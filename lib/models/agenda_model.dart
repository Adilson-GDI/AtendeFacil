class AgendaModel {
  final int? id;
  final int? clienteId;
  final int? ordemServicoId;

  final String titulo;
  final String descricao;

  final String dataInicio;
  final String horaInicio;
  final String horaFim;

  final String status;

  final int recorrente;
  final String tipoRecorrencia;
  final String diasSemana;
  final String dataFimRecorrencia;

  final String observacoes;
  final String createdAt;
  final String? updatedAt;

  AgendaModel({
    this.id,
    this.clienteId,
    this.ordemServicoId,
    required this.titulo,
    required this.descricao,
    required this.dataInicio,
    required this.horaInicio,
    required this.horaFim,
    required this.status,
    required this.recorrente,
    required this.tipoRecorrencia,
    required this.diasSemana,
    required this.dataFimRecorrencia,
    required this.observacoes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'ordem_servico_id': ordemServicoId,
      'titulo': titulo,
      'descricao': descricao,
      'data_inicio': dataInicio,
      'hora_inicio': horaInicio,
      'hora_fim': horaFim,
      'status': status,
      'recorrente': recorrente,
      'tipo_recorrencia': tipoRecorrencia,
      'dias_semana': diasSemana,
      'data_fim_recorrencia': dataFimRecorrencia,
      'observacoes': observacoes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory AgendaModel.fromMap(Map<String, dynamic> map) {
    return AgendaModel(
      id: map['id'],
      clienteId: map['cliente_id'],
      ordemServicoId: map['ordem_servico_id'],
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'] ?? '',
      dataInicio: map['data_inicio'] ?? '',
      horaInicio: map['hora_inicio'] ?? '',
      horaFim: map['hora_fim'] ?? '',
      status: map['status'] ?? 'AGENDADO',
      recorrente: map['recorrente'] ?? 0,
      tipoRecorrencia: map['tipo_recorrencia'] ?? '',
      diasSemana: map['dias_semana'] ?? '',
      dataFimRecorrencia: map['data_fim_recorrencia'] ?? '',
      observacoes: map['observacoes'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'],
    );
  }

  AgendaModel copyWith({
    int? id,
    int? clienteId,
    int? ordemServicoId,
    String? titulo,
    String? descricao,
    String? dataInicio,
    String? horaInicio,
    String? horaFim,
    String? status,
    int? recorrente,
    String? tipoRecorrencia,
    String? diasSemana,
    String? dataFimRecorrencia,
    String? observacoes,
    String? createdAt,
    String? updatedAt,
  }) {
    return AgendaModel(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      ordemServicoId: ordemServicoId ?? this.ordemServicoId,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      dataInicio: dataInicio ?? this.dataInicio,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFim: horaFim ?? this.horaFim,
      status: status ?? this.status,
      recorrente: recorrente ?? this.recorrente,
      tipoRecorrencia: tipoRecorrencia ?? this.tipoRecorrencia,
      diasSemana: diasSemana ?? this.diasSemana,
      dataFimRecorrencia: dataFimRecorrencia ?? this.dataFimRecorrencia,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
