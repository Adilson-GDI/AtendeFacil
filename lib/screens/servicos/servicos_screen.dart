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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Serviços',
      subtitle: 'Serviços e valores',
      currentIndex: 4,
      showBack: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => abrirFormulario(),
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : servicos.isEmpty
          ? const Center(
              child: Text(
                'Nenhum serviço cadastrado',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              itemCount: servicos.length,
              itemBuilder: (context, index) {
                final servico = servicos[index];

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
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.10),
                      child: const Icon(
                        Icons.build_circle_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      servico.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    subtitle: Text(dinheiro(servico.valorPadrao)),
                    trailing: PopupMenuButton<String>(
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
                    onTap: () => abrirFormulario(servico: servico),
                  ),
                );
              },
            ),
    );
  }
}
