import 'package:sqflite/sqflite.dart';

import '../models/anamnese_model.dart';
import 'app_database.dart';

class AnamneseDatabase {
  AnamneseDatabase._();

  static final AnamneseDatabase instance = AnamneseDatabase._();

  Future<Database> get _db async {
    return await AppDatabase.instance.database;
  }

  Future<int> criarAnamnese(AnamneseModel anamnese) async {
    final db = await _db;

    return await db.insert(
      'anamneses',
      anamnese.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AnamneseModel>> listarAnamneses() async {
    final db = await _db;

    final result = await db.query(
      'anamneses',
      orderBy: 'data_anamnese DESC, id DESC',
    );

    return result.map((map) => AnamneseModel.fromMap(map)).toList();
  }

  Future<List<AnamneseModel>> listarPorCliente(int clienteId) async {
    final db = await _db;

    final result = await db.query(
      'anamneses',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'data_anamnese DESC, id DESC',
    );

    return result.map((map) => AnamneseModel.fromMap(map)).toList();
  }

  Future<AnamneseModel?> buscarPorId(int id) async {
    final db = await _db;

    final result = await db.query(
      'anamneses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return AnamneseModel.fromMap(result.first);
  }

  Future<int> atualizarAnamnese(AnamneseModel anamnese) async {
    final db = await _db;

    return await db.update(
      'anamneses',
      anamnese.toMap(),
      where: 'id = ?',
      whereArgs: [anamnese.id],
    );
  }

  Future<int> salvarAnamnese(AnamneseModel anamnese) async {
    if (anamnese.id == null) {
      return await criarAnamnese(anamnese);
    }

    return await atualizarAnamnese(anamnese);
  }

  Future<int> excluirAnamnese(int id) async {
    final db = await _db;

    return await db.delete('anamneses', where: 'id = ?', whereArgs: [id]);
  }
}
