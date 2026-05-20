import 'package:flutter/material.dart';

import '../database/lembrete_database.dart';
import '../models/lembrete_model.dart';
import 'app_header.dart';
import 'app_bottom_nav.dart';

class AppScaffold extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget body;
  final int currentIndex;
  final bool showBack;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.currentIndex,
    this.showBack = false,
    this.floatingActionButton,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int totalLembretesHoje = 0;

  @override
  void initState() {
    super.initState();
    carregarLembretesHoje();
  }

  String dataSql(DateTime data) {
    return '${data.year.toString().padLeft(4, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }

  bool lembreteEhHoje(LembreteModel item) {
    final hoje = DateTime.now();
    final hojeSql = dataSql(hoje);
    if (item.ultimaExecucao == hojeSql) return false;

    if (item.ativo != 1 || item.concluido == 1) return false;

    if (item.recorrencia == 'NENHUMA') {
      return item.dataInicio == hojeSql;
    }

    DateTime dataInicio;

    try {
      dataInicio = DateTime.parse(item.dataInicio);
    } catch (_) {
      return false;
    }

    if (hoje.isBefore(
      DateTime(dataInicio.year, dataInicio.month, dataInicio.day),
    )) {
      return false;
    }

    switch (item.recorrencia) {
      case 'DIARIA':
        return true;
      case 'SEMANAL':
        return hoje.weekday == dataInicio.weekday;
      case 'MENSAL':
        return hoje.day == dataInicio.day;
      case 'ANUAL':
        return hoje.day == dataInicio.day && hoje.month == dataInicio.month;
      default:
        return false;
    }
  }

  Future<void> carregarLembretesHoje() async {
    final lembretes = await LembreteDatabase.instance.listarLembretesAtivos();

    if (!mounted) return;

    setState(() {
      totalLembretesHoje = lembretes.where(lembreteEhHoje).length;
    });
  }

  void _navigate(BuildContext context, int index) {
    if (index == widget.currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(context, '/agenda', (route) => false);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/clientes',
          (route) => false,
        );
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(context, '/ordens', (route) => false);
        break;
      case 4:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/configuracoes',
          (route) => false,
        );
        break;
    }
  }

  void _back(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  Widget sinoLembretes() {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () async {
        await Navigator.pushNamed(context, '/lembretes');
        carregarLembretesHoje();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          if (totalLembretesHoje > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  totalLembretesHoje > 9 ? '9+' : '$totalLembretesHoje',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.floatingActionButton,
      body: Column(
        children: [
          AppHeader(
            title: widget.title,
            subtitle: widget.subtitle,
            showBack: widget.showBack,
            menuActive: widget.currentIndex == 4,
            onBack: () => _back(context),
            onMenu: () {
              if (widget.currentIndex != 4) {
                Navigator.pushNamed(context, '/configuracoes');
              }
            },
            rightWidget: sinoLembretes(),
          ),
          Expanded(child: widget.body),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: widget.currentIndex,
        onTap: (index) => _navigate(context, index),
      ),
    );
  }
}
