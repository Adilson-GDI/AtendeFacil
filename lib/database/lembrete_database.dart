import 'package:sqflite/sqflite.dart';

import '../models/lembrete_model.dart';
import 'app_database.dart';

class LembreteDatabase {
  static final LembreteDatabase instance = LembreteDatabase._init();

  LembreteDatabase._init();

  Future<Database> get database async {
    return await AppDatabase.instance.database;
  }

  Future<int> criarLembrete(LembreteModel lembrete) async {
    final db = await database;

    final data = lembrete.toMap();
    data.remove('id');

    return await db.insert('lembretes', data);
  }

  Future<int> atualizarLembrete(LembreteModel lembrete) async {
    final db = await database;

    final data = lembrete.toMap();
    data.remove('id');

    return await db.update(
      'lembretes',
      data,
      where: 'id = ?',
      whereArgs: [lembrete.id],
    );
  }

  Future<int> deletarLembrete(int id) async {
    final db = await database;

    return await db.delete('lembretes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LembreteModel>> listarLembretes() async {
    final db = await database;

    final result = await db.query(
      'lembretes',
      orderBy: 'data_inicio ASC, hora ASC',
    );

    return result.map((e) => LembreteModel.fromMap(e)).toList();
  }

  Future<List<LembreteModel>> listarLembretesAtivos() async {
    final db = await database;

    final result = await db.query(
      'lembretes',
      where: 'ativo = ?',
      whereArgs: [1],
      orderBy: 'data_inicio ASC, hora ASC',
    );

    return result.map((e) => LembreteModel.fromMap(e)).toList();
  }

  Future<int> marcarLembreteConcluido(int id, int concluido) async {
    final db = await database;

    return await db.update(
      'lembretes',
      {'concluido': concluido},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> concluirLembreteDoDia(LembreteModel lembrete) async {
    final db = await database;

    final hoje = DateTime.now();
    final hojeSql =
        '${hoje.year.toString().padLeft(4, '0')}-'
        '${hoje.month.toString().padLeft(2, '0')}-'
        '${hoje.day.toString().padLeft(2, '0')}';

    if (lembrete.recorrencia == 'NENHUMA') {
      return await db.update(
        'lembretes',
        {'concluido': 1, 'ultima_execucao': hojeSql},
        where: 'id = ?',
        whereArgs: [lembrete.id],
      );
    }

    return await db.update(
      'lembretes',
      {'ultima_execucao': hojeSql},
      where: 'id = ?',
      whereArgs: [lembrete.id],
    );
  }
}
