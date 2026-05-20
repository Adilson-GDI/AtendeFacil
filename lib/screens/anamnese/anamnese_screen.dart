import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/anamnese_database.dart';
import '../../database/app_database.dart';
import '../../models/anamnese_model.dart';
import '../../models/cliente_model.dart';
import '../../widgets/app_scaffold.dart';
import 'anamnese_form_screen.dart';

class AnamneseScreen extends StatefulWidget {
  const AnamneseScreen({super.key});

  @override
  State<AnamneseScreen> createState() => _AnamneseScreenState();
}

class _AnamneseScreenState extends State<AnamneseScreen> {
  bool loading = true;

  List<AnamneseModel> anamneses = [];
  Map<int, ClienteModel> clientesMap = {};

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    final listaAnamneses = await AnamneseDatabase.instance.listarAnamneses();
    final listaClientes = await AppDatabase.instance.listarClientes();

    final mapaClientes = {
      for (final cliente in listaClientes)
        if (cliente.id != null) cliente.id!: cliente,
    };

    if (!mounted) return;

    setState(() {
      anamneses = listaAnamneses;
      clientesMap = mapaClientes;
      loading = false;
    });
  }

  Future<void> abrirFormulario({AnamneseModel? anamnese}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnamneseFormScreen(anamnese: anamnese)),
    );

    if (result == true) {
      await carregarDados();
    }
  }

  Future<void> excluirAnamnese(AnamneseModel anamnese) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Excluir anamnese?'),
          content: const Text('Essa ação não poderá ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || anamnese.id == null) return;

    await AnamneseDatabase.instance.excluirAnamnese(anamnese.id!);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Anamnese excluída.')));

    await carregarDados();
  }

  String nomeCliente(AnamneseModel anamnese) {
    return clientesMap[anamnese.clienteId]?.nome ?? 'Cliente não encontrado';
  }

  String formatarData(String dataIso) {
    if (dataIso.isEmpty) return '-';

    try {
      final data = DateTime.parse(dataIso);
      return '${data.day.toString().padLeft(2, '0')}/'
          '${data.month.toString().padLeft(2, '0')}/'
          '${data.year}';
    } catch (_) {
      return dataIso;
    }
  }

  Widget emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_ind_rounded,
              size: 72,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma anamnese cadastrada',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cadastre a avaliação inicial do cliente para acompanhar objetivos, restrições e histórico.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => abrirFormulario(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova anamnese'),
            ),
          ],
        ),
      ),
    );
  }

  Widget anamneseCard(AnamneseModel anamnese) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEAF1FF),
          child: Icon(Icons.assignment_ind_rounded, color: AppColors.primary),
        ),
        title: Text(
          nomeCliente(anamnese),
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${formatarData(anamnese.dataAnamnese)}'
            '${anamnese.objetivo.isNotEmpty ? ' • ${anamnese.objetivo}' : ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'editar') {
              abrirFormulario(anamnese: anamnese);
            }

            if (value == 'excluir') {
              excluirAnamnese(anamnese);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'editar', child: Text('Editar')),
            PopupMenuItem(value: 'excluir', child: Text('Excluir')),
          ],
        ),
        onTap: () => abrirFormulario(anamnese: anamnese),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Anamnese',
      subtitle: 'Avaliação inicial do cliente',
      currentIndex: 0,
      showBack: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () => abrirFormulario(),
        child: const Icon(Icons.add_rounded),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : anamneses.isEmpty
          ? emptyState()
          : RefreshIndicator(
              onRefresh: carregarDados,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 90),
                itemCount: anamneses.length,
                itemBuilder: (_, index) {
                  return anamneseCard(anamneses[index]);
                },
              ),
            ),
    );
  }
}
