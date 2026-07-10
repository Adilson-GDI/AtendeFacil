import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/tipo_servico_app.dart';
import '../../database/app_database.dart';
import '../../models/app_remote_status_model.dart';
import '../../services/app_bootstrap_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    verificarFluxoInicial();
  }

  Future<void> verificarFluxoInicial() async {
    await Future.delayed(const Duration(milliseconds: 900));

    await AppDatabase.instance.atualizarTipoServicoApp(
      TipoServicoApp.personalTrainer,
    );

    final result = await AppBootstrapService.instance.iniciar();

    if (!mounted) return;

    if (result.precisaCadastro) {
      Navigator.pushReplacementNamed(context, '/cadastro-profissional');
      return;
    }

    if (result.status.bloqueado) {
      Navigator.pushReplacementNamed(
        context,
        '/app-bloqueado',
        arguments: result.status,
      );
      return;
    }

    if (result.status.noticeActive && result.status.noticeMessage.isNotEmpty) {
      await mostrarAviso(result.status);

      if (!mounted) return;
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> mostrarAviso(AppRemoteStatusModel status) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            status.noticeTitle.isEmpty ? 'Aviso' : status.noticeTitle,
          ),
          content: Text(status.noticeMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.fitness_center_rounded,
                size: 82,
                color: Colors.white,
              ),

              const SizedBox(height: 28),

              const Text(
                'FitCheck',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Carregando sua rotina local.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.90),
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 42),

              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),

              const SizedBox(height: 18),

              Text(
                'Preparando seu ambiente...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
