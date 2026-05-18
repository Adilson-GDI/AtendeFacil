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
          ? const Center(
              child: Text(
                'Nenhuma ordem cadastrada',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              itemCount: ordens.length,
              itemBuilder: (context, index) {
                final ordem = ordens[index];
                final statusColor = corStatus(ordem.status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.12),
                      child: Icon(Icons.assignment_rounded, color: statusColor),
                    ),
                    title: Text(
                      ordem.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dinheiro(ordem.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              labelStatus(ordem.status),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
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
                    onTap: () => abrirFormulario(ordem: ordem),
                  ),
                );
              },
            ),
    );
  }
}
