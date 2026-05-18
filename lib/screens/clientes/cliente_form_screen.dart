import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/cliente_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_button.dart';

class ClienteFormScreen extends StatefulWidget {
  final ClienteModel? cliente;

  const ClienteFormScreen({super.key, this.cliente});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final telefoneController = TextEditingController();
  final instagramController = TextEditingController();

  bool salvando = false;

  bool get editando => widget.cliente != null;

  @override
  void initState() {
    super.initState();

    if (editando) {
      nomeController.text = widget.cliente!.nome;
      telefoneController.text = widget.cliente!.telefone;
      instagramController.text = widget.cliente!.instagram;
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    telefoneController.dispose();
    instagramController.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => salvando = true);

    final agora = DateTime.now().toIso8601String();

    final cliente = ClienteModel(
      id: widget.cliente?.id,
      nome: nomeController.text.trim(),
      telefone: telefoneController.text.trim(),
      instagram: instagramController.text.trim().replaceAll('@', ''),
      createdAt: widget.cliente?.createdAt ?? agora,
      updatedAt: editando ? agora : null,
    );

    if (editando) {
      await AppDatabase.instance.atualizarCliente(cliente);
    } else {
      await AppDatabase.instance.criarCliente(cliente);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.navInactive),
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: editando ? 'Editar cliente' : 'Novo cliente',
      subtitle: editando ? 'Atualizar cadastro' : 'Cadastrar cliente',
      currentIndex: 1,
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _input(
                      controller: nomeController,
                      label: 'Nome',
                      icon: Icons.person_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome do cliente';
                        }
                        return null;
                      },
                    ),
                    _input(
                      controller: telefoneController,
                      label: 'Telefone',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    _input(
                      controller: instagramController,
                      label: 'Instagram',
                      icon: Icons.alternate_email_rounded,
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: editando ? 'Salvar alterações' : 'Salvar cliente',
                      loading: salvando,
                      onPressed: salvar,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
