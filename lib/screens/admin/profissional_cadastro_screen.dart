import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/app_bootstrap_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';

class ProfissionalCadastroScreen extends StatefulWidget {
  const ProfissionalCadastroScreen({super.key});

  @override
  State<ProfissionalCadastroScreen> createState() =>
      _ProfissionalCadastroScreenState();
}

class _ProfissionalCadastroScreenState
    extends State<ProfissionalCadastroScreen> {
  final formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final telefoneController = TextEditingController();

  bool salvando = false;

  @override
  void dispose() {
    nomeController.dispose();
    telefoneController.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => salvando = true);

    final result = await AppBootstrapService.instance.cadastrarProfissional(
      nome: nomeController.text.trim(),
      telefone: telefoneController.text.trim(),
    );

    if (!mounted) return;

    if (result.status.bloqueado) {
      Navigator.pushReplacementNamed(
        context,
        '/app-bloqueado',
        arguments: result.status,
      );
      return;
    }

    if (result.erroOnline != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro salvo. Sincronizacao online fica pendente.'),
        ),
      );
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  String? obrigatorio(String? value, String campo) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe $campo';
    }
    return null;
  }

  String? validarTelefone(String? value) {
    final erro = obrigatorio(value, 'seu telefone');
    if (erro != null) return erro;

    final digitos = value!.replaceAll(RegExp(r'\D'), '');
    if (digitos.length < 10 || digitos.length > 13) {
      return 'Informe um telefone válido com DDD';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          children: [
            Icon(
              Icons.verified_user_rounded,
              size: 58,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            const Text(
              'Vamos começar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Informe seus dados para identificar seu acesso ao FitCheck. É rápido e seguro.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Form(
              key: formKey,
              child: Column(
                children: [
                  AppInput(
                    controller: nomeController,
                    label: 'Nome',
                    icon: Icons.person_rounded,
                    validator: (value) => obrigatorio(value, 'seu nome'),
                  ),
                  AppInput(
                    controller: telefoneController,
                    label: 'Telefone com DDD',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    hint: '(11) 99999-9999',
                    validator: validarTelefone,
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Continuar',
                    icon: Icons.arrow_forward_rounded,
                    loading: salvando,
                    onPressed: salvando ? null : salvar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
