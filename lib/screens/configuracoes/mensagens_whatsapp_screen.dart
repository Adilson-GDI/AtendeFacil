import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/app_config_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_button.dart';

class MensagensWhatsappScreen extends StatefulWidget {
  const MensagensWhatsappScreen({super.key});

  @override
  State<MensagensWhatsappScreen> createState() =>
      _MensagensWhatsappScreenState();
}

class _MensagensWhatsappScreenState extends State<MensagensWhatsappScreen> {
  final resumoController = TextEditingController();
  final cobrancaController = TextEditingController();

  AppConfigModel? config;
  bool loading = true;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  @override
  void dispose() {
    resumoController.dispose();
    cobrancaController.dispose();
    super.dispose();
  }

  Future<void> carregar() async {
    config = await AppDatabase.instance.buscarConfigApp();

    resumoController.text = config!.mensagemResumoOs;
    cobrancaController.text = config!.mensagemCobranca;

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> salvar() async {
    if (config == null) return;

    setState(() => salvando = true);

    final novaConfig = config!.copyWith(
      mensagemResumoOs: resumoController.text.trim(),
      mensagemCobranca: cobrancaController.text.trim(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    await AppDatabase.instance.salvarConfigApp(novaConfig);

    if (mounted) {
      setState(() => salvando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensagens salvas com sucesso.')),
      );
    }
  }

  Widget helpBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
      ),
      child: const Text(
        'Variáveis disponíveis:\n'
        '{cliente}, {numero_os}, {titulo_os}, {resumo_os}, {total}, {valor_pendente}, {empresa}',
        style: TextStyle(
          color: AppColors.textDark,
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget textarea({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        minLines: 7,
        maxLines: 12,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 120),
            child: Icon(icon, color: AppColors.navInactive),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'WhatsApp',
      subtitle: 'Mensagens automáticas',
      currentIndex: 4,
      showBack: true,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                helpBox(),
                const SizedBox(height: 18),
                textarea(
                  controller: resumoController,
                  label: 'Mensagem de resumo da OS',
                  icon: Icons.receipt_long_rounded,
                ),
                textarea(
                  controller: cobrancaController,
                  label: 'Mensagem de cobrança',
                  icon: Icons.payments_rounded,
                ),
                AppButton(
                  label: 'Salvar ',
                  loading: salvando,
                  onPressed: salvar,
                ),
              ],
            ),
    );
  }
}
