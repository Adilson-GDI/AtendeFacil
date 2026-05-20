class TreinoItemModel {
  final int? id;
  final int treinoId;
  final int? exercicioId;
  final String nomeExercicio;
  final String? categoria;
  final String? grupoMuscular;
  final int ordem;
  final String? series;
  final String? repeticoes;
  final String? carga;
  final String? descanso;
  final String? tempo;
  final String? observacoes;
  final String createdAt;
  final String? updatedAt;

  TreinoItemModel({
    this.id,
    required this.treinoId,
    this.exercicioId,
    required this.nomeExercicio,
    this.categoria,
    this.grupoMuscular,
    this.ordem = 0,
    this.series,
    this.repeticoes,
    this.carga,
    this.descanso,
    this.tempo,
    this.observacoes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'treino_id': treinoId,
      'exercicio_id': exercicioId,
      'nome_exercicio': nomeExercicio,
      'categoria': categoria,
      'grupo_muscular': grupoMuscular,
      'ordem': ordem,
      'series': series,
      'repeticoes': repeticoes,
      'carga': carga,
      'descanso': descanso,
      'tempo': tempo,
      'observacoes': observacoes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory TreinoItemModel.fromMap(Map<String, dynamic> map) {
    return TreinoItemModel(
      id: map['id'] as int?,
      treinoId: (map['treino_id'] as int?) ?? 0,
      exercicioId: map['exercicio_id'] as int?,
      nomeExercicio: map['nome_exercicio']?.toString() ?? '',
      categoria: map['categoria']?.toString(),
      grupoMuscular: map['grupo_muscular']?.toString(),
      ordem: (map['ordem'] as int?) ?? 0,
      series: map['series']?.toString(),
      repeticoes: map['repeticoes']?.toString(),
      carga: map['carga']?.toString(),
      descanso: map['descanso']?.toString(),
      tempo: map['tempo']?.toString(),
      observacoes: map['observacoes']?.toString(),
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString(),
    );
  }

  TreinoItemModel copyWith({
    int? id,
    int? treinoId,
    int? exercicioId,
    String? nomeExercicio,
    String? categoria,
    String? grupoMuscular,
    int? ordem,
    String? series,
    String? repeticoes,
    String? carga,
    String? descanso,
    String? tempo,
    String? observacoes,
    String? createdAt,
    String? updatedAt,
  }) {
    return TreinoItemModel(
      id: id ?? this.id,
      treinoId: treinoId ?? this.treinoId,
      exercicioId: exercicioId ?? this.exercicioId,
      nomeExercicio: nomeExercicio ?? this.nomeExercicio,
      categoria: categoria ?? this.categoria,
      grupoMuscular: grupoMuscular ?? this.grupoMuscular,
      ordem: ordem ?? this.ordem,
      series: series ?? this.series,
      repeticoes: repeticoes ?? this.repeticoes,
      carga: carga ?? this.carga,
      descanso: descanso ?? this.descanso,
      tempo: tempo ?? this.tempo,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
