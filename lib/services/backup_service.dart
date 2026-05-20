import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

class BackupService {
  static Future<String> exportarBackup() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, 'atende_facil.db');

    final backupDir = Directory.systemTemp;
    final backupPath = join(backupDir.path, 'backup_atende_facil.db');

    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('Banco de dados não encontrado');
    }

    await AppDatabase.instance.close();
    await dbFile.copy(backupPath);

    return backupPath;
  }

  static Future<void> compartilharBackup() async {
    final backupPath = await exportarBackup();

    await Share.shareXFiles([XFile(backupPath)], text: 'Backup Atende Fácil');
  }

  static Future<String?> selecionarBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    return result.files.single.path!;
  }

  static Future<void> restaurarBackup() async {
    final backupSelecionado = await selecionarBackup();

    if (backupSelecionado == null) return;

    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, 'atende_facil.db');

    final backupFile = File(backupSelecionado);

    if (!await backupFile.exists()) {
      throw Exception('Arquivo de backup não encontrado');
    }

    await AppDatabase.instance.close();
    await backupFile.copy(dbPath);
  }

  static Future<void> excluirBaseLocal() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, 'atende_facil.db');

    await AppDatabase.instance.close();

    final dbFile = File(dbPath);

    if (await dbFile.exists()) {
      await deleteDatabase(dbPath);
    }
  }
}
