import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/app_config_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_button.dart';

class EmpresaScreen extends StatefulWidget {
  const EmpresaScreen({super.key});

  @override
  State<EmpresaScreen> createState() => _EmpresaScreenState();
}

class _EmpresaScreenState extends State<EmpresaScreen> {
  final nomeController = TextEditingController();
  final telefoneController = TextEditingController();
  final whatsappController = TextEditingController();
  final instagramController = TextEditingController();
  final documentoController = TextEditingController();
  final enderecoController = TextEditingController();
  final cidadeController = TextEditingController();
  final estadoController = TextEditingController();

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
    nomeController.dispose();
    telefoneController.dispose();
    whatsappController.dispose();
    instagramController.dispose();
    documentoController.dispose();
    enderecoController.dispose();
    cidadeController.dispose();
    estadoController.dispose();
    super.dispose();
  }

  Future<void> carregar() async {
    config = await AppDatabase.instance.buscarConfigApp();

    nomeController.text = config!.nomeEmpresa;
    telefoneController.text = config!.telefone;
    whatsappController.text = config!.whatsapp;
    instagramController.text = config!.instagram;
    documentoController.text = config!.documento;
    enderecoController.text = config!.endereco;
    cidadeController.text = config!.cidade;
    estadoController.text = config!.estado;

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> salvar() async {
    if (config == null) return;

    setState(() => salvando = true);

    final novaConfig = config!.copyWith(
      nomeEmpresa: nomeController.text.trim().isEmpty
          ? 'Atende Fácil'
          : nomeController.text.trim(),
      telefone: telefoneController.text.trim(),
      whatsapp: whatsappController.text.trim(),
      instagram: instagramController.text.trim().replaceAll('@', ''),
      documento: documentoController.text.trim(),
      endereco: enderecoController.text.trim(),
      cidade: cidadeController.text.trim(),
      estado: estadoController.text.trim(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    await AppDatabase.instance.salvarConfigApp(novaConfig);

    if (mounted) {
      setState(() => salvando = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dados da empresa salvos.')));
    }
  }

  Widget input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon, color: AppColors.navInactive),
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
      title: 'Empresa',
      subtitle: 'Dados do negócio',
      currentIndex: 4,
      showBack: true,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                input(
                  controller: nomeController,
                  label: 'Nome da empresa',
                  icon: Icons.storefront_rounded,
                ),
                input(
                  controller: telefoneController,
                  label: 'Telefone',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                input(
                  controller: whatsappController,
                  label: 'WhatsApp',
                  icon: Icons.chat_rounded,
                  keyboardType: TextInputType.phone,
                ),
                input(
                  controller: instagramController,
                  label: 'Instagram',
                  icon: Icons.alternate_email_rounded,
                ),
                input(
                  controller: documentoController,
                  label: 'CPF/CNPJ',
                  icon: Icons.badge_rounded,
                ),
                input(
                  controller: enderecoController,
                  label: 'Endereço',
                  icon: Icons.location_on_rounded,
                ),
                input(
                  controller: cidadeController,
                  label: 'Cidade',
                  icon: Icons.location_city_rounded,
                ),
                input(
                  controller: estadoController,
                  label: 'Estado',
                  icon: Icons.map_rounded,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Salvar',
                  loading: salvando,
                  onPressed: salvar,
                ),
              ],
            ),
    );
  }
}
