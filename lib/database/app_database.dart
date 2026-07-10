import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../app/app_runtime.dart';
import '../models/cliente_model.dart';
import '../models/produto_model.dart';
import '../models/servico_model.dart';
import '../models/ordem_servico_model.dart';
import '../models/ordem_servico_item_model.dart';
import '../models/pagamento_model.dart';
import '../models/pagamento_aluno_model.dart';
import '../models/app_config_model.dart';
import '../models/app_remote_status_model.dart';
import '../models/app_user_model.dart';
import '../models/agenda_model.dart';
import '../models/atendimento_model.dart';
import '../models/service_location_model.dart';
import '../models/support_message_model.dart';
import 'treinos_database.dart';
import '../models/exercicio_model.dart';
import '../models/treino_model.dart';
import '../models/treino_item_model.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();

  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB(AppRuntime.definition.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    final legacyPath = join(dbPath, 'atende_facil.db');

    final dbFile = File(path);
    final legacyFile = File(legacyPath);
    if (filePath != 'atende_facil.db' &&
        !await dbFile.exists() &&
        await legacyFile.exists()) {
      await legacyFile.copy(path);
    }

    return await openDatabase(
      path,
      version: 21,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await _createClientesTable(db);
    await _createProdutosTable(db);
    await _createServicosTable(db);
    await _createOrdensServicoTable(db);
    await _createOrdemServicoItensTable(db);
    await _createPagamentosTable(db);
    await _createPagamentosAlunosTable(db);
    await _createAppConfigTable(db);
    await _createAgendaTable(db);
    await _createServiceLocationsTable(db);
    await _createSupportMessagesTable(db);
    await _createAnamnesesTable(db);
    await TreinosDatabase.createTables(db);
    await _createLembretesTable(db);
    await _createAtendimentosTable(db);
    await _createAppUsersTable(db);
    await _createAppRemoteStatusTable(db);
    await _createQuickRoutinesTable(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await _createProdutosTable(db);
    }

    if (oldVersion < 4) {
      await _createServicosTable(db);
    }

    if (oldVersion < 5) {
      await _createOrdensServicoTable(db);
      await _createOrdemServicoItensTable(db);
    }

    if (oldVersion < 6) {
      await _createPagamentosTable(db);
    }

    if (oldVersion < 7) {
      await _createAppConfigTable(db);
    }

    if (oldVersion < 8) {
      await _addColumnIfNotExists(db, 'app_config', 'telefone', 'TEXT');
      await _addColumnIfNotExists(db, 'app_config', 'whatsapp', 'TEXT');
      await _addColumnIfNotExists(db, 'app_config', 'instagram', 'TEXT');
      await _addColumnIfNotExists(db, 'app_config', 'documento', 'TEXT');
      await _addColumnIfNotExists(db, 'app_config', 'endereco', 'TEXT');
      await _addColumnIfNotExists(db, 'app_config', 'cidade', 'TEXT');
      await _addColumnIfNotExists(db, 'app_config', 'estado', 'TEXT');
      await _addColumnIfNotExists(
        db,
        'app_config',
        'mensagem_resumo_os',
        'TEXT',
      );
      await _addColumnIfNotExists(
        db,
        'app_config',
        'mensagem_cobranca',
        'TEXT',
      );

      await _garantirConfigAppPadrao(db);
    }

    if (oldVersion < 9) {
      await db.execute(
        "ALTER TABLE app_config ADD COLUMN tipo_servico TEXT DEFAULT 'PERSONAL_TRAINER'",
      );
    }

    if (oldVersion < 10) {
      await _createAgendaTable(db);
    }

    if (oldVersion < 11) {
      await TreinosDatabase.createTables(db);
    }

    if (oldVersion < 12) {
      await _createAnamnesesTable(db);
    }

    if (oldVersion < 13) {
      await _addColumnIfNotExists(db, 'app_config', 'email', 'TEXT');

      await _addColumnIfNotExists(db, 'app_config', 'cep', 'TEXT');
    }

    if (oldVersion < 14) {
      await _createLembretesTable(db);
    }
    if (oldVersion < 15) {
      await _addColumnIfNotExists(db, 'lembretes', 'ultima_execucao', 'TEXT');
    }

    if (oldVersion < 16) {
      await _createAtendimentosTable(db);
    }

    if (oldVersion < 17) {
      await _createAppUsersTable(db);
      await _createAppRemoteStatusTable(db);
    }

    if (oldVersion < 18) {
      await _createPagamentosAlunosTable(db);
    }

    if (oldVersion < 19) {
      await _createServiceLocationsTable(db);
      await _addColumnIfNotExists(
        db,
        'agenda',
        'service_location_id',
        'INTEGER',
      );
    }

    if (oldVersion < 20) {
      await _createSupportMessagesTable(db);
    }

    if (oldVersion < 21) {
      await _createQuickRoutinesTable(db);
    }
  }

  Future<void> _createQuickRoutinesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quick_routines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_key TEXT NOT NULL,
        label TEXT NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _addColumnIfNotExists(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');

    final exists = columns.any((col) => col['name'] == column);

    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<void> _createClientesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        telefone TEXT,
        instagram TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _createProdutosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS produtos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        preco_custo REAL DEFAULT 0,
        preco_venda REAL DEFAULT 0,
        estoque_atual REAL DEFAULT 0,
        unidade TEXT DEFAULT 'UN',
        ativo INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _createServicosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS servicos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        valor_padrao REAL DEFAULT 0,
        ativo INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _createOrdensServicoTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ordens_servico (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER,
        titulo TEXT NOT NULL,
        descricao TEXT,
        status TEXT DEFAULT 'ORCAMENTO',
        data_abertura TEXT NOT NULL,
        data_previsao TEXT,
        data_conclusao TEXT,
        subtotal REAL DEFAULT 0,
        desconto REAL DEFAULT 0,
        acrescimo REAL DEFAULT 0,
        total REAL DEFAULT 0,
        valor_pago REAL DEFAULT 0,
        valor_pendente REAL DEFAULT 0,
        observacoes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (cliente_id) REFERENCES clientes(id)
      )
    ''');
  }

  Future<void> _createOrdemServicoItensTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ordem_servico_itens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ordem_servico_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        servico_id INTEGER,
        produto_id INTEGER,
        descricao TEXT NOT NULL,
        quantidade REAL DEFAULT 1,
        valor_unitario REAL DEFAULT 0,
        valor_total REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (ordem_servico_id) REFERENCES ordens_servico(id),
        FOREIGN KEY (servico_id) REFERENCES servicos(id),
        FOREIGN KEY (produto_id) REFERENCES produtos(id)
      )
    ''');
  }

  Future<void> _createPagamentosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pagamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ordem_servico_id INTEGER NOT NULL,
        valor REAL NOT NULL,
        forma_pagamento TEXT,
        status TEXT DEFAULT 'PAGO',
        data_pagamento TEXT NOT NULL,
        observacoes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (ordem_servico_id) REFERENCES ordens_servico(id)
      )
    ''');
  }

  Future<void> _createPagamentosAlunosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pagamentos_alunos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        valor REAL NOT NULL,
        vencimento TEXT NOT NULL,
        status TEXT DEFAULT 'PENDENTE',
        descricao TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (cliente_id) REFERENCES clientes(id)
      )
    ''');
  }

  Future<void> _createAppConfigTable(Database db) async {
    await db.execute('''
  CREATE TABLE IF NOT EXISTS app_config (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_empresa TEXT DEFAULT 'FitCheck',
    cor_primaria TEXT DEFAULT '#2563EB',
    cor_secundaria TEXT DEFAULT '#22C55E',
    logo_path TEXT,

    telefone TEXT,
    whatsapp TEXT,
    email TEXT,
    cep TEXT,
    instagram TEXT,
    documento TEXT,
    endereco TEXT,
    cidade TEXT,
    estado TEXT,

    mensagem_resumo_os TEXT,
    mensagem_cobranca TEXT,

    tipo_servico TEXT DEFAULT 'PERSONAL_TRAINER',

    created_at TEXT NOT NULL,
    updated_at TEXT
  )
''');

    await _garantirConfigAppPadrao(db);
  }

  Future<void> _garantirConfigAppPadrao(Database db) async {
    final result = await db.query('app_config', orderBy: 'id ASC', limit: 1);

    if (result.isEmpty) {
      await db.insert('app_config', {
        'nome_empresa': AppRuntime.definition.defaultBusinessName,
        'cor_primaria': '#2563EB',
        'cor_secundaria': '#22C55E',
        'logo_path': null,
        'telefone': null,
        'whatsapp': null,
        'email': null,
        'cep': null,
        'instagram': null,
        'documento': null,
        'endereco': null,
        'cidade': null,
        'estado': null,
        'mensagem_resumo_os': null,
        'mensagem_cobranca': null,
        'tipo_servico': 'PERSONAL_TRAINER',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': null,
      });
    }
  }

  Future<void> _createAgendaTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS agenda (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cliente_id INTEGER,
      ordem_servico_id INTEGER,
      service_location_id INTEGER,

      titulo TEXT NOT NULL,
      descricao TEXT,

      data_inicio TEXT NOT NULL,
      hora_inicio TEXT NOT NULL,
      hora_fim TEXT,

      status TEXT DEFAULT 'AGENDADO',

      recorrente INTEGER DEFAULT 0,
      tipo_recorrencia TEXT,
      dias_semana TEXT,
      data_fim_recorrencia TEXT,

      observacoes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT,

      FOREIGN KEY (cliente_id) REFERENCES clientes(id),
      FOREIGN KEY (ordem_servico_id) REFERENCES ordens_servico(id),
      FOREIGN KEY (service_location_id) REFERENCES service_locations(id)
    )
  ''');
  }

  Future<void> _createServiceLocationsTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS service_locations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      address TEXT,
      neighborhood TEXT,
      city TEXT,
      state TEXT,
      zip_code TEXT,
      latitude REAL,
      longitude REAL,
      type TEXT DEFAULT 'OUTRO',
      notes TEXT,
      is_public INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT
    )
  ''');
  }

  Future<void> _createSupportMessagesTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS support_messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      remote_id TEXT,
      sender TEXT NOT NULL,
      message TEXT NOT NULL,
      status TEXT DEFAULT 'PENDING',
      created_at TEXT NOT NULL,
      updated_at TEXT
    )
  ''');
  }

  Future<void> _createAnamnesesTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS anamneses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cliente_id INTEGER NOT NULL,
      tipo_servico TEXT NOT NULL,

      objetivo TEXT,
      queixa_principal TEXT,
      historico_saude TEXT,
      lesoes TEXT,
      cirurgias TEXT,
      medicamentos TEXT,
      alergias TEXT,
      dores TEXT,
      limitacoes TEXT,
      nivel_atividade TEXT,
      observacoes TEXT,

      data_anamnese TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT,

      FOREIGN KEY (cliente_id) REFERENCES clientes(id)
    )
  ''');
  }

  Future<void> _createLembretesTable(Database db) async {
    await db.execute('''
  CREATE TABLE IF NOT EXISTS lembretes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      titulo TEXT NOT NULL,
      descricao TEXT,
      tipo TEXT DEFAULT 'GERAL',
      data_inicio TEXT NOT NULL,
      hora TEXT,
      recorrencia TEXT DEFAULT 'NENHUMA',
      ativo INTEGER DEFAULT 1,
      concluido INTEGER DEFAULT 0,
      ultima_execucao TEXT,
      created_at TEXT NOT NULL
    )
  ''');
  }

  Future<void> _createAtendimentosTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS atendimentos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cliente_id INTEGER NOT NULL,
      agenda_id INTEGER,
      data_atendimento TEXT NOT NULL,
      hora_inicio TEXT NOT NULL,
      hora_fim TEXT,
      duracao_minutos INTEGER DEFAULT 0,
      treino_realizado TEXT,
      observacoes TEXT,
      status TEXT DEFAULT 'FINALIZADO',
      created_at TEXT NOT NULL,
      updated_at TEXT,
      FOREIGN KEY (cliente_id) REFERENCES clientes(id),
      FOREIGN KEY (agenda_id) REFERENCES agenda(id)
    )
  ''');
  }

  Future<void> _createAppUsersTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS app_users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      remote_user_id TEXT,
      nome TEXT NOT NULL,
      email TEXT,
      telefone TEXT,
      profissao TEXT,
      cidade TEXT,
      estado TEXT,
      device_id TEXT,
      plataforma TEXT,
      app_version TEXT,
      fcm_token TEXT,
      created_at TEXT NOT NULL,
      last_sync_at TEXT
    )
  ''');
  }

  Future<void> _createAppRemoteStatusTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS app_remote_status (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      app_enabled INTEGER DEFAULT 1,
      user_blocked INTEGER DEFAULT 0,
      force_update INTEGER DEFAULT 0,
      min_version TEXT,
      notice_active INTEGER DEFAULT 0,
      notice_title TEXT,
      notice_message TEXT,
      notice_type TEXT,
      agenda_enabled INTEGER DEFAULT 1,
      payments_enabled INTEGER DEFAULT 1,
      backup_enabled INTEGER DEFAULT 1,
      updated_at TEXT NOT NULL
    )
  ''');
  }

  // =========================
  // USUARIO DO APP / CONTROLE ADMIN
  // =========================

  Future<AppUserModel?> buscarAppUser() async {
    final db = await instance.database;

    final result = await db.query('app_users', orderBy: 'id ASC', limit: 1);

    if (result.isEmpty) return null;
    return AppUserModel.fromMap(result.first);
  }

  Future<int> salvarAppUser(AppUserModel user) async {
    final db = await instance.database;

    if (user.id == null) {
      return await db.insert('app_users', user.toMap());
    }

    await db.update(
      'app_users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );

    return user.id!;
  }

  Future<void> atualizarAppUserToken({
    required int userId,
    required String? remoteUserId,
    required String? fcmToken,
  }) async {
    final db = await instance.database;

    await db.update(
      'app_users',
      {
        'remote_user_id': remoteUserId,
        'fcm_token': fcmToken,
        'last_sync_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<AppRemoteStatusModel?> buscarRemoteStatusCache() async {
    final db = await instance.database;

    final result = await db.query(
      'app_remote_status',
      where: 'id = 1',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return AppRemoteStatusModel.fromMap(result.first);
  }

  Future<void> salvarRemoteStatusCache(AppRemoteStatusModel status) async {
    final db = await instance.database;

    await db.insert('app_remote_status', {
      ...status.toMap(),
      'id': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // =========================
  // CLIENTES
  // =========================

  Future<int> criarCliente(ClienteModel cliente) async {
    final db = await instance.database;
    return await db.insert('clientes', cliente.toMap());
  }

  Future<List<ClienteModel>> listarClientes() async {
    final db = await instance.database;
    final result = await db.query('clientes', orderBy: 'nome ASC');
    return result.map((map) => ClienteModel.fromMap(map)).toList();
  }

  Future<ClienteModel?> buscarClientePorId(int id) async {
    final db = await instance.database;

    final result = await db.query(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ClienteModel.fromMap(result.first);
  }

  Future<int> atualizarCliente(ClienteModel cliente) async {
    final db = await instance.database;

    return await db.update(
      'clientes',
      cliente.toMap(),
      where: 'id = ?',
      whereArgs: [cliente.id],
    );
  }

  Future<int> deletarCliente(int id) async {
    final db = await instance.database;
    await db.delete(
      'pagamentos_alunos',
      where: 'cliente_id = ?',
      whereArgs: [id],
    );
    return await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
  }

  // =========================
  // PRODUTOS
  // =========================

  Future<int> criarProduto(ProdutoModel produto) async {
    final db = await instance.database;
    return await db.insert('produtos', produto.toMap());
  }

  Future<List<ProdutoModel>> listarProdutos() async {
    final db = await instance.database;
    final result = await db.query('produtos', orderBy: 'nome ASC');
    return result.map((map) => ProdutoModel.fromMap(map)).toList();
  }

  Future<ProdutoModel?> buscarProdutoPorId(int id) async {
    final db = await instance.database;

    final result = await db.query(
      'produtos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ProdutoModel.fromMap(result.first);
  }

  Future<int> atualizarProduto(ProdutoModel produto) async {
    final db = await instance.database;

    return await db.update(
      'produtos',
      produto.toMap(),
      where: 'id = ?',
      whereArgs: [produto.id],
    );
  }

  Future<int> deletarProduto(int id) async {
    final db = await instance.database;
    return await db.delete('produtos', where: 'id = ?', whereArgs: [id]);
  }

  // =========================
  // SERVIÇOS
  // =========================

  Future<int> criarServico(ServicoModel servico) async {
    final db = await instance.database;
    return await db.insert('servicos', servico.toMap());
  }

  Future<List<ServicoModel>> listarServicos() async {
    final db = await instance.database;
    final result = await db.query('servicos', orderBy: 'nome ASC');
    return result.map((map) => ServicoModel.fromMap(map)).toList();
  }

  Future<ServicoModel?> buscarServicoPorId(int id) async {
    final db = await instance.database;

    final result = await db.query(
      'servicos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ServicoModel.fromMap(result.first);
  }

  Future<int> atualizarServico(ServicoModel servico) async {
    final db = await instance.database;

    return await db.update(
      'servicos',
      servico.toMap(),
      where: 'id = ?',
      whereArgs: [servico.id],
    );
  }

  Future<int> deletarServico(int id) async {
    final db = await instance.database;
    return await db.delete('servicos', where: 'id = ?', whereArgs: [id]);
  }

  // =========================
  // ORDENS DE SERVIÇO
  // =========================

  Future<int> criarOrdemServico(OrdemServicoModel ordem) async {
    final db = await instance.database;
    return await db.insert('ordens_servico', ordem.toMap());
  }

  Future<List<OrdemServicoModel>> listarOrdensServico() async {
    final db = await instance.database;
    final result = await db.query('ordens_servico', orderBy: 'id DESC');
    return result.map((map) => OrdemServicoModel.fromMap(map)).toList();
  }

  Future<OrdemServicoModel?> buscarOrdemServicoPorId(int id) async {
    final db = await instance.database;

    final result = await db.query(
      'ordens_servico',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return OrdemServicoModel.fromMap(result.first);
  }

  Future<int> atualizarOrdemServico(OrdemServicoModel ordem) async {
    final db = await instance.database;

    return await db.update(
      'ordens_servico',
      ordem.toMap(),
      where: 'id = ?',
      whereArgs: [ordem.id],
    );
  }

  Future<int> deletarOrdemServico(int id) async {
    final db = await instance.database;

    await db.delete(
      'pagamentos',
      where: 'ordem_servico_id = ?',
      whereArgs: [id],
    );

    await db.delete(
      'ordem_servico_itens',
      where: 'ordem_servico_id = ?',
      whereArgs: [id],
    );

    return await db.delete('ordens_servico', where: 'id = ?', whereArgs: [id]);
  }

  // =========================
  // ITENS DA ORDEM
  // =========================

  Future<int> criarItemOrdemServico(OrdemServicoItemModel item) async {
    final db = await instance.database;
    return await db.insert('ordem_servico_itens', item.toMap());
  }

  Future<List<OrdemServicoItemModel>> listarItensDaOrdem(
    int ordemServicoId,
  ) async {
    final db = await instance.database;

    final result = await db.query(
      'ordem_servico_itens',
      where: 'ordem_servico_id = ?',
      whereArgs: [ordemServicoId],
      orderBy: 'id ASC',
    );

    return result.map((map) => OrdemServicoItemModel.fromMap(map)).toList();
  }

  Future<int> deletarItemOrdemServico(int id) async {
    final db = await instance.database;

    return await db.delete(
      'ordem_servico_itens',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletarItensDaOrdem(int ordemServicoId) async {
    final db = await instance.database;

    return await db.delete(
      'ordem_servico_itens',
      where: 'ordem_servico_id = ?',
      whereArgs: [ordemServicoId],
    );
  }

  Future<int> salvarOrdemComItens({
    required OrdemServicoModel ordem,
    required List<OrdemServicoItemModel> itens,
  }) async {
    final db = await instance.database;

    return await db.transaction<int>((txn) async {
      int ordemId;

      if (ordem.id == null) {
        ordemId = await txn.insert('ordens_servico', ordem.toMap());
      } else {
        ordemId = ordem.id!;

        final itensAntigos = await txn.query(
          'ordem_servico_itens',
          where: 'ordem_servico_id = ?',
          whereArgs: [ordemId],
        );

        for (final item in itensAntigos) {
          if (item['tipo'] == 'PRODUTO' && item['produto_id'] != null) {
            await txn.rawUpdate(
              '''
              UPDATE produtos
              SET estoque_atual = estoque_atual + ?
              WHERE id = ?
              ''',
              [item['quantidade'], item['produto_id']],
            );
          }
        }

        await txn.update(
          'ordens_servico',
          ordem.toMap(),
          where: 'id = ?',
          whereArgs: [ordemId],
        );

        await txn.delete(
          'ordem_servico_itens',
          where: 'ordem_servico_id = ?',
          whereArgs: [ordemId],
        );
      }

      for (final item in itens) {
        final novoItem = item.copyWith(ordemServicoId: ordemId);

        await txn.insert('ordem_servico_itens', novoItem.toMap());

        if (novoItem.tipo == 'PRODUTO' && novoItem.produtoId != null) {
          await txn.rawUpdate(
            '''
            UPDATE produtos
            SET estoque_atual = estoque_atual - ?
            WHERE id = ?
            ''',
            [novoItem.quantidade, novoItem.produtoId],
          );
        }
      }

      return ordemId;
    });
  }

  Future<void> atualizarEstoqueProduto({
    required int produtoId,
    required double quantidade,
  }) async {
    final db = await instance.database;

    await db.rawUpdate(
      '''
      UPDATE produtos
      SET estoque_atual = estoque_atual - ?
      WHERE id = ?
      ''',
      [quantidade, produtoId],
    );
  }

  // =========================
  // PAGAMENTOS
  // =========================

  Future<int> criarPagamento(PagamentoModel pagamento) async {
    final db = await instance.database;

    return await db.transaction<int>((txn) async {
      final pagamentoId = await txn.insert('pagamentos', pagamento.toMap());

      final result = await txn.rawQuery(
        '''
        SELECT 
          total,
          COALESCE((
            SELECT SUM(valor) 
            FROM pagamentos 
            WHERE ordem_servico_id = ?
            AND status = 'PAGO'
          ), 0) AS total_pago
        FROM ordens_servico
        WHERE id = ?
        ''',
        [pagamento.ordemServicoId, pagamento.ordemServicoId],
      );

      if (result.isNotEmpty) {
        final total = (result.first['total'] as num).toDouble();
        final totalPago = (result.first['total_pago'] as num).toDouble();
        final pendente = total - totalPago;

        await txn.update(
          'ordens_servico',
          {
            'valor_pago': totalPago,
            'valor_pendente': pendente < 0 ? 0 : pendente,
            'status': pendente <= 0 ? 'PAGO' : 'AGUARDANDO_PAGAMENTO',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [pagamento.ordemServicoId],
        );
      }

      return pagamentoId;
    });
  }

  Future<List<PagamentoModel>> listarPagamentos() async {
    final db = await instance.database;
    final result = await db.query('pagamentos', orderBy: 'id DESC');
    return result.map((map) => PagamentoModel.fromMap(map)).toList();
  }

  Future<List<PagamentoModel>> listarPagamentosPorOrdem(
    int ordemServicoId,
  ) async {
    final db = await instance.database;

    final result = await db.query(
      'pagamentos',
      where: 'ordem_servico_id = ?',
      whereArgs: [ordemServicoId],
      orderBy: 'id DESC',
    );

    return result.map((map) => PagamentoModel.fromMap(map)).toList();
  }

  Future<Map<String, double>> resumoFinanceiro() async {
    final db = await instance.database;

    final recebidoResult = await db.rawQuery('''
      SELECT COALESCE(SUM(valor), 0) AS total
      FROM pagamentos
      WHERE status = 'PAGO'
    ''');

    final pendenteResult = await db.rawQuery('''
      SELECT COALESCE(SUM(valor_pendente), 0) AS total
      FROM ordens_servico
      WHERE status != 'CANCELADO'
    ''');

    return {
      'recebido': (recebidoResult.first['total'] as num).toDouble(),
      'pendente': (pendenteResult.first['total'] as num).toDouble(),
    };
  }

  // =========================
  // PAGAMENTOS DOS ALUNOS
  // =========================

  Future<int> criarPagamentoAluno(PagamentoAlunoModel pagamento) async {
    final db = await instance.database;
    return await db.insert('pagamentos_alunos', pagamento.toMap());
  }

  Future<int> atualizarPagamentoAluno(PagamentoAlunoModel pagamento) async {
    final db = await instance.database;

    return await db.update(
      'pagamentos_alunos',
      pagamento.toMap(),
      where: 'id = ?',
      whereArgs: [pagamento.id],
    );
  }

  Future<int> deletarPagamentoAluno(int id) async {
    final db = await instance.database;
    return await db.delete(
      'pagamentos_alunos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<PagamentoAlunoModel>> listarPagamentosAlunos() async {
    final db = await instance.database;

    final result = await db.query(
      'pagamentos_alunos',
      orderBy: 'vencimento DESC, id DESC',
    );

    return result.map((map) => PagamentoAlunoModel.fromMap(map)).toList();
  }

  Future<List<PagamentoAlunoModel>> listarPagamentosPorCliente(
    int clienteId,
  ) async {
    final db = await instance.database;

    final result = await db.query(
      'pagamentos_alunos',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'vencimento DESC, id DESC',
    );

    return result.map((map) => PagamentoAlunoModel.fromMap(map)).toList();
  }

  Future<Map<String, double>> resumoFinanceiroAlunos() async {
    final pagamentos = await listarPagamentosAlunos();

    double recebido = 0;
    double pendente = 0;
    double vencido = 0;

    for (final pagamento in pagamentos) {
      final status = pagamento.statusCalculado();

      if (status == PagamentoAlunoModel.statusPago) {
        recebido += pagamento.valor;
      } else if (status == PagamentoAlunoModel.statusVencido) {
        vencido += pagamento.valor;
      } else {
        pendente += pagamento.valor;
      }
    }

    return {'recebido': recebido, 'pendente': pendente, 'vencido': vencido};
  }

  // =========================
  // CONFIGURAÇÃO DO APP
  // =========================

  Future<AppConfigModel> buscarConfigApp() async {
    final db = await instance.database;

    final result = await db.query('app_config', orderBy: 'id ASC', limit: 1);

    if (result.isEmpty) {
      final agora = DateTime.now().toIso8601String();

      final id = await db.insert('app_config', {
        'nome_empresa': AppRuntime.definition.defaultBusinessName,
        'cor_primaria': '#2563EB',
        'cor_secundaria': '#22C55E',
        'logo_path': null,
        'telefone': '',
        'whatsapp': '',
        'email': '',
        'cep': '',
        'instagram': '',
        'documento': '',
        'endereco': '',
        'cidade': '',
        'estado': '',
        'mensagem_resumo_os':
            'Olá {cliente}, tudo bem?\n\nSegue o resumo da sua ordem de serviço:\n\n{resumo_os}\n\nTotal: {total}\n\nObrigado pela preferência!',
        'mensagem_cobranca':
            'Olá {cliente}, tudo bem?\n\nEstamos passando para lembrar do pagamento referente à ordem de serviço {numero_os}.\n\nValor pendente: {valor_pendente}',
        'created_at': agora,
        'updated_at': null,
      });

      final novo = await db.query(
        'app_config',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      return AppConfigModel.fromMap(novo.first);
    }

    return AppConfigModel.fromMap(result.first);
  }

  Future<int> salvarConfigApp(AppConfigModel config) async {
    final db = await instance.database;

    return await db.update(
      'app_config',
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  // =========================
  // AGENDA
  // =========================

  Future<int> criarAgenda(AgendaModel agenda) async {
    final db = await instance.database;
    return await db.insert('agenda', agenda.toMap());
  }

  Future<List<AgendaModel>> listarAgenda() async {
    final db = await instance.database;

    final result = await db.query(
      'agenda',
      orderBy: 'data_inicio ASC, hora_inicio ASC',
    );

    return result.map((map) => AgendaModel.fromMap(map)).toList();
  }

  Future<List<AgendaModel>> listarAgendaPorData(String data) async {
    final db = await instance.database;

    final result = await db.query(
      'agenda',
      where: 'data_inicio = ?',
      whereArgs: [data],
      orderBy: 'hora_inicio ASC',
    );

    return result.map((map) => AgendaModel.fromMap(map)).toList();
  }

  Future<List<AgendaModel>> listarAgendaPorPeriodo({
    required String dataInicio,
    required String dataFim,
  }) async {
    final db = await instance.database;

    final result = await db.query(
      'agenda',
      where: 'data_inicio >= ? AND data_inicio <= ?',
      whereArgs: [dataInicio, dataFim],
      orderBy: 'data_inicio ASC, hora_inicio ASC',
    );

    return result.map((map) => AgendaModel.fromMap(map)).toList();
  }

  Future<int> contarAgendaPorPeriodo({
    required String dataInicio,
    required String dataFim,
  }) async {
    final db = await instance.database;

    final result = await db.rawQuery(
      '''
    SELECT COUNT(*) AS total
    FROM agenda
    WHERE data_inicio >= ?
      AND data_inicio <= ?
      AND status != 'CANCELADO'
    ''',
      [dataInicio, dataFim],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  Future<AgendaModel?> buscarAgendaPorId(int id) async {
    final db = await instance.database;

    final result = await db.query(
      'agenda',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return AgendaModel.fromMap(result.first);
  }

  Future<int> atualizarAgenda(AgendaModel agenda) async {
    final db = await instance.database;

    return await db.update(
      'agenda',
      agenda.toMap(),
      where: 'id = ?',
      whereArgs: [agenda.id],
    );
  }

  Future<int> deletarAgenda(int id) async {
    final db = await instance.database;

    return await db.delete('agenda', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AgendaModel>> listarAgendaDoDiaComRecorrencia(
    DateTime data,
  ) async {
    final db = await instance.database;

    String dataSql(DateTime d) {
      return '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    }

    String diaSemanaCodigo(DateTime d) {
      const dias = {
        1: 'SEG',
        2: 'TER',
        3: 'QUA',
        4: 'QUI',
        5: 'SEX',
        6: 'SAB',
        7: 'DOM',
      };

      return dias[d.weekday]!;
    }

    final dataTexto = dataSql(data);
    final diaCodigo = diaSemanaCodigo(data);

    final normais = await db.query(
      'agenda',
      where: 'data_inicio = ? AND recorrente = 0',
      whereArgs: [dataTexto],
    );

    final recorrentes = await db.query(
      'agenda',
      where: '''
      recorrente = 1
      AND data_inicio <= ?
      AND (
        data_fim_recorrencia IS NULL 
        OR data_fim_recorrencia = '' 
        OR data_fim_recorrencia >= ?
      )
      AND dias_semana LIKE ?
    ''',
      whereArgs: [dataTexto, dataTexto, '%$diaCodigo%'],
    );

    final todos = [
      ...normais.map((map) => AgendaModel.fromMap(map)),
      ...recorrentes.map((map) => AgendaModel.fromMap(map)),
    ];

    todos.sort((a, b) => a.horaInicio.compareTo(b.horaInicio));

    return todos;
  }

  Future<bool> existeConflitoAgenda({
    int? agendaIdIgnorar,
    required String dataInicio,
    required String horaInicio,
    required String horaFim,
  }) async {
    final db = await instance.database;

    final result = await db.query(
      'agenda',
      where: '''
      data_inicio = ?
      AND status != 'CANCELADO'
      AND id != COALESCE(?, -1)
      AND (
        (? < hora_fim AND ? > hora_inicio)
        OR hora_fim = ''
      )
    ''',
      whereArgs: [dataInicio, agendaIdIgnorar, horaInicio, horaFim],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // =========================
  // ATENDIMENTOS
  // =========================

  Future<int> criarAtendimento(AtendimentoModel atendimento) async {
    final db = await instance.database;
    return await db.insert('atendimentos', atendimento.toMap());
  }

  Future<List<AtendimentoModel>> listarAtendimentos() async {
    final db = await instance.database;

    final result = await db.query(
      'atendimentos',
      orderBy: 'data_atendimento DESC, hora_inicio DESC',
    );

    return result.map((map) => AtendimentoModel.fromMap(map)).toList();
  }

  Future<List<AtendimentoModel>> listarAtendimentosPorCliente(
    int clienteId,
  ) async {
    final db = await instance.database;

    final result = await db.query(
      'atendimentos',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'data_atendimento DESC, hora_inicio DESC',
    );

    return result.map((map) => AtendimentoModel.fromMap(map)).toList();
  }

  Future<List<AtendimentoModel>> listarAtendimentosPorData(String data) async {
    final db = await instance.database;

    final result = await db.query(
      'atendimentos',
      where: 'data_atendimento = ?',
      whereArgs: [data],
      orderBy: 'hora_inicio DESC',
    );

    return result.map((map) => AtendimentoModel.fromMap(map)).toList();
  }

  Future<double> totalPagoDaOrdem(int ordemServicoId) async {
    final db = await instance.database;

    final result = await db.rawQuery(
      '''
    SELECT COALESCE(SUM(valor), 0) AS total_pago
    FROM pagamentos
    WHERE ordem_servico_id = ?
      AND status = 'PAGO'
    ''',
      [ordemServicoId],
    );

    return (result.first['total_pago'] as num).toDouble();
  }

  Future<int> atualizarTipoServicoApp(String tipoServico) async {
    final db = await instance.database;

    return await db.update(
      'app_config',
      {
        'tipo_servico': tipoServico,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<String> buscarTipoServicoApp() async {
    final db = await instance.database;

    final result = await db.query(
      'app_config',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) {
      return 'PERSONAL_TRAINER';
    }

    return result.first['tipo_servico']?.toString() ?? 'PERSONAL_TRAINER';
  }

  // =========================
  // TREINOS / EXERCÍCIOS
  // =========================

  Future<int> criarExercicio(ExercicioModel exercicio) async {
    final db = await instance.database;
    return await TreinosDatabase.criarExercicio(db, exercicio);
  }

  Future<List<ExercicioModel>> listarExercicios() async {
    final db = await instance.database;
    return await TreinosDatabase.listarExercicios(db);
  }

  Future<List<ExercicioModel>> listarExerciciosPorCategoria(
    String categoria,
  ) async {
    final db = await instance.database;
    return await TreinosDatabase.listarExerciciosPorCategoria(db, categoria);
  }

  Future<ExercicioModel?> buscarExercicioPorId(int id) async {
    final db = await instance.database;
    return await TreinosDatabase.buscarExercicioPorId(db, id);
  }

  Future<int> atualizarExercicio(ExercicioModel exercicio) async {
    final db = await instance.database;
    return await TreinosDatabase.atualizarExercicio(db, exercicio);
  }

  Future<int> deletarExercicio(int id) async {
    final db = await instance.database;
    return await TreinosDatabase.deletarExercicio(db, id);
  }

  Future<int> alternarFavoritoExercicio({
    required int id,
    required int favorito,
  }) async {
    final db = await instance.database;

    return await TreinosDatabase.alternarFavoritoExercicio(
      db: db,
      id: id,
      favorito: favorito,
    );
  }

  Future<int> criarTreino(TreinoModel treino) async {
    final db = await instance.database;
    return await TreinosDatabase.criarTreino(db, treino);
  }

  Future<List<TreinoModel>> listarTreinos() async {
    final db = await instance.database;
    return await TreinosDatabase.listarTreinos(db);
  }

  Future<List<TreinoModel>> listarTreinosPorCliente(int clienteId) async {
    final db = await instance.database;
    return await TreinosDatabase.listarTreinosPorCliente(db, clienteId);
  }

  Future<TreinoModel?> buscarTreinoPorId(int id) async {
    final db = await instance.database;
    return await TreinosDatabase.buscarTreinoPorId(db, id);
  }

  Future<int> atualizarTreino(TreinoModel treino) async {
    final db = await instance.database;
    return await TreinosDatabase.atualizarTreino(db, treino);
  }

  Future<int> deletarTreino(int id) async {
    final db = await instance.database;
    return await TreinosDatabase.deletarTreino(db, id);
  }

  Future<int> criarItemTreino(TreinoItemModel item) async {
    final db = await instance.database;
    return await TreinosDatabase.criarItemTreino(db, item);
  }

  Future<List<TreinoItemModel>> listarItensDoTreino(int treinoId) async {
    final db = await instance.database;
    return await TreinosDatabase.listarItensDoTreino(db, treinoId);
  }

  Future<int> atualizarItemTreino(TreinoItemModel item) async {
    final db = await instance.database;
    return await TreinosDatabase.atualizarItemTreino(db, item);
  }

  Future<int> deletarItemTreino(int id) async {
    final db = await instance.database;
    return await TreinosDatabase.deletarItemTreino(db, id);
  }

  Future<int> deletarItensDoTreino(int treinoId) async {
    final db = await instance.database;
    return await TreinosDatabase.deletarItensDoTreino(db, treinoId);
  }

  Future<int> salvarTreinoComItens({
    required TreinoModel treino,
    required List<TreinoItemModel> itens,
  }) async {
    final db = await instance.database;

    return await TreinosDatabase.salvarTreinoComItens(
      db: db,
      treino: treino,
      itens: itens,
    );
  }

  Future<int> duplicarTreinoParaCliente({
    required int treinoModeloId,
    required int clienteId,
  }) async {
    final db = await instance.database;

    return await TreinosDatabase.duplicarTreinoParaCliente(
      db: db,
      treinoModeloId: treinoModeloId,
      clienteId: clienteId,
    );
  }

  // =========================
  // LOCAIS DE ATENDIMENTO
  // =========================

  Future<int> criarServiceLocation(ServiceLocationModel location) async {
    final db = await instance.database;
    return await db.insert('service_locations', location.toMap());
  }

  Future<List<ServiceLocationModel>> listarServiceLocations() async {
    final db = await instance.database;

    final result = await db.query(
      'service_locations',
      orderBy: 'name ASC, id DESC',
    );

    return result.map((map) => ServiceLocationModel.fromMap(map)).toList();
  }

  Future<ServiceLocationModel?> buscarServiceLocationPorId(int id) async {
    final db = await instance.database;

    final result = await db.query(
      'service_locations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ServiceLocationModel.fromMap(result.first);
  }

  Future<int> atualizarServiceLocation(ServiceLocationModel location) async {
    final db = await instance.database;

    return await db.update(
      'service_locations',
      location.copyWith(updatedAt: DateTime.now().toIso8601String()).toMap(),
      where: 'id = ?',
      whereArgs: [location.id],
    );
  }

  Future<int> deletarServiceLocation(int id) async {
    final db = await instance.database;
    return await db.delete(
      'service_locations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // SUPORTE
  // =========================

  Future<int> criarSupportMessage(SupportMessageModel message) async {
    final db = await instance.database;
    return await db.insert('support_messages', message.toMap());
  }

  Future<List<SupportMessageModel>> listarSupportMessages() async {
    final db = await instance.database;

    final result = await db.query(
      'support_messages',
      orderBy: 'created_at ASC, id ASC',
    );

    return result.map((map) => SupportMessageModel.fromMap(map)).toList();
  }

  Future<int> atualizarSupportMessage(SupportMessageModel message) async {
    final db = await instance.database;

    return await db.update(
      'support_messages',
      message.copyWith(updatedAt: DateTime.now().toIso8601String()).toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  // =========================
  // ROTINAS RAPIDAS
  // =========================

  Future<List<Map<String, Object?>>> listarQuickRoutines() async {
    final db = await instance.database;
    return db.query('quick_routines', orderBy: 'position ASC, id ASC');
  }

  Future<int> criarQuickRoutine({
    required String actionKey,
    required String label,
  }) async {
    final db = await instance.database;
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM quick_routines'),
        ) ??
        0;
    return db.insert('quick_routines', {
      'action_key': actionKey,
      'label': label,
      'position': count,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> deletarQuickRoutine(int id) async {
    final db = await instance.database;
    return db.delete('quick_routines', where: 'id = ?', whereArgs: [id]);
  }

  // =========================
  // FECHAR BANCO
  // =========================

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
