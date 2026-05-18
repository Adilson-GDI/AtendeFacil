import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/cliente_model.dart';
import '../models/produto_model.dart';
import '../models/servico_model.dart';
import '../models/ordem_servico_model.dart';
import '../models/ordem_servico_item_model.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();

  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('atende_facil.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
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
  // FECHAR BANCO
  // =========================

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
