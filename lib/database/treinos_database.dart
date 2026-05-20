import 'package:sqflite/sqflite.dart';

import '../models/exercicio_model.dart';
import '../models/treino_model.dart';
import '../models/treino_item_model.dart';

class TreinosDatabase {
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercicios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        categoria TEXT,
        grupo_muscular TEXT,
        descricao TEXT,
        video_url TEXT,
        favorito INTEGER DEFAULT 0,
        ativo INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS treinos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER,
        nome TEXT NOT NULL,
        divisao TEXT,
        objetivo TEXT,
        observacoes TEXT,
        ativo INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (cliente_id) REFERENCES clientes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS treino_itens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        treino_id INTEGER NOT NULL,
        exercicio_id INTEGER,
        nome_exercicio TEXT NOT NULL,
        categoria TEXT,
        grupo_muscular TEXT,
        ordem INTEGER DEFAULT 0,
        series TEXT,
        repeticoes TEXT,
        carga TEXT,
        descanso TEXT,
        tempo TEXT,
        observacoes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (treino_id) REFERENCES treinos(id),
        FOREIGN KEY (exercicio_id) REFERENCES exercicios(id)
      )
    ''');
  }

  // =========================
  // EXERCÍCIOS
  // =========================

  static Future<int> criarExercicio(
    Database db,
    ExercicioModel exercicio,
  ) async {
    return await db.insert('exercicios', exercicio.toMap());
  }

  static Future<List<ExercicioModel>> listarExercicios(Database db) async {
    final result = await db.query(
      'exercicios',
      where: 'ativo = ?',
      whereArgs: [1],
      orderBy: 'nome ASC',
    );

    return result.map((map) => ExercicioModel.fromMap(map)).toList();
  }

  static Future<List<ExercicioModel>> listarExerciciosPorCategoria(
    Database db,
    String categoria,
  ) async {
    final result = await db.query(
      'exercicios',
      where: 'ativo = ? AND categoria = ?',
      whereArgs: [1, categoria],
      orderBy: 'nome ASC',
    );

    return result.map((map) => ExercicioModel.fromMap(map)).toList();
  }

  static Future<ExercicioModel?> buscarExercicioPorId(
    Database db,
    int id,
  ) async {
    final result = await db.query(
      'exercicios',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return ExercicioModel.fromMap(result.first);
  }

  static Future<int> atualizarExercicio(
    Database db,
    ExercicioModel exercicio,
  ) async {
    return await db.update(
      'exercicios',
      exercicio.copyWith(updatedAt: DateTime.now().toIso8601String()).toMap(),
      where: 'id = ?',
      whereArgs: [exercicio.id],
    );
  }

  static Future<int> deletarExercicio(Database db, int id) async {
    return await db.update(
      'exercicios',
      {'ativo': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> alternarFavoritoExercicio({
    required Database db,
    required int id,
    required int favorito,
  }) async {
    return await db.update(
      'exercicios',
      {
        'favorito': favorito == 1 ? 0 : 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // TREINOS
  // =========================

  static Future<int> criarTreino(Database db, TreinoModel treino) async {
    return await db.insert('treinos', treino.toMap());
  }

  static Future<List<TreinoModel>> listarTreinos(Database db) async {
    final result = await db.query(
      'treinos',
      where: 'ativo = ?',
      whereArgs: [1],
      orderBy: 'cliente_id IS NOT NULL ASC, id DESC',
    );

    return result.map((map) => TreinoModel.fromMap(map)).toList();
  }

  static Future<List<TreinoModel>> listarTreinosPorCliente(
    Database db,
    int clienteId,
  ) async {
    final result = await db.query(
      'treinos',
      where: 'ativo = ? AND cliente_id = ?',
      whereArgs: [1, clienteId],
      orderBy: 'id DESC',
    );

    return result.map((map) => TreinoModel.fromMap(map)).toList();
  }

  static Future<TreinoModel?> buscarTreinoPorId(Database db, int id) async {
    final result = await db.query(
      'treinos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return TreinoModel.fromMap(result.first);
  }

  static Future<int> atualizarTreino(Database db, TreinoModel treino) async {
    return await db.update(
      'treinos',
      treino.copyWith(updatedAt: DateTime.now().toIso8601String()).toMap(),
      where: 'id = ?',
      whereArgs: [treino.id],
    );
  }

  static Future<int> deletarTreino(Database db, int id) async {
    return await db.update(
      'treinos',
      {'ativo': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // ITENS DO TREINO
  // =========================

  static Future<int> criarItemTreino(Database db, TreinoItemModel item) async {
    return await db.insert('treino_itens', item.toMap());
  }

  static Future<List<TreinoItemModel>> listarItensDoTreino(
    Database db,
    int treinoId,
  ) async {
    final result = await db.query(
      'treino_itens',
      where: 'treino_id = ?',
      whereArgs: [treinoId],
      orderBy: 'ordem ASC, id ASC',
    );

    return result.map((map) => TreinoItemModel.fromMap(map)).toList();
  }

  static Future<int> atualizarItemTreino(
    Database db,
    TreinoItemModel item,
  ) async {
    return await db.update(
      'treino_itens',
      item.copyWith(updatedAt: DateTime.now().toIso8601String()).toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  static Future<int> deletarItemTreino(Database db, int id) async {
    return await db.delete('treino_itens', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deletarItensDoTreino(Database db, int treinoId) async {
    return await db.delete(
      'treino_itens',
      where: 'treino_id = ?',
      whereArgs: [treinoId],
    );
  }

  static Future<int> salvarTreinoComItens({
    required Database db,
    required TreinoModel treino,
    required List<TreinoItemModel> itens,
  }) async {
    return await db.transaction<int>((txn) async {
      int treinoId;

      if (treino.id == null) {
        treinoId = await txn.insert('treinos', treino.toMap());
      } else {
        treinoId = treino.id!;

        await txn.update(
          'treinos',
          treino.copyWith(updatedAt: DateTime.now().toIso8601String()).toMap(),
          where: 'id = ?',
          whereArgs: [treinoId],
        );

        await txn.delete(
          'treino_itens',
          where: 'treino_id = ?',
          whereArgs: [treinoId],
        );
      }

      for (int i = 0; i < itens.length; i++) {
        final item = itens[i].copyWith(treinoId: treinoId, ordem: i + 1);

        await txn.insert('treino_itens', item.toMap());
      }

      return treinoId;
    });
  }

  static Future<int> duplicarTreinoParaCliente({
    required Database db,
    required int treinoModeloId,
    required int clienteId,
  }) async {
    return await db.transaction<int>((txn) async {
      final treinoResult = await txn.query(
        'treinos',
        where: 'id = ?',
        whereArgs: [treinoModeloId],
        limit: 1,
      );

      if (treinoResult.isEmpty) {
        throw Exception('Treino modelo não encontrado');
      }

      final treinoModelo = TreinoModel.fromMap(treinoResult.first);

      final agora = DateTime.now().toIso8601String();

      final novoTreinoId = await txn.insert('treinos', {
        'cliente_id': clienteId,
        'nome': treinoModelo.nome,
        'divisao': treinoModelo.divisao,
        'objetivo': treinoModelo.objetivo,
        'observacoes': treinoModelo.observacoes,
        'ativo': 1,
        'created_at': agora,
        'updated_at': null,
      });

      final itens = await txn.query(
        'treino_itens',
        where: 'treino_id = ?',
        whereArgs: [treinoModeloId],
        orderBy: 'ordem ASC, id ASC',
      );

      for (final item in itens) {
        await txn.insert('treino_itens', {
          'treino_id': novoTreinoId,
          'exercicio_id': item['exercicio_id'],
          'nome_exercicio': item['nome_exercicio'],
          'categoria': item['categoria'],
          'grupo_muscular': item['grupo_muscular'],
          'ordem': item['ordem'],
          'series': item['series'],
          'repeticoes': item['repeticoes'],
          'carga': item['carga'],
          'descanso': item['descanso'],
          'tempo': item['tempo'],
          'observacoes': item['observacoes'],
          'created_at': agora,
          'updated_at': null,
        });
      }

      return novoTreinoId;
    });
  }
}
