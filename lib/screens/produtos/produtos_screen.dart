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

  Widget totalProdutosCard() {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Lista de produtos',
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
              '${produtos.length} cadastrados',
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

  Widget produtoCard(ProdutoModel produto) {
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
        onTap: () => abrirFormulario(produto: produto),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.inventory_2_rounded, size: 18, color: primary),
        ),
        title: Text(
          produto.nome,
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
            '${dinheiro(produto.precoVenda)} • Estoque: ${produto.estoqueAtual.toStringAsFixed(0)} ${produto.unidade}',
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
      ),
    );
  }

  Widget vazio() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        totalProdutosCard(),
        const SizedBox(height: 80),
        const Center(
          child: Text(
            'Nenhum produto cadastrado',
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
      title: 'Produtos',
      subtitle: 'Estoque e mercadorias',
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
          : produtos.isEmpty
          ? vazio()
          : RefreshIndicator(
              onRefresh: carregarProdutos,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: produtos.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return totalProdutosCard();
                  }

                  final produto = produtos[index - 1];

                  return produtoCard(produto);
                },
              ),
            ),
    );
  }
}
