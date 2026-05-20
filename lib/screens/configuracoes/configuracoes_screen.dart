import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme_controller.dart';
import '../../core/tipo_servico_app.dart';
import '../../database/app_database.dart';
import '../../widgets/app_scaffold.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  bool loading = true;
  String tipoServico = TipoServicoApp.geral;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    final tipo = await AppDatabase.instance.buscarTipoServicoApp();

    if (mounted) {
      setState(() {
        tipoServico = tipo;
        loading = false;
      });
    }
  }

  String labelTipoServico(String tipo) {
    switch (tipo) {
      case TipoServicoApp.fisioterapeuta:
        return 'Fisioterapeuta';
      case TipoServicoApp.personalTrainer:
        return 'Personal trainer';
      case TipoServicoApp.estetica:
        return 'Estética';
      case TipoServicoApp.manutencao:
        return 'Manutenção técnica';
      case TipoServicoApp.barbearia:
        return 'Barbearia / Salão';
      case TipoServicoApp.consultoria:
        return 'Consultoria';
      case TipoServicoApp.outro:
        return 'Outro';
      default:
        return 'Prestador geral';
    }
  }

  IconData iconTipoServico(String tipo) {
    switch (tipo) {
      case TipoServicoApp.fisioterapeuta:
        return Icons.healing_rounded;
      case TipoServicoApp.personalTrainer:
        return Icons.fitness_center_rounded;
      case TipoServicoApp.estetica:
        return Icons.spa_rounded;
      case TipoServicoApp.manutencao:
        return Icons.build_rounded;
      case TipoServicoApp.barbearia:
        return Icons.content_cut_rounded;
      case TipoServicoApp.consultoria:
        return Icons.business_center_rounded;
      case TipoServicoApp.outro:
        return Icons.more_horiz_rounded;
      default:
        return Icons.work_outline_rounded;
    }
  }

  Future<void> selecionarTipoServico(BuildContext context) async {
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

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        final theme = context.watch<AppThemeController>();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tipo de serviço do app',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Escolha o tipo de negócio para liberar recursos específicos no app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ...opcoes.map((item) {
                  final value = item['value'] as String;
                  final label = item['label'] as String;
                  final icon = item['icon'] as IconData;
                  final selecionado = value == tipoServico;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: selecionado
                          ? theme.primary.withOpacity(0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selecionado
                            ? theme.primary.withOpacity(0.35)
                            : AppColors.border,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.primary.withOpacity(0.10),
                        child: Icon(icon, color: theme.primary, size: 20),
                      ),
                      title: Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      trailing: selecionado
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: theme.primary,
                            )
                          : const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AppColors.navInactive,
                            ),
                      onTap: () async {
                        await AppDatabase.instance.atualizarTipoServicoApp(
                          value,
                        );

                        if (mounted) {
                          setState(() {
                            tipoServico = value;
                          });
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = context.watch<AppThemeController>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
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
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 15,
          color: AppColors.navInactive,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Configurações',
      subtitle: 'Ajustes do aplicativo',
      currentIndex: 4,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                _sectionTitle('Negócio'),

                _menuCard(
                  context: context,
                  icon: iconTipoServico(tipoServico),
                  title: 'Tipo de serviço',
                  subtitle: labelTipoServico(tipoServico),
                  onTap: () async {
                    await selecionarTipoServico(context);
                    await carregarDados();
                  },
                ),

                _menuCard(
                  context: context,
                  icon: Icons.storefront_rounded,
                  title: 'Dados da empresa',
                  subtitle: 'Nome, telefone, documento e redes sociais',
                  onTap: () {
                    Navigator.pushNamed(context, '/empresa');
                  },
                ),

                _menuCard(
                  context: context,
                  icon: Icons.chat_rounded,
                  title: 'Mensagens WhatsApp',
                  subtitle: 'Textos automáticos para atendimento',
                  onTap: () {
                    Navigator.pushNamed(context, '/mensagens-whatsapp');
                  },
                ),

                _sectionTitle('Cadastros'),

                _menuCard(
                  context: context,
                  icon: Icons.people_alt_rounded,
                  title: 'Clientes',
                  subtitle: 'Gerenciar clientes cadastrados',
                  onTap: () {
                    Navigator.pushNamed(context, '/clientes');
                  },
                ),

                _menuCard(
                  context: context,
                  icon: Icons.design_services_rounded,
                  title: 'Serviços',
                  subtitle: 'Cadastrar e editar serviços prestados',
                  onTap: () {
                    Navigator.pushNamed(context, '/servicos');
                  },
                ),

                _menuCard(
                  context: context,
                  icon: Icons.inventory_2_rounded,
                  title: 'Produtos',
                  subtitle: 'Estoque e produtos utilizados',
                  onTap: () {
                    Navigator.pushNamed(context, '/produtos');
                  },
                ),

                _sectionTitle('Operação'),

                _menuCard(
                  context: context,
                  icon: Icons.calendar_month_rounded,
                  title: 'Agenda',
                  subtitle: 'Atendimentos e compromissos',
                  onTap: () {
                    Navigator.pushNamed(context, '/agenda');
                  },
                ),

                _menuCard(
                  context: context,
                  icon: Icons.notifications_active_rounded,
                  title: 'Lembretes',
                  subtitle: 'Tarefas, alertas e recorrências',
                  onTap: () {
                    Navigator.pushNamed(context, '/lembretes');
                  },
                ),

                _menuCard(
                  context: context,
                  icon: Icons.assignment_rounded,
                  title: 'Ordens de serviço',
                  subtitle: 'Orçamentos, serviços e acompanhamento',
                  onTap: () {
                    Navigator.pushNamed(context, '/ordens');
                  },
                ),

                _menuCard(
                  context: context,
                  icon: Icons.payments_rounded,
                  title: 'Financeiro',
                  subtitle: 'Recebimentos, pendências e pagamentos',
                  onTap: () {
                    Navigator.pushNamed(context, '/financeiro');
                  },
                ),

                if (tipoServico == TipoServicoApp.personalTrainer ||
                    tipoServico == TipoServicoApp.fisioterapeuta)
                  _menuCard(
                    context: context,
                    icon: Icons.fitness_center_rounded,
                    title: 'Treinos',
                    subtitle: 'Fichas de treino, exercícios e evolução',
                    onTap: () {
                      Navigator.pushNamed(context, '/treinos');
                    },
                  ),

                if (tipoServico == TipoServicoApp.personalTrainer ||
                    tipoServico == TipoServicoApp.fisioterapeuta)
                  _menuCard(
                    context: context,
                    icon: Icons.sports_gymnastics_rounded,
                    title: 'Exercícios',
                    subtitle: 'Biblioteca de exercícios e grupos musculares',
                    onTap: () {
                      Navigator.pushNamed(context, '/exercicios');
                    },
                  ),

                _sectionTitle('Aplicativo'),

                _menuCard(
                  context: context,
                  icon: Icons.palette_rounded,
                  title: 'Aparência',
                  subtitle: 'Cores e visual do aplicativo',
                  onTap: () {
                    Navigator.pushNamed(context, '/aparencia');
                  },
                ),

                _menuCard(
                  context: context,
                  icon: Icons.backup_rounded,
                  title: 'Backup',
                  subtitle: 'Exportar ou restaurar dados do app',
                  onTap: () {
                    Navigator.pushNamed(context, '/backup');
                  },
                ),

                _menuCard(
                  context: context,
                  icon: Icons.info_outline_rounded,
                  title: 'Sobre o app',
                  subtitle: 'Versão e informações do sistema',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Atende Fácil',
                      applicationVersion: '1.0.0',
                      applicationLegalese: 'Gestão para prestadores de serviço',
                    );
                  },
                ),
              ],
            ),
    );
  }
}
