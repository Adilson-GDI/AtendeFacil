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

  Widget totalClientesCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Lista de clientes',
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
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${clientes.length} cadastrados',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget clienteCard(ClienteModel cliente) {
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
        onTap: () => abrirFormulario(cliente: cliente),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          cliente.nome,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cliente.telefone.isNotEmpty)
                Text(
                  cliente.telefone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              if (cliente.instagram.isNotEmpty)
                Text(
                  '@${cliente.instagram}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
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
      ),
    );
  }

  Widget vazio() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        totalClientesCard(),
        const SizedBox(height: 80),
        const Center(
          child: Text(
            'Nenhum cliente cadastrado',
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
      title: 'Clientes',
      subtitle: 'Cadastros',
      currentIndex: 1,
      floatingActionButton: AppFab(onPressed: () => abrirFormulario()),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : clientes.isEmpty
          ? vazio()
          : RefreshIndicator(
              onRefresh: carregarClientes,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: clientes.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return totalClientesCard();
                  }

                  final cliente = clientes[index - 1];

                  return clienteCard(cliente);
                },
              ),
            ),
    );
  }
}
