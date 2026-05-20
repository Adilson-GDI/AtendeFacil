class AppConfigModel {
  final int? id;
  final String nomeEmpresa;
  final String corPrimaria;
  final String corSecundaria;
  final String? logoPath;

  final String telefone;
  final String whatsapp;
  final String email;
  final String cep;
  final String instagram;
  final String documento;
  final String endereco;
  final String cidade;
  final String estado;

  final String mensagemResumoOs;
  final String mensagemCobranca;

  final String createdAt;
  final String? updatedAt;

  AppConfigModel({
    this.id,
    required this.nomeEmpresa,
    required this.corPrimaria,
    required this.corSecundaria,
    this.logoPath,
    this.telefone = '',
    required this.whatsapp,
    this.email = '',
    this.cep = '',
    required this.instagram,
    required this.documento,
    required this.endereco,
    required this.cidade,
    required this.estado,
    required this.mensagemResumoOs,
    required this.mensagemCobranca,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome_empresa': nomeEmpresa,
      'cor_primaria': corPrimaria,
      'cor_secundaria': corSecundaria,
      'logo_path': logoPath,
      'telefone': telefone,
      'whatsapp': whatsapp,
      'email': email,
      'cep': cep,
      'instagram': instagram,
      'documento': documento,
      'endereco': endereco,
      'cidade': cidade,
      'estado': estado,
      'mensagem_resumo_os': mensagemResumoOs,
      'mensagem_cobranca': mensagemCobranca,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory AppConfigModel.fromMap(Map<String, dynamic> map) {
    return AppConfigModel(
      id: map['id'],
      nomeEmpresa: map['nome_empresa'] ?? 'Atende Fácil',
      corPrimaria: map['cor_primaria'] ?? '#1B5CB1',
      corSecundaria: map['cor_secundaria'] ?? '#C9A46B',
      logoPath: map['logo_path'],
      telefone: map['telefone'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      email: map['email'] ?? '',
      cep: map['cep'] ?? '',
      instagram: map['instagram'] ?? '',
      documento: map['documento'] ?? '',
      endereco: map['endereco'] ?? '',
      cidade: map['cidade'] ?? '',
      estado: map['estado'] ?? '',
      mensagemResumoOs:
          map['mensagem_resumo_os'] ??
          'Olá {cliente}, tudo bem?\n\nSegue o resumo da sua ordem de serviço:\n\n{resumo_os}\n\nTotal: {total}\n\nObrigado pela preferência!',
      mensagemCobranca:
          map['mensagem_cobranca'] ??
          'Olá {cliente}, tudo bem?\n\nEstamos passando para lembrar do pagamento referente à ordem de serviço {numero_os}.\n\nValor pendente: {valor_pendente}',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'],
    );
  }

  AppConfigModel copyWith({
    int? id,
    String? nomeEmpresa,
    String? corPrimaria,
    String? corSecundaria,
    String? logoPath,
    String? telefone,
    String? whatsapp,
    String? email,
    String? cep,
    String? instagram,
    String? documento,
    String? endereco,
    String? cidade,
    String? estado,
    String? mensagemResumoOs,
    String? mensagemCobranca,
    String? createdAt,
    String? updatedAt,
  }) {
    return AppConfigModel(
      id: id ?? this.id,
      nomeEmpresa: nomeEmpresa ?? this.nomeEmpresa,
      corPrimaria: corPrimaria ?? this.corPrimaria,
      corSecundaria: corSecundaria ?? this.corSecundaria,
      logoPath: logoPath ?? this.logoPath,
      telefone: telefone ?? this.telefone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      cep: cep ?? this.cep,
      instagram: instagram ?? this.instagram,
      documento: documento ?? this.documento,
      endereco: endereco ?? this.endereco,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      mensagemResumoOs: mensagemResumoOs ?? this.mensagemResumoOs,
      mensagemCobranca: mensagemCobranca ?? this.mensagemCobranca,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
