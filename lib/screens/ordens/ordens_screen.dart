import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/ordem_servico_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_fab.dart';
import 'ordem_form_screen.dart';

class OrdensScreen extends StatefulWidget {
  const OrdensScreen({super.key});

  @override
  State<OrdensScreen> createState() => _OrdensScreenState();
}

class _OrdensScreenState extends State<OrdensScreen> {
  List<OrdemServicoModel> ordens = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    carregarOrdens();
  }

  Future<void> carregarOrdens() async {
    setState(() => loading = true);

    ordens = await AppDatabase.instance.listarOrdensServico();

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> abrirFormulario({OrdemServicoModel? ordem}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrdemFormScreen(ordem: ordem)),
    );

    carregarOrdens();
  }

  Future<void> confirmarExclusao(OrdemServicoModel ordem) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir ordem'),
        content: Text('Deseja excluir "${ordem.titulo}"?'),
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

    if (confirmar == true && ordem.id != null) {
      await AppDatabase.instance.deletarOrdemServico(ordem.id!);
      carregarOrdens();
    }
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Color corStatus(String status) {
    switch (status) {
      case 'PAGO':
        return AppColors.success;
      case 'CONCLUIDO':
        return AppColors.primary;
      case 'AGUARDANDO_PAGAMENTO':
        return AppColors.warning;
      case 'CANCELADO':
        return AppColors.danger;
      default:
        return AppColors.gold;
    }
  }

  String labelStatus(String status) {
    switch (status) {
      case 'ORCAMENTO':
        return 'Orçamento';
      case 'APROVADO':
        return 'Aprovado';
      case 'EM_ANDAMENTO':
        return 'Em andamento';
      case 'CONCLUIDO':
        return 'Concluído';
      case 'AGUARDANDO_PAGAMENTO':
        return 'Aguardando pagamento';
      case 'PAGO':
        return 'Pago';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Widget totalOrdensCard() {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Lista de ordens',
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
              '${ordens.length} cadastradas',
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

  Widget ordemCard(OrdemServicoModel ordem) {
    final statusColor = corStatus(ordem.status);

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
        onTap: () => abrirFormulario(ordem: ordem),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.assignment_rounded, size: 18, color: statusColor),
        ),
        title: Text(
          ordem.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Wrap(
            spacing: 8,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                dinheiro(ordem.total),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  labelStatus(ordem.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
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
              abrirFormulario(ordem: ordem);
            }

            if (value == 'excluir') {
              confirmarExclusao(ordem);
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
        totalOrdensCard(),
        const SizedBox(height: 80),
        const Center(
          child: Text(
            'Nenhuma ordem cadastrada',
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
    return AppScaffold(
      title: 'Ordens',
      subtitle: 'Serviços realizados',
      currentIndex: 2,
      floatingActionButton: AppFab(onPressed: () => abrirFormulario()),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ordens.isEmpty
          ? vazio()
          : RefreshIndicator(
              onRefresh: carregarOrdens,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: ordens.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return totalOrdensCard();
                  }

                  final ordem = ordens[index - 1];

                  return ordemCard(ordem);
                },
              ),
            ),
    );
  }
}
