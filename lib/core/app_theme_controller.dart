import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/app_config_model.dart';

class AppThemeController extends ChangeNotifier {
  AppConfigModel? config;

  Color primary = const Color(0xFF1B5CB1);
  Color secondary = const Color(0xFFC9A46B);

  bool loading = true;

  Future<void> carregarTema() async {
    loading = true;
    notifyListeners();

    config = await AppDatabase.instance.buscarConfigApp();

    primary = hexToColor(config!.corPrimaria);
    secondary = hexToColor(config!.corSecundaria);

    loading = false;
    notifyListeners();
  }

  Future<void> atualizarTema() async {
    await carregarTema();
  }

  Color hexToColor(String hex) {
    final cleanHex = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleanHex', radix: 16));
  }

  ThemeData themeData() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
