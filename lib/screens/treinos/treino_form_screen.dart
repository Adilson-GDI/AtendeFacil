import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/cliente_model.dart';
import '../../models/exercicio_model.dart';
import '../../models/treino_item_model.dart';
import '../../models/treino_model.dart';
import '../../widgets/app_scaffold.dart';

class TreinoFormScreen extends StatefulWidget {
  const TreinoFormScreen({super.key});

  @override
  State<TreinoFormScreen> createState() => _TreinoFormScreenState();
}

class _TreinoFormScreenState extends State<TreinoFormScreen> {
  final formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final divisaoController = TextEditingController();
  final objetivoController = TextEditingController();
  final observacoesController = TextEditingController();

  bool carregouArgs = false;
  bool salvando = false;

  TreinoModel? treino;
  List<TreinoItemModel> itens = [];

  List<ClienteModel> clientes = [];
  ClienteModel? clienteSelecionado;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (carregouArgs) return;
    carregouArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is TreinoModel) {
      treino = args;

      nomeController.text = treino!.nome;
      divisaoController.text = treino!.divisao ?? '';
      objetivoController.text = treino!.objetivo ?? '';
      observacoesController.text = treino!.observacoes ?? '';

      carregarItens(treino!.id!);
    }

    carregarClientes();
  }

  Future<void> carregarItens(int treinoId) async {
    itens = await AppDatabase.instance.listarItensDoTreino(treinoId);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> carregarClientes() async {
    clientes = await AppDatabase.instance.listarClientes();

    if (treino?.clienteId != null) {
      try {
        clienteSelecionado = clientes.firstWhere(
          (c) => c.id == treino!.clienteId,
        );
      } catch (_) {
        clienteSelecionado = null;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    divisaoController.dispose();
    objetivoController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => salvando = true);

    final agora = DateTime.now().toIso8601String();

    final model = TreinoModel(
      id: treino?.id,
      clienteId: clienteSelecionado?.id ?? treino?.clienteId,
      nome: nomeController.text.trim(),
      divisao: divisaoController.text.trim(),
      objetivo: objetivoController.text.trim(),
      observacoes: observacoesController.text.trim(),
      ativo: 1,
      createdAt: treino?.createdAt ?? agora,
      updatedAt: treino == null ? null : agora,
    );

    await AppDatabase.instance.salvarTreinoComItens(
      treino: model,
      itens: itens,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String montarMensagemTreino() {
    final buffer = StringBuffer();

    buffer.writeln('Olá ${clienteSelecionado?.nome ?? ''}, tudo bem?');
    buffer.writeln('');
    buffer.writeln('Segue seu treino:');
    buffer.writeln('');
    buffer.writeln('*${nomeController.text.trim()}*');

    if (objetivoController.text.trim().isNotEmpty) {
      buffer.writeln('Objetivo: ${objetivoController.text.trim()}');
    }

    if (divisaoController.text.trim().isNotEmpty) {
      buffer.writeln('Divisão: ${divisaoController.text.trim()}');
    }

    buffer.writeln('');

    for (int i = 0; i < itens.length; i++) {
      final item = itens[i];

      buffer.writeln('${i + 1}. *${item.nomeExercicio}*');

      if ((item.series ?? '').isNotEmpty) {
        buffer.writeln('Séries: ${item.series}');
      }

      if ((item.repeticoes ?? '').isNotEmpty) {
        buffer.writeln('Repetições: ${item.repeticoes}');
      }

      if ((item.carga ?? '').isNotEmpty) {
        buffer.writeln('Carga: ${item.carga}');
      }

      if ((item.descanso ?? '').isNotEmpty) {
        buffer.writeln('Descanso: ${item.descanso}');
      }

      if ((item.tempo ?? '').isNotEmpty) {
        buffer.writeln('Tempo: ${item.tempo}');
      }

      if ((item.observacoes ?? '').isNotEmpty) {
        buffer.writeln('Obs: ${item.observacoes}');
      }

      buffer.writeln('');
    }

    if (observacoesController.text.trim().isNotEmpty) {
      buffer.writeln('Observações gerais:');
      buffer.writeln(observacoesController.text.trim());
      buffer.writeln('');
    }

    buffer.writeln('Bons treinos!');

    return buffer.toString();
  }

  Future<void> enviarWhatsApp() async {
    final cliente = clienteSelecionado;

    if (cliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este treino não está vinculado a um cliente.'),
        ),
      );
      return;
    }

    final telefone = cliente.telefone?.replaceAll(RegExp(r'\D'), '');

    if (telefone == null || telefone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente sem telefone cadastrado.')),
      );
      return;
    }

    if (itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este treino não possui exercícios.')),
      );
      return;
    }

    String numero = telefone;

    if (!numero.startsWith('55')) {
      numero = '55$numero';
    }

    final mensagem = montarMensagemTreino();

    final url = Uri.parse(
      'https://wa.me/$numero?text=${Uri.encodeComponent(mensagem)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  Future<void> selecionarDivisao() async {
    final opcoes = [
      'A',
      'B',
      'C',
      'D',
      'ABC',
      'ABCD',
      'Full Body',
      'Funcional',
      'Mobilidade',
      'Reabilitação',
    ];

    final selecionada = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
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
                  'Divisão do treino',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ...opcoes.map((item) {
                  return ListTile(
                    title: Text(item),
                    trailing: divisaoController.text == item
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.navInactive,
                          ),
                    onTap: () => Navigator.pop(context, item),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selecionada != null) {
      setState(() => divisaoController.text = selecionada);
    }
  }

  Future<void> adicionarExercicio() async {
    final exercicios = await AppDatabase.instance.listarExercicios();

    if (!mounted) return;

    final selecionado = await showModalBottomSheet<ExercicioModel>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.78,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
              child: Column(
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
                    'Adicionar exercício',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: exercicios.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum exercício cadastrado na biblioteca',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            itemCount: exercicios.length,
                            itemBuilder: (_, index) {
                              final e = exercicios[index];

                              return ListTile(
                                leading: const Icon(
                                  Icons.fitness_center_rounded,
                                ),
                                title: Text(e.nome),
                                subtitle: Text(
                                  [
                                    if ((e.categoria ?? '').isNotEmpty)
                                      e.categoria!,
                                    if ((e.grupoMuscular ?? '').isNotEmpty)
                                      e.grupoMuscular!,
                                  ].join(' • '),
                                ),
                                trailing: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
                                onTap: () => Navigator.pop(context, e),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selecionado == null) return;

    await configurarItemTreino(selecionado);
  }

  Future<void> configurarItemTreino(ExercicioModel exercicio) async {
    final seriesController = TextEditingController();
    final repeticoesController = TextEditingController();
    final cargaController = TextEditingController();
    final descansoController = TextEditingController();
    final tempoController = TextEditingController();
    final obsController = TextEditingController();

    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 14,
              bottom: MediaQuery.of(context).viewInsets.bottom + 22,
            ),
            child: SingleChildScrollView(
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
                  Text(
                    exercicio.nome,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _modalInput(seriesController, 'Séries', 'Ex: 3'),
                  _modalInput(repeticoesController, 'Repetições', 'Ex: 12'),
                  _modalInput(cargaController, 'Carga', 'Ex: 20kg'),
                  _modalInput(descansoController, 'Descanso', 'Ex: 60s'),
                  _modalInput(tempoController, 'Tempo', 'Ex: 40s'),
                  _modalInput(
                    obsController,
                    'Observações',
                    'Orientações do exercício',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Adicionar ao treino'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmado != true) return;

    final agora = DateTime.now().toIso8601String();

    setState(() {
      itens.add(
        TreinoItemModel(
          treinoId: treino?.id ?? 0,
          exercicioId: exercicio.id,
          nomeExercicio: exercicio.nome,
          categoria: exercicio.categoria,
          grupoMuscular: exercicio.grupoMuscular,
          ordem: itens.length + 1,
          series: seriesController.text.trim(),
          repeticoes: repeticoesController.text.trim(),
          carga: cargaController.text.trim(),
          descanso: descansoController.text.trim(),
          tempo: tempoController.text.trim(),
          observacoes: obsController.text.trim(),
          createdAt: agora,
        ),
      );
    });
  }

  Widget _modalInput(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget input({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        onTap: onTap,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget itemCard(TreinoItemModel item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text(
          item.nomeExercicio,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            if ((item.series ?? '').isNotEmpty) '${item.series} séries',
            if ((item.repeticoes ?? '').isNotEmpty)
              '${item.repeticoes} repetições',
            if ((item.carga ?? '').isNotEmpty) 'Carga ${item.carga}',
            if ((item.descanso ?? '').isNotEmpty) 'Descanso ${item.descanso}',
          ].join(' • '),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () {
            setState(() {
              itens.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editando = treino != null;
    final temCliente = clienteSelecionado != null || treino?.clienteId != null;

    return AppScaffold(
      title: editando ? 'Editar treino' : 'Novo treino',
      subtitle: temCliente ? 'Treino vinculado ao cliente' : 'Treino modelo',
      currentIndex: 4,
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            if (temCliente)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        clienteSelecionado?.nome ??
                            'Treino vinculado a cliente',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            input(
              controller: nomeController,
              label: 'Nome do treino',
              hint: 'Ex: Treino A - Peito e tríceps',
              icon: Icons.fitness_center_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome do treino';
                }
                return null;
              },
            ),

            input(
              controller: divisaoController,
              label: 'Divisão',
              hint: 'A, B, C, ABC, Full Body',
              icon: Icons.view_module_rounded,
              readOnly: true,
              onTap: selecionarDivisao,
            ),

            input(
              controller: objetivoController,
              label: 'Objetivo',
              hint: 'Ex: Hipertrofia, reabilitação, mobilidade',
              icon: Icons.flag_rounded,
            ),

            input(
              controller: observacoesController,
              label: 'Observações gerais',
              hint: 'Orientações gerais do treino',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Exercícios do treino',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: adicionarExercicio,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Adicionar'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (itens.isEmpty)
              const Text(
                'Nenhum exercício adicionado',
                style: TextStyle(color: AppColors.textMuted),
              )
            else
              ...itens.asMap().entries.map((entry) {
                return itemCard(entry.value, entry.key);
              }),

            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: salvando ? null : salvar,
                icon: salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(editando ? 'Salvar alterações' : 'Salvar treino'),
              ),
            ),

            if (temCliente) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: enviarWhatsApp,
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('Enviar treino no WhatsApp'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
