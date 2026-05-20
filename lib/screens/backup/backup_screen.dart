import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/backup_service.dart';
import '../../widgets/app_scaffold.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  Widget _button({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final buttonColor = color ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: buttonColor.withOpacity(0.10),
          child: Icon(icon, color: buttonColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? AppColors.textDark,
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

  Future<void> _exportarBackup(BuildContext context) async {
    try {
      await BackupService.compartilharBackup();
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao exportar backup: $e')));
    }
  }

  Future<void> _restaurarBackup(BuildContext context) async {
    try {
      await BackupService.restaurarBackup();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup restaurado com sucesso. Reinicie o app.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao restaurar backup: $e')));
    }
  }

  Future<void> _excluirBase(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir base de dados?'),
        content: const Text(
          'Essa ação vai apagar todos os clientes, produtos, serviços, ordens, agenda, financeiro e configurações do aplicativo. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir tudo'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await BackupService.excluirBaseLocal();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Base excluída com sucesso. Reinicie o app.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao excluir base: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Backup',
      subtitle: 'Exportar, restaurar ou limpar dados',
      currentIndex: 4,
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _button(
            icon: Icons.upload_file_rounded,
            title: 'Exportar backup',
            subtitle: 'Salvar uma cópia dos dados do app',
            onTap: () => _exportarBackup(context),
          ),
          _button(
            icon: Icons.restore_rounded,
            title: 'Restaurar backup',
            subtitle: 'Importar dados salvos anteriormente',
            onTap: () => _restaurarBackup(context),
          ),
          _button(
            icon: Icons.delete_forever_rounded,
            title: 'Excluir base de dados',
            subtitle: 'Apagar todos os dados do aplicativo',
            color: AppColors.danger,
            onTap: () => _excluirBase(context),
          ),
        ],
      ),
    );
  }
}
