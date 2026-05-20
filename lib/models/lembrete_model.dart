class LembreteModel {
  final int? id;
  final String titulo;
  final String descricao;
  final String tipo;
  final String dataInicio;
  final String hora;
  final String recorrencia;
  final int ativo;
  final int concluido;
  final String ultimaExecucao;
  final String createdAt;

  LembreteModel({
    this.id,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.dataInicio,
    required this.hora,
    required this.recorrencia,
    required this.ativo,
    required this.concluido,
    required this.ultimaExecucao,
    required this.createdAt,
  });

  factory LembreteModel.fromMap(Map<String, dynamic> map) {
    return LembreteModel(
      id: map['id'],
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'] ?? '',
      tipo: map['tipo'] ?? 'GERAL',
      dataInicio: map['data_inicio'] ?? '',
      hora: map['hora'] ?? '',
      recorrencia: map['recorrencia'] ?? 'NENHUMA',
      ativo: map['ativo'] ?? 1,
      concluido: map['concluido'] ?? 0,
      ultimaExecucao: map['ultima_execucao'] ?? '',
      createdAt: map['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'tipo': tipo,
      'data_inicio': dataInicio,
      'hora': hora,
      'recorrencia': recorrencia,
      'ativo': ativo,
      'concluido': concluido,
      'ultima_execucao': ultimaExecucao,
      'created_at': createdAt,
    };
  }
}
