class AnamneseModel {
  final int? id;

  final int clienteId;
  final String tipoServico;

  final String objetivo;
  final String queixaPrincipal;
  final String historicoSaude;
  final String lesoes;
  final String cirurgias;
  final String medicamentos;
  final String alergias;
  final String dores;
  final String limitacoes;
  final String nivelAtividade;
  final String observacoes;

  final String dataAnamnese;

  final String createdAt;
  final String? updatedAt;

  AnamneseModel({
    this.id,
    required this.clienteId,
    required this.tipoServico,
    required this.objetivo,
    required this.queixaPrincipal,
    required this.historicoSaude,
    required this.lesoes,
    required this.cirurgias,
    required this.medicamentos,
    required this.alergias,
    required this.dores,
    required this.limitacoes,
    required this.nivelAtividade,
    required this.observacoes,
    required this.dataAnamnese,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'tipo_servico': tipoServico,

      'objetivo': objetivo,
      'queixa_principal': queixaPrincipal,
      'historico_saude': historicoSaude,
      'lesoes': lesoes,
      'cirurgias': cirurgias,
      'medicamentos': medicamentos,
      'alergias': alergias,
      'dores': dores,
      'limitacoes': limitacoes,
      'nivel_atividade': nivelAtividade,
      'observacoes': observacoes,

      'data_anamnese': dataAnamnese,

      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory AnamneseModel.fromMap(Map<String, dynamic> map) {
    return AnamneseModel(
      id: map['id'] as int?,

      clienteId: map['cliente_id'] ?? 0,
      tipoServico: map['tipo_servico'] ?? '',

      objetivo: map['objetivo'] ?? '',
      queixaPrincipal: map['queixa_principal'] ?? '',
      historicoSaude: map['historico_saude'] ?? '',
      lesoes: map['lesoes'] ?? '',
      cirurgias: map['cirurgias'] ?? '',
      medicamentos: map['medicamentos'] ?? '',
      alergias: map['alergias'] ?? '',
      dores: map['dores'] ?? '',
      limitacoes: map['limitacoes'] ?? '',
      nivelAtividade: map['nivel_atividade'] ?? '',
      observacoes: map['observacoes'] ?? '',

      dataAnamnese: map['data_anamnese'] ?? '',

      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'],
    );
  }

  AnamneseModel copyWith({
    int? id,
    int? clienteId,
    String? tipoServico,
    String? objetivo,
    String? queixaPrincipal,
    String? historicoSaude,
    String? lesoes,
    String? cirurgias,
    String? medicamentos,
    String? alergias,
    String? dores,
    String? limitacoes,
    String? nivelAtividade,
    String? observacoes,
    String? dataAnamnese,
    String? createdAt,
    String? updatedAt,
  }) {
    return AnamneseModel(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      tipoServico: tipoServico ?? this.tipoServico,

      objetivo: objetivo ?? this.objetivo,
      queixaPrincipal: queixaPrincipal ?? this.queixaPrincipal,
      historicoSaude: historicoSaude ?? this.historicoSaude,
      lesoes: lesoes ?? this.lesoes,
      cirurgias: cirurgias ?? this.cirurgias,
      medicamentos: medicamentos ?? this.medicamentos,
      alergias: alergias ?? this.alergias,
      dores: dores ?? this.dores,
      limitacoes: limitacoes ?? this.limitacoes,
      nivelAtividade: nivelAtividade ?? this.nivelAtividade,
      observacoes: observacoes ?? this.observacoes,

      dataAnamnese: dataAnamnese ?? this.dataAnamnese,

      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
