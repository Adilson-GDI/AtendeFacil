import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/servico_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_button.dart';
import '../../core/money_utils.dart';

class ServicoFormScreen extends StatefulWidget {
  final ServicoModel? servico;

  const ServicoFormScreen({super.key, this.servico});

  @override
  State<ServicoFormScreen> createState() => _ServicoFormScreenState();
}

class _ServicoFormScreenState extends State<ServicoFormScreen> {
  final formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final valorController = TextEditingController();

  bool ativo = true;
  bool salvando = false;

  bool get editando => widget.servico != null;

  @override
  void initState() {
    super.initState();

    if (editando) {
      nomeController.text = widget.servico!.nome;
      descricaoController.text = widget.servico!.descricao;
      valorController.text = MoneyUtils.format(widget.servico!.valorPadrao);
      ativo = widget.servico!.ativo == 1;
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    valorController.dispose();
    super.dispose();
  }

  double _parseValor(String value) {
    return MoneyUtils.parse(value);
  }

  Future<void> salvar() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => salvando = true);

    final agora = DateTime.now().toIso8601String();

    final servico = ServicoModel(
      id: widget.servico?.id,
      nome: nomeController.text.trim(),
      descricao: descricaoController.text.trim(),
      valorPadrao: _parseValor(valorController.text),
      ativo: ativo ? 1 : 0,
      createdAt: widget.servico?.createdAt ?? agora,
      updatedAt: editando ? agora : null,
    );

    if (editando) {
      await AppDatabase.instance.atualizarServico(servico);
    } else {
      await AppDatabase.instance.criarServico(servico);
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
      title: editando ? 'Editar serviço' : 'Novo serviço',
      subtitle: editando ? 'Atualizar cadastro' : 'Cadastrar serviço',
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
                  label: 'Nome do serviço',
                  icon: Icons.build_circle_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome do serviço';
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
                  controller: valorController,
                  label: 'Valor padrão',
                  icon: Icons.sell_rounded,
                  keyboardType: TextInputType.number,
                ),

                SwitchListTile(
                  value: ativo,
                  activeColor: AppColors.primary,
                  title: const Text(
                    'Serviço ativo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Disponível para usar na ordem de serviço',
                  ),
                  onChanged: (value) {
                    setState(() => ativo = value);
                  },
                ),

                const SizedBox(height: 12),

                AppButton(
                  label: 'Salvar ',
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
