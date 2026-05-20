import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/lembrete_database.dart';
import '../../models/lembrete_model.dart';
import '../../widgets/app_fab.dart';
import '../../widgets/app_scaffold.dart';
import 'lembrete_form_screen.dart';

class LembretesScreen extends StatefulWidget {
  const LembretesScreen({super.key});

  @override
  State<LembretesScreen> createState() => _LembretesScreenState();
}

class _LembretesScreenState extends State<LembretesScreen> {
  bool loading = true;
  List<LembreteModel> lembretes = [];

  @override
  void initState() {
    super.initState();
    carregarLembretes();
  }

  Future<void> carregarLembretes() async {
    setState(() => loading = true);

    lembretes = await LembreteDatabase.instance.listarLembretes();

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> abrirFormulario({LembreteModel? lembrete}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LembreteFormScreen(lembrete: lembrete)),
    );

    carregarLembretes();
  }

  Future<void> excluir(LembreteModel lembrete) async {
    if (lembrete.id == null) return;

    await LembreteDatabase.instance.deletarLembrete(lembrete.id!);

    carregarLembretes();
  }

  Future<void> concluir(LembreteModel lembrete) async {
    await LembreteDatabase.instance.concluirLembreteDoDia(lembrete);

    carregarLembretes();
  }

  Color corTipo(String tipo) {
    switch (tipo) {
      case 'FINANCEIRO':
        return AppColors.success;
      case 'FISCAL':
        return AppColors.warning;
      case 'CLIENTE':
        return Theme.of(context).colorScheme.primary;
      case 'AGENDA':
        return Theme.of(context).colorScheme.secondary;
      case 'BACKUP':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  String labelRecorrencia(String recorrencia) {
    switch (recorrencia) {
      case 'DIARIA':
        return 'Diário';
      case 'SEMANAL':
        return 'Semanal';
      case 'MENSAL':
        return 'Mensal';
      case 'ANUAL':
        return 'Anual';
      default:
        return 'Não repetir';
    }
  }

  Widget lembreteCard(LembreteModel item) {
    final cor = corTipo(item.tipo);

    return Dismissible(
      key: ValueKey(item.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await concluir(item);
          return false;
        }

        if (direction == DismissDirection.endToStart) {
          await excluir(item);
          return true;
        }

        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          onTap: () => abrirFormulario(lembrete: item),
          leading: CircleAvatar(
            backgroundColor: cor.withOpacity(0.12),
            child: Icon(Icons.notifications_active_rounded, color: cor),
          ),
          title: Text(
            item.titulo,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            '${item.dataInicio} ${item.hora.isEmpty ? '' : '• ${item.hora}'}\n'
            '${item.tipo} • ${labelRecorrencia(item.recorrencia)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'editar') abrirFormulario(lembrete: item);
              if (value == 'concluir') concluir(item);
              if (value == 'excluir') excluir(item);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(value: 'concluir', child: Text('Concluir')),
              PopupMenuItem(value: 'excluir', child: Text('Excluir')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Lembretes',
      subtitle: 'Tarefas e alertas',
      currentIndex: 0,
      showBack: true,
      floatingActionButton: AppFab(onPressed: () => abrirFormulario()),
      body: RefreshIndicator(
        onRefresh: carregarLembretes,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  if (lembretes.isEmpty)
                    const Text(
                      'Nenhum lembrete cadastrado',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    )
                  else
                    ...lembretes.map(lembreteCard),
                ],
              ),
      ),
    );
  }
}
