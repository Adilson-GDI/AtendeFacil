import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  final emailController = TextEditingController();
  final whatsappController = TextEditingController();
  final instagramController = TextEditingController();

  final cepController = TextEditingController();
  final enderecoController = TextEditingController();
  final cidadeController = TextEditingController();
  final estadoController = TextEditingController();

  AppConfigModel? config;

  bool loading = true;
  bool salvando = false;
  bool buscandoCep = false;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    whatsappController.dispose();
    instagramController.dispose();
    cepController.dispose();
    enderecoController.dispose();
    cidadeController.dispose();
    estadoController.dispose();
    super.dispose();
  }

  Future<void> carregar() async {
    config = await AppDatabase.instance.buscarConfigApp();

    nomeController.text = config!.nomeEmpresa;
    emailController.text = config!.email;
    whatsappController.text = config!.whatsapp;
    instagramController.text = config!.instagram;
    cepController.text = config!.cep;
    enderecoController.text = config!.endereco;
    cidadeController.text = config!.cidade;
    estadoController.text = config!.estado;

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> buscarCep() async {
    final cep = cepController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um CEP válido com 8 números.')),
      );
      return;
    }

    setState(() => buscandoCep = true);

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cep/json/'),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao buscar CEP');
      }

      final data = jsonDecode(response.body);

      if (data['erro'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CEP não encontrado. Preencha manualmente.'),
          ),
        );
        return;
      }

      enderecoController.text = data['logradouro'] ?? '';
      cidadeController.text = data['localidade'] ?? '';
      estadoController.text = data['uf'] ?? '';
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível buscar o CEP. Preencha manualmente.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => buscandoCep = false);
      }
    }
  }

  Future<void> salvar() async {
    if (config == null) return;

    if (nomeController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        whatsappController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha os dados obrigatórios da empresa.'),
        ),
      );
      return;
    }

    setState(() => salvando = true);

    final novaConfig = config!.copyWith(
      nomeEmpresa: nomeController.text.trim(),
      email: emailController.text.trim(),
      whatsapp: whatsappController.text.trim(),
      instagram: instagramController.text.trim().replaceAll('@', ''),
      cep: cepController.text.trim(),
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

  Widget section({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: requiredField ? '$label *' : label,
          filled: true,
          fillColor: const Color(0xffF8FAFC),
          prefixIcon: Icon(icon, color: AppColors.navInactive),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget cepInput() {
    return Row(
      children: [
        Expanded(
          child: input(
            controller: cepController,
            label: 'CEP',
            icon: Icons.markunread_mailbox_rounded,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: buscandoCep ? null : buscarCep,
              icon: buscandoCep
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(buscandoCep ? 'Buscando' : 'Buscar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
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
                section(
                  title: 'Dados obrigatórios',
                  subtitle:
                      'Essas informações são usadas no app e nas comunicações.',
                  children: [
                    input(
                      controller: nomeController,
                      label: 'Nome da empresa',
                      icon: Icons.storefront_rounded,
                      requiredField: true,
                    ),
                    input(
                      controller: emailController,
                      label: 'E-mail',
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      requiredField: true,
                    ),
                    input(
                      controller: whatsappController,
                      label: 'WhatsApp',
                      icon: Icons.chat_rounded,
                      keyboardType: TextInputType.phone,
                      requiredField: true,
                    ),
                    input(
                      controller: instagramController,
                      label: 'Instagram',
                      icon: Icons.alternate_email_rounded,
                    ),
                  ],
                ),

                section(
                  title: 'Endereço',
                  subtitle:
                      'Busque pelo CEP ou preencha manualmente se não encontrar.',
                  children: [
                    cepInput(),
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
                  ],
                ),

                const SizedBox(height: 4),
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
