import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme_controller.dart';
import '../../database/app_database.dart';
import '../../models/app_config_model.dart';
import '../../widgets/app_scaffold.dart';

import 'package:provider/provider.dart';
import '../../core/app_theme_controller.dart';

class AparenciaScreen extends StatefulWidget {
  const AparenciaScreen({super.key});

  @override
  State<AparenciaScreen> createState() => _AparenciaScreenState();
}

class _AparenciaScreenState extends State<AparenciaScreen> {
  final nomeController = TextEditingController();
  final corPrimariaController = TextEditingController();
  final corSecundariaController = TextEditingController();

  AppConfigModel? config;
  bool loading = true;
  bool salvando = false;

  String corPrimaria = '#1B5CB1';
  String corSecundaria = '#C9A46B';

  final List<String> coresPrimarias = [
    '#1B5CB1',
    '#123F7D',
    '#2563EB',
    '#0891B2',
    '#0F766E',
    '#16A34A',
    '#7C3AED',
    '#9333EA',
    '#DB2777',
    '#BE123C',
    '#DC2626',
    '#EA580C',
    '#CA8A04',
    '#475569',
    '#111827',
    '#000000',
  ];

  final List<String> coresSecundarias = [
    '#C9A46B',
    '#F59E0B',
    '#FACC15',
    '#D97706',
    '#22C55E',
    '#2DD4BF',
    '#38BDF8',
    '#60A5FA',
    '#A78BFA',
    '#F472B6',
    '#FB7185',
    '#94A3B8',
    '#64748B',
    '#A3A3A3',
    '#FFFFFF',
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
    corPrimariaController.dispose();
    corSecundariaController.dispose();
    super.dispose();
  }

  Future<void> carregarConfig() async {
    final result = await AppDatabase.instance.buscarConfigApp();

    config = result;
    nomeController.text = result.nomeEmpresa;

    corPrimaria = result.corPrimaria;
    corSecundaria = result.corSecundaria;

    corPrimariaController.text = corPrimaria;
    corSecundariaController.text = corSecundaria;

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Color hexToColor(String hex) {
    final cleanHex = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleanHex', radix: 16));
  }

  bool hexValido(String value) {
    final regex = RegExp(r'^#([A-Fa-f0-9]{6})$');
    return regex.hasMatch(value.trim());
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
    }
  }

  Widget colorOption({
    required String hex,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    final active = hex == selected;
    final color = hexToColor(hex);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        onSelect(hex);

        if (selected == corPrimaria) {
          corPrimariaController.text = hex;
        }

        if (selected == corSecundaria) {
          corSecundariaController.text = hex;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 54,
        height: 54,
        margin: const EdgeInsets.only(right: 10, bottom: 10),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? AppColors.textDark : Colors.white,
            width: active ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.30),
              blurRadius: active ? 14 : 6,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: active
            ? Icon(
                Icons.check_rounded,
                color: hex == '#FFFFFF' ? AppColors.textDark : Colors.white,
                size: 26,
              )
            : null,
      ),
    );
  }

  Widget campoCorPersonalizada({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onApply,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: label,
                hintText: '#1B5CB1',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.color_lens_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                var value = controller.text.trim();

                if (!value.startsWith('#')) {
                  value = '#$value';
                }

                value = value.toUpperCase();

                if (!hexValido(value)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informe uma cor válida. Exemplo: #1B5CB1'),
                    ),
                  );
                  return;
                }

                controller.text = value;
                onApply(value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Aplicar',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 18),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 4,
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

  @override
  Widget build(BuildContext context) {
    final primary = hexToColor(corPrimaria);

    return AppScaffold(
      title: 'Aparência',
      subtitle: 'Personalização do app',
      currentIndex: 4,
      showBack: true,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                previewCard(),

                const SizedBox(height: 18),

                TextField(
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
                ),

                sectionTitle('Cor principal'),

                campoCorPersonalizada(
                  label: 'Cor principal personalizada',
                  controller: corPrimariaController,
                  onApply: (value) {
                    setState(() => corPrimaria = value);
                  },
                ),

                Wrap(
                  children: coresPrimarias.map((hex) {
                    return colorOption(
                      hex: hex,
                      selected: corPrimaria,
                      onSelect: (value) {
                        setState(() {
                          corPrimaria = value;
                          corPrimariaController.text = value;
                        });
                      },
                    );
                  }).toList(),
                ),

                sectionTitle('Cor secundária / filete'),

                campoCorPersonalizada(
                  label: 'Cor secundária personalizada',
                  controller: corSecundariaController,
                  onApply: (value) {
                    setState(() => corSecundaria = value);
                  },
                ),

                Wrap(
                  children: coresSecundarias.map((hex) {
                    return colorOption(
                      hex: hex,
                      selected: corSecundaria,
                      onSelect: (value) {
                        setState(() {
                          corSecundaria = value;
                          corSecundariaController.text = value;
                        });
                      },
                    );
                  }).toList(),
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
                        : const Text(
                            'Salvar aparência',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
