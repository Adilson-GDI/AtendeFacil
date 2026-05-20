import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme_controller.dart';
import '../../database/app_database.dart';
import '../../models/app_config_model.dart';
import '../../widgets/app_scaffold.dart';

class AparenciaScreen extends StatefulWidget {
  final bool primeiroAcesso;

  const AparenciaScreen({super.key, this.primeiroAcesso = false});

  @override
  State<AparenciaScreen> createState() => _AparenciaScreenState();
}

class _AparenciaScreenState extends State<AparenciaScreen> {
  final nomeController = TextEditingController();

  AppConfigModel? config;
  bool loading = true;
  bool salvando = false;

  String corPrimaria = '#1B5CB1';
  String corSecundaria = '#C9A46B';

  final List<String> coresPrimarias = [
    '#0F172A',
    '#111827',
    '#1E293B',
    '#334155',
    '#1B5CB1',
    '#123F7D',
    '#2563EB',
    '#1D4ED8',
    '#0E7490',
    '#155E75',
    '#0F766E',
    '#115E59',
    '#166534',
    '#365314',
    '#581C87',
    '#6D28D9',
    '#7C3AED',
    '#831843',
    '#9D174D',
    '#991B1B',
    '#7F1D1D',
    '#9A3412',
    '#78350F',
    '#3F3F46',
  ];

  final List<String> coresSecundarias = [
    '#C9A46B',
    '#D4AF37',
    '#B8860B',
    '#A16207',
    '#F59E0B',
    '#EAB308',
    '#FACC15',
    '#FDE68A',
    '#94A3B8',
    '#CBD5E1',
    '#E5E7EB',
    '#FFFFFF',
    '#38BDF8',
    '#60A5FA',
    '#818CF8',
    '#A78BFA',
    '#C084FC',
    '#F0ABFC',
    '#F472B6',
    '#FB7185',
    '#2DD4BF',
    '#34D399',
    '#86EFAC',
    '#111827',
  ];

  @override
  void initState() {
    super.initState();
    carregarConfig();
  }

  @override
  void dispose() {
    nomeController.dispose();
    super.dispose();
  }

  Future<void> carregarConfig() async {
    final result = await AppDatabase.instance.buscarConfigApp();

    config = result;
    nomeController.text = result.nomeEmpresa;
    corPrimaria = result.corPrimaria;
    corSecundaria = result.corSecundaria;

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Color hexToColor(String hex) {
    final cleanHex = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleanHex', radix: 16));
  }

  Future<void> salvar() async {
    if (config == null) return;

    setState(() => salvando = true);

    final novaConfig = config!.copyWith(
      nomeEmpresa: nomeController.text.trim().isEmpty
          ? 'Atende Fácil'
          : nomeController.text.trim(),
      corPrimaria: corPrimaria,
      corSecundaria: corSecundaria,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await AppDatabase.instance.salvarConfigApp(novaConfig);
    await context.read<AppThemeController>().atualizarTema();

    if (mounted) {
      setState(() => salvando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aparência salva com sucesso.')),
      );

      if (widget.primeiroAcesso) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    }
  }

  Widget colorOption({
    required String hex,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    final active = hex.toUpperCase() == selected.toUpperCase();
    final color = hexToColor(hex);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onSelect(hex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 48,
        height: 48,
        margin: const EdgeInsets.only(right: 9, bottom: 10),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? AppColors.textDark : Colors.white,
            width: active ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(hex == '#FFFFFF' ? 0.12 : 0.28),
              blurRadius: active ? 14 : 6,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: active
            ? Icon(
                Icons.check_rounded,
                color: hex == '#FFFFFF' || hex == '#FDE68A'
                    ? AppColors.textDark
                    : Colors.white,
                size: 23,
              )
            : null,
      ),
    );
  }

  Widget sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 18),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget previewCard() {
    final primary = hexToColor(corPrimaria);
    final secondary = hexToColor(corSecundaria);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.business_rounded, color: primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              nomeController.text.trim().isEmpty
                  ? 'Atende Fácil'
                  : nomeController.text.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: secondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: secondary == Colors.white ? AppColors.border : secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget nomeEmpresaInput() {
    return TextField(
      controller: nomeController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: 'Nome da empresa',
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.storefront_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget painelCores({
    required List<String> cores,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withOpacity(0.75)),
      ),
      child: Wrap(
        children: cores.map((hex) {
          return colorOption(hex: hex, selected: selected, onSelect: onSelect);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = hexToColor(corPrimaria);

    return AppScaffold(
      title: widget.primeiroAcesso ? 'Personalização' : 'Aparência',
      subtitle: widget.primeiroAcesso
          ? 'Escolha as cores do seu app'
          : 'Personalização do app',
      currentIndex: 4,
      showBack: !widget.primeiroAcesso,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                previewCard(),
                const SizedBox(height: 18),

                nomeEmpresaInput(),

                sectionTitle(
                  'Cor principal',
                  'Define cabeçalho, botões e destaques do app.',
                ),

                painelCores(
                  cores: coresPrimarias,
                  selected: corPrimaria,
                  onSelect: (value) {
                    setState(() => corPrimaria = value);
                  },
                ),

                sectionTitle(
                  'Cor secundária / filete',
                  'Use para detalhes, linhas e acabamento visual.',
                ),

                painelCores(
                  cores: coresSecundarias,
                  selected: corSecundaria,
                  onSelect: (value) {
                    setState(() => corSecundaria = value);
                  },
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: salvando ? null : salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: salvando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            widget.primeiroAcesso
                                ? 'Finalizar configuração'
                                : 'Salvar aparência',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
