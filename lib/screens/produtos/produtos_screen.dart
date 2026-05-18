import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/produto_model.dart';
import '../../widgets/app_scaffold.dart';
import 'produto_form_screen.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  List<ProdutoModel> produtos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    carregarProdutos();
  }

  Future<void> carregarProdutos() async {
    setState(() => loading = true);
    produtos = await AppDatabase.instance.listarProdutos();

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> abrirFormulario({ProdutoModel? produto}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProdutoFormScreen(produto: produto)),
    );

    carregarProdutos();
  }

  Future<void> confirmarExclusao(ProdutoModel produto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir produto'),
        content: Text('Deseja excluir ${produto.nome}?'),
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

    if (confirmar == true && produto.id != null) {
      await AppDatabase.instance.deletarProduto(produto.id!);
      carregarProdutos();
    }
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Produtos',
      subtitle: 'Estoque e mercadorias',
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
          : produtos.isEmpty
          ? const Center(
              child: Text(
                'Nenhum produto cadastrado',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              itemCount: produtos.length,
              itemBuilder: (context, index) {
                final produto = produtos[index];

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
                        Icons.inventory_2_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      produto.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${dinheiro(produto.precoVenda)} • Estoque: ${produto.estoqueAtual.toStringAsFixed(0)} ${produto.unidade}',
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'editar') {
                          abrirFormulario(produto: produto);
                        }

                        if (value == 'excluir') {
                          confirmarExclusao(produto);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'editar', child: Text('Editar')),
                        PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                      ],
                    ),
                    onTap: () => abrirFormulario(produto: produto),
                  ),
                );
              },
            ),
    );
  }
}
