class ExercicioModel {
  final int? id;
  final String nome;
  final String? categoria;
  final String? grupoMuscular;
  final String? descricao;
  final String? videoUrl;
  final int favorito;
  final int ativo;
  final String createdAt;
  final String? updatedAt;

  ExercicioModel({
    this.id,
    required this.nome,
    this.categoria,
    this.grupoMuscular,
    this.descricao,
    this.videoUrl,
    this.favorito = 0,
    this.ativo = 1,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'categoria': categoria,
      'grupo_muscular': grupoMuscular,
      'descricao': descricao,
      'video_url': videoUrl,
      'favorito': favorito,
      'ativo': ativo,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ExercicioModel.fromMap(Map<String, dynamic> map) {
    return ExercicioModel(
      id: map['id'] as int?,
      nome: map['nome']?.toString() ?? '',
      categoria: map['categoria']?.toString(),
      grupoMuscular: map['grupo_muscular']?.toString(),
      descricao: map['descricao']?.toString(),
      videoUrl: map['video_url']?.toString(),
      favorito: (map['favorito'] as int?) ?? 0,
      ativo: (map['ativo'] as int?) ?? 1,
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString(),
    );
  }

  ExercicioModel copyWith({
    int? id,
    String? nome,
    String? categoria,
    String? grupoMuscular,
    String? descricao,
    String? videoUrl,
    int? favorito,
    int? ativo,
    String? createdAt,
    String? updatedAt,
  }) {
    return ExercicioModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      categoria: categoria ?? this.categoria,
      grupoMuscular: grupoMuscular ?? this.grupoMuscular,
      descricao: descricao ?? this.descricao,
      videoUrl: videoUrl ?? this.videoUrl,
      favorito: favorito ?? this.favorito,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
