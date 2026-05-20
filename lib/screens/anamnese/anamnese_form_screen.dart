import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/anamnese_database.dart';
import '../../database/app_database.dart';
import '../../models/anamnese_model.dart';
import '../../models/cliente_model.dart';
import '../../widgets/app_scaffold.dart';

class AnamneseFormScreen extends StatefulWidget {
  final AnamneseModel? anamnese;

  const AnamneseFormScreen({super.key, this.anamnese});

  @override
  State<AnamneseFormScreen> createState() => _AnamneseFormScreenState();
}

class _AnamneseFormScreenState extends State<AnamneseFormScreen> {
  final formKey = GlobalKey<FormState>();

  final objetivoController = TextEditingController();
  final queixaController = TextEditingController();
  final historicoController = TextEditingController();
  final lesoesController = TextEditingController();
  final cirurgiasController = TextEditingController();
  final medicamentosController = TextEditingController();
  final alergiasController = TextEditingController();
  final doresController = TextEditingController();
  final limitacoesController = TextEditingController();
  final nivelAtividadeController = TextEditingController();
  final observacoesController = TextEditingController();

  bool loading = true;
  bool salvando = false;

  List<ClienteModel> clientes = [];
  ClienteModel? clienteSelecionado;
  String tipoServico = 'GERAL';

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    objetivoController.dispose();
    queixaController.dispose();
    historicoController.dispose();
    lesoesController.dispose();
    cirurgiasController.dispose();
    medicamentosController.dispose();
    alergiasController.dispose();
    doresController.dispose();
    limitacoesController.dispose();
    nivelAtividadeController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    clientes = await AppDatabase.instance.listarClientes();
    tipoServico = await AppDatabase.instance.buscarTipoServicoApp();

    if (widget.anamnese != null) {
      final a = widget.anamnese!;

      objetivoController.text = a.objetivo;
      queixaController.text = a.queixaPrincipal;
      historicoController.text = a.historicoSaude;
      lesoesController.text = a.lesoes;
      cirurgiasController.text = a.cirurgias;
      medicamentosController.text = a.medicamentos;
      alergiasController.text = a.alergias;
      doresController.text = a.dores;
      limitacoesController.text = a.limitacoes;
      nivelAtividadeController.text = a.nivelAtividade;
      observacoesController.text = a.observacoes;

      try {
        clienteSelecionado = clientes.firstWhere((c) => c.id == a.clienteId);
      } catch (_) {
        clienteSelecionado = null;
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> salvar() async {
    if (!formKey.currentState!.validate()) return;

    if (clienteSelecionado == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione um cliente.')));
      return;
    }

    setState(() => salvando = true);

    final agora = DateTime.now().toIso8601String();

    final anamnese = AnamneseModel(
      id: widget.anamnese?.id,
      clienteId: clienteSelecionado!.id!,
      tipoServico: tipoServico,
      objetivo: objetivoController.text.trim(),
      queixaPrincipal: queixaController.text.trim(),
      historicoSaude: historicoController.text.trim(),
      lesoes: lesoesController.text.trim(),
      cirurgias: cirurgiasController.text.trim(),
      medicamentos: medicamentosController.text.trim(),
      alergias: alergiasController.text.trim(),
      dores: doresController.text.trim(),
      limitacoes: limitacoesController.text.trim(),
      nivelAtividade: nivelAtividadeController.text.trim(),
      observacoes: observacoesController.text.trim(),
      dataAnamnese: widget.anamnese?.dataAnamnese ?? agora,
      createdAt: widget.anamnese?.createdAt ?? agora,
      updatedAt: widget.anamnese == null ? null : agora,
    );

    await AnamneseDatabase.instance.salvarAnamnese(anamnese);

    if (!mounted) return;

    setState(() => salvando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anamnese salva com sucesso.')),
    );

    Navigator.pop(context, true);
  }

  Widget input({
    required String label,
    required TextEditingController controller,
    int maxLines = 3,
    String? hint,
    bool requiredField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: requiredField
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Campo obrigatório';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          alignLabelWithHint: maxLines > 1,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget clienteSelect() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ClienteModel>(
          value: clienteSelecionado,
          isExpanded: true,
          hint: const Text('Selecione o cliente'),
          items: clientes.map((cliente) {
            return DropdownMenuItem<ClienteModel>(
              value: cliente,
              child: Text(cliente.nome),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => clienteSelecionado = value);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.anamnese == null ? 'Nova anamnese' : 'Editar anamnese',
      subtitle: 'Avaliação inicial do cliente',
      currentIndex: 0,
      showBack: true,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  clienteSelect(),

                  input(
                    label: 'Objetivo',
                    controller: objetivoController,
                    requiredField: true,
                    hint: 'Ex: emagrecimento, reabilitação, hipertrofia...',
                  ),

                  input(
                    label: 'Queixa principal',
                    controller: queixaController,
                    hint: 'Ex: dor lombar, falta de condicionamento...',
                  ),

                  input(
                    label: 'Histórico de saúde',
                    controller: historicoController,
                  ),

                  input(label: 'Lesões', controller: lesoesController),

                  input(label: 'Cirurgias', controller: cirurgiasController),

                  input(
                    label: 'Medicamentos',
                    controller: medicamentosController,
                  ),

                  input(label: 'Alergias', controller: alergiasController),

                  input(label: 'Dores', controller: doresController),

                  input(label: 'Limitações', controller: limitacoesController),

                  input(
                    label: 'Nível de atividade física',
                    controller: nivelAtividadeController,
                    hint: 'Sedentário, iniciante, intermediário, avançado...',
                  ),

                  input(
                    label: 'Observações profissionais',
                    controller: observacoesController,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: salvando ? null : salvar,
                      icon: salvando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        salvando ? 'Salvando...' : 'Salvar anamnese',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
