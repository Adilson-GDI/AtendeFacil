class ClienteModel {
  final int? id;
  final String nome;
  final String telefone;
  final String instagram;
  final String createdAt;
  final String? updatedAt;

  ClienteModel({
    this.id,
    required this.nome,
    required this.telefone,
    required this.instagram,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'telefone': telefone,
      'instagram': instagram,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ClienteModel.fromMap(Map<String, dynamic> map) {
    return ClienteModel(
      id: map['id'],
      nome: map['nome'] ?? '',
      telefone: map['telefone'] ?? '',
      instagram: map['instagram'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'],
    );
  }

  ClienteModel copyWith({
    int? id,
    String? nome,
    String? telefone,
    String? instagram,
    String? createdAt,
    String? updatedAt,
  }) {
    return ClienteModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      instagram: instagram ?? this.instagram,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
