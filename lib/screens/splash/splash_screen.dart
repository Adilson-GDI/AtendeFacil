import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';

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
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Buscar no banco/configuração se já escolheu o tipo de serviço
    final tipoServico = await AppDatabase.instance.buscarTipoServicoApp();

    if (!mounted) return;

    if (tipoServico.isEmpty) {
      Navigator.pushReplacementNamed(context, '/tipo-servico-inicial');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
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
              const Icon(Icons.handyman_rounded, size: 82, color: Colors.white),

              const SizedBox(height: 28),

              const Text(
                'Atende Fácil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Organize clientes, agenda, serviços, treinos, financeiro '
                'e atendimentos em um só lugar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.90),
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
                  color: Colors.white.withOpacity(0.85),
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
