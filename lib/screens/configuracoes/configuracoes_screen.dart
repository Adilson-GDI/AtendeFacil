import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme_controller.dart';
import '../../widgets/app_scaffold.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

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
          backgroundColor: theme.primary.withOpacity(0.10),
          child: Icon(icon, color: theme.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: AppColors.navInactive,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mais',
      subtitle: 'Configurações',
      currentIndex: 4,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          _menuCard(
            context: context,
            icon: Icons.inventory_2_rounded,
            title: 'Produtos',
            subtitle: 'Cadastrar produtos e controlar estoque',
            onTap: () {
              Navigator.pushNamed(context, '/produtos');
            },
          ),
          _menuCard(
            context: context,
            icon: Icons.build_circle_rounded,
            title: 'Serviços',
            subtitle: 'Cadastrar serviços e valores padrão',
            onTap: () {
              Navigator.pushNamed(context, '/servicos');
            },
          ),

          _menuCard(
            context: context,
            icon: Icons.storefront_rounded,
            title: 'agenda',
            subtitle: '',
            onTap: () {
              Navigator.pushNamed(context, '/agenda');
            },
          ),

          _menuCard(
            context: context,
            icon: Icons.storefront_rounded,
            title: 'Dados da empresa',
            subtitle: 'Nome, telefone, WhatsApp e endereço',
            onTap: () {
              Navigator.pushNamed(context, '/empresa');
            },
          ),
          _menuCard(
            context: context,
            icon: Icons.palette_rounded,
            title: 'Aparência do app',
            subtitle: 'Alterar cores e identidade visual',
            onTap: () {
              Navigator.pushNamed(context, '/aparencia');
            },
          ),
          _menuCard(
            context: context,
            icon: Icons.chat_rounded,
            title: 'Mensagens WhatsApp',
            subtitle: 'Resumo da OS e mensagem de cobrança',
            onTap: () {
              Navigator.pushNamed(context, '/mensagens-whatsapp');
            },
          ),
          _menuCard(
            context: context,
            icon: Icons.backup_rounded,
            title: 'Backup',
            subtitle: 'Exportar ou restaurar dados do aplicativo',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
