import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme_controller.dart';

import 'screens/home/home_screen.dart';
import 'screens/clientes/clientes_screen.dart';
import 'screens/ordens/ordens_screen.dart';
import 'screens/financeiro/financeiro_screen.dart';
import 'screens/configuracoes/configuracoes_screen.dart';
import 'screens/configuracoes/aparencia_screen.dart';
import 'screens/produtos/produtos_screen.dart';
import 'screens/servicos/servicos_screen.dart';

import 'screens/configuracoes/empresa_screen.dart';
import 'screens/configuracoes/mensagens_whatsapp_screen.dart';

import 'screens/agenda/agenda_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeController = AppThemeController();
  await themeController.carregarTema();

  runApp(
    ChangeNotifierProvider.value(
      value: themeController,
      child: const AtendeFacilApp(),
    ),
  );
}

class AtendeFacilApp extends StatelessWidget {
  const AtendeFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<AppThemeController>();

    return MaterialApp(
      title: 'Atende Fácil',
      debugShowCheckedModeBanner: false,
      theme: themeController.themeData(),
      initialRoute: '/home',
      routes: {
        '/home': (_) => const HomeScreen(),
        '/clientes': (_) => const ClientesScreen(),
        '/ordens': (_) => const OrdensScreen(),
        '/financeiro': (_) => const FinanceiroScreen(),
        '/configuracoes': (_) => const ConfiguracoesScreen(),
        '/aparencia': (_) => const AparenciaScreen(),
        '/produtos': (_) => const ProdutosScreen(),
        '/servicos': (_) => const ServicosScreen(),
        '/empresa': (_) => const EmpresaScreen(),
        '/mensagens-whatsapp': (_) => const MensagensWhatsappScreen(),
        '/agenda': (_) => const AgendaScreen(),
      },
    );
  }
}
