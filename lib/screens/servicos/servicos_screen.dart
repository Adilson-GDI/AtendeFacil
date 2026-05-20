import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/servico_model.dart';
import '../../widgets/app_scaffold.dart';
import 'servico_form_screen.dart';

class ServicosScreen extends StatefulWidget {
  const ServicosScreen({super.key});

  @override
  State<ServicosScreen> createState() => _ServicosScreenState();
}

class _ServicosScreenState extends State<ServicosScreen> {
  List<ServicoModel> servicos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    carregarServicos();
  }

  Future<void> carregarServicos() async {
    setState(() => loading = true);

    servicos = await AppDatabase.instance.listarServicos();

    if (mounted) {
      setState(() => loading = false);
    }
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> abrirFormulario({ServicoModel? servico}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ServicoFormScreen(servico: servico)),
    );

    carregarServicos();
  }

  Future<void> confirmarExclusao(ServicoModel servico) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir serviço'),
        content: Text('Deseja excluir ${servico.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && servico.id != null) {
      await AppDatabase.instance.deletarServico(servico.id!);
      carregarServicos();
    }
  }

  Widget totalServicosCard() {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Lista de serviços',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${servicos.length} cadastrados',
              style: TextStyle(
                color: primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget servicoCard(ServicoModel servico) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => abrirFormulario(servico: servico),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.build_circle_rounded, size: 18, color: primary),
        ),
        title: Text(
          servico.nome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            dinheiro(servico.valorPadrao),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert_rounded,
            size: 22,
            color: AppColors.textMuted,
          ),
          onSelected: (value) {
            if (value == 'editar') {
              abrirFormulario(servico: servico);
            }

            if (value == 'excluir') {
              confirmarExclusao(servico);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'editar', child: Text('Editar')),
            PopupMenuItem(value: 'excluir', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }

  Widget vazio() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        totalServicosCard(),
        const SizedBox(height: 80),
        const Center(
          child: Text(
            'Nenhum serviço cadastrado',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AppScaffold(
      title: 'Serviços',
      subtitle: 'Serviços e valores',
      currentIndex: 4,
      showBack: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => abrirFormulario(),
        child: const Icon(Icons.add_rounded),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : servicos.isEmpty
          ? vazio()
          : RefreshIndicator(
              onRefresh: carregarServicos,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: servicos.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return totalServicosCard();
                  }

                  final servico = servicos[index - 1];

                  return servicoCard(servico);
                },
              ),
            ),
    );
  }
}
