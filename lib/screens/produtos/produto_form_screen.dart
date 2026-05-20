import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/produto_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_button.dart';
import '../../core/money_utils.dart';

class ProdutoFormScreen extends StatefulWidget {
  final ProdutoModel? produto;

  const ProdutoFormScreen({super.key, this.produto});

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final precoCustoController = TextEditingController();
  final precoVendaController = TextEditingController();
  final estoqueController = TextEditingController();

  String unidade = 'UN';
  bool ativo = true;
  bool salvando = false;

  bool get editando => widget.produto != null;

  @override
  void initState() {
    super.initState();

    if (editando) {
      nomeController.text = widget.produto!.nome;
      descricaoController.text = widget.produto!.descricao;
      precoVendaController.text = MoneyUtils.format(widget.produto!.precoVenda);
      precoCustoController.text = MoneyUtils.format(widget.produto!.precoCusto);
      estoqueController.text = widget.produto!.estoqueAtual.toStringAsFixed(0);
      unidade = widget.produto!.unidade;
      ativo = widget.produto!.ativo == 1;
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    precoCustoController.dispose();
    precoVendaController.dispose();
    estoqueController.dispose();
    super.dispose();
  }

  double _parseValor(String value) {
    return MoneyUtils.parse(value);
  }

  Future<void> salvar() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => salvando = true);

    final agora = DateTime.now().toIso8601String();

    final produto = ProdutoModel(
      id: widget.produto?.id,
      nome: nomeController.text.trim(),
      descricao: descricaoController.text.trim(),
      precoCusto: _parseValor(precoCustoController.text),
      precoVenda: _parseValor(precoVendaController.text),
      estoqueAtual: _parseValor(estoqueController.text),
      unidade: unidade,
      ativo: ativo ? 1 : 0,
      createdAt: widget.produto?.createdAt ?? agora,
      updatedAt: editando ? agora : null,
    );

    if (editando) {
      await AppDatabase.instance.atualizarProduto(produto);
    } else {
      await AppDatabase.instance.criarProduto(produto);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.navInactive),
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: editando ? 'Editar produto' : 'Novo produto',
      subtitle: editando ? 'Atualizar cadastro' : 'Cadastrar mercadoria',
      currentIndex: 4,
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
        child: Form(
          key: formKey,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                _input(
                  controller: nomeController,
                  label: 'Nome do produto',
                  icon: Icons.inventory_2_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome do produto';
                    }
                    return null;
                  },
                ),
                _input(
                  controller: descricaoController,
                  label: 'Descrição',
                  icon: Icons.description_rounded,
                ),
                _input(
                  controller: precoCustoController,
                  label: 'Preço de custo',
                  icon: Icons.money_off_csred_rounded,
                  keyboardType: TextInputType.number,
                ),
                _input(
                  controller: precoVendaController,
                  label: 'Preço de venda',
                  icon: Icons.sell_rounded,
                  keyboardType: TextInputType.number,
                ),
                _input(
                  controller: estoqueController,
                  label: 'Estoque atual',
                  icon: Icons.warehouse_rounded,
                  keyboardType: TextInputType.number,
                ),

                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: unidade,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Unidade',
                      prefixIcon: Icon(
                        Icons.straighten_rounded,
                        color: AppColors.navInactive,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'UN', child: Text('Unidade')),
                      DropdownMenuItem(value: 'KG', child: Text('Quilo')),
                      DropdownMenuItem(value: 'LT', child: Text('Litro')),
                      DropdownMenuItem(value: 'M', child: Text('Metro')),
                      DropdownMenuItem(value: 'CX', child: Text('Caixa')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => unidade = value);
                      }
                    },
                  ),
                ),

                SwitchListTile(
                  value: ativo,
                  activeColor: AppColors.primary,
                  title: const Text(
                    'Produto ativo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Produto disponível para usar na OS'),
                  onChanged: (value) {
                    setState(() => ativo = value);
                  },
                ),

                const SizedBox(height: 12),
                AppButton(
                  label: 'Salvar',
                  loading: salvando,
                  onPressed: salvar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
