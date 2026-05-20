import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme_controller.dart';
import '../../core/tipo_servico_app.dart';
import '../../database/app_database.dart';
import '../../services/push_service.dart';

class TipoServicoInicialScreen extends StatelessWidget {
  const TipoServicoInicialScreen({super.key});

  Future<void> salvarTipo(BuildContext context, String tipo) async {
    await AppDatabase.instance.atualizarTipoServicoApp(tipo);

    // Atualiza o token no servidor com o tipo_servico correto
    await PushService.registrarToken();

    if (!context.mounted) return;

    Navigator.pushReplacementNamed(context, '/aparencia-inicial');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppThemeController>();

    final opcoes = [
      {
        'value': TipoServicoApp.geral,
        'label': 'Prestador geral',
        'icon': Icons.work_outline_rounded,
      },
      {
        'value': TipoServicoApp.fisioterapeuta,
        'label': 'Fisioterapeuta',
        'icon': Icons.healing_rounded,
      },
      {
        'value': TipoServicoApp.personalTrainer,
        'label': 'Personal trainer',
        'icon': Icons.fitness_center_rounded,
      },
      {
        'value': TipoServicoApp.estetica,
        'label': 'Estética',
        'icon': Icons.spa_rounded,
      },
      {
        'value': TipoServicoApp.manutencao,
        'label': 'Manutenção técnica',
        'icon': Icons.build_rounded,
      },
      {
        'value': TipoServicoApp.barbearia,
        'label': 'Barbearia / Salão',
        'icon': Icons.content_cut_rounded,
      },
      {
        'value': TipoServicoApp.consultoria,
        'label': 'Consultoria',
        'icon': Icons.business_center_rounded,
      },
      {
        'value': TipoServicoApp.outro,
        'label': 'Outro',
        'icon': Icons.more_horiz_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          children: [
            Icon(Icons.apps_rounded, size: 58, color: theme.primary),

            const SizedBox(height: 18),

            const Text(
              'Qual é o seu tipo de serviço?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Escolha uma opção para personalizar os recursos do aplicativo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            ...opcoes.map((item) {
              final value = item['value'] as String;
              final label = item['label'] as String;
              final icon = item['icon'] as IconData;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: theme.primary.withOpacity(0.10),
                    child: Icon(icon, color: theme.primary),
                  ),
                  title: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: AppColors.navInactive,
                  ),
                  onTap: () => salvarTipo(context, value),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
