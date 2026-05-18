import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/cliente_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_fab.dart';
import 'cliente_form_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<ClienteModel> clientes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    carregarClientes();
  }

  Future<void> carregarClientes() async {
    setState(() => loading = true);

    clientes = await AppDatabase.instance.listarClientes();

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> abrirFormulario({ClienteModel? cliente}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClienteFormScreen(cliente: cliente)),
    );

    carregarClientes();
  }

  Future<void> confirmarExclusao(ClienteModel cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir cliente'),
        content: Text('Deseja excluir ${cliente.nome}?'),
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

    if (confirmar == true && cliente.id != null) {
      await AppDatabase.instance.deletarCliente(cliente.id!);
      carregarClientes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Clientes',
      subtitle: 'Cadastros',
      currentIndex: 1,
      floatingActionButton: AppFab(onPressed: () => abrirFormulario()),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : clientes.isEmpty
          ? const Center(
              child: Text(
                'Nenhum cliente cadastrado',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final cliente = clientes[index];

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
                        Icons.person_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      cliente.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cliente.telefone.isNotEmpty) Text(cliente.telefone),
                        if (cliente.instagram.isNotEmpty)
                          Text('@${cliente.instagram}'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'editar') {
                          abrirFormulario(cliente: cliente);
                        }

                        if (value == 'excluir') {
                          confirmarExclusao(cliente);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'editar', child: Text('Editar')),
                        PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                      ],
                    ),
                    onTap: () => abrirFormulario(cliente: cliente),
                  ),
                );
              },
            ),
    );
  }
}
