import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/exercicio_model.dart';
import '../../widgets/app_scaffold.dart';

class ExercicioFormScreen extends StatefulWidget {
  const ExercicioFormScreen({super.key});

  @override
  State<ExercicioFormScreen> createState() => _ExercicioFormScreenState();
}

class _ExercicioFormScreenState extends State<ExercicioFormScreen> {
  final formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final categoriaController = TextEditingController();
  final grupoMuscularController = TextEditingController();
  final descricaoController = TextEditingController();
  final videoUrlController = TextEditingController();

  bool carregouArgs = false;
  bool salvando = false;

  ExercicioModel? exercicio;

  final List<String> categorias = [
    'Peito',
    'Costas',
    'Pernas',
    'Ombros',
    'Bíceps',
    'Tríceps',
    'Abdômen',
    'Glúteos',
    'Mobilidade',
    'Funcional',
    'Cardio',
    'Alongamento',
    'Reabilitação',
    'Outro',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (carregouArgs) return;
    carregouArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is ExercicioModel) {
      exercicio = args;

      nomeController.text = exercicio!.nome;
      categoriaController.text = exercicio!.categoria ?? '';
      grupoMuscularController.text = exercicio!.grupoMuscular ?? '';
      descricaoController.text = exercicio!.descricao ?? '';
      videoUrlController.text = exercicio!.videoUrl ?? '';
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    categoriaController.dispose();
    grupoMuscularController.dispose();
    descricaoController.dispose();
    videoUrlController.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => salvando = true);

    final agora = DateTime.now().toIso8601String();

    final model = ExercicioModel(
      id: exercicio?.id,
      nome: nomeController.text.trim(),
      categoria: categoriaController.text.trim(),
      grupoMuscular: grupoMuscularController.text.trim(),
      descricao: descricaoController.text.trim(),
      videoUrl: videoUrlController.text.trim(),
      favorito: exercicio?.favorito ?? 0,
      ativo: 1,
      createdAt: exercicio?.createdAt ?? agora,
      updatedAt: exercicio == null ? null : agora,
    );

    if (exercicio == null) {
      await AppDatabase.instance.criarExercicio(model);
    } else {
      await AppDatabase.instance.atualizarExercicio(model);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> selecionarCategoria() async {
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
                  'Categoria do exercício',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categorias.length,
                    itemBuilder: (_, index) {
                      final item = categorias[index];

                      return ListTile(
                        title: Text(item),
                        trailing: categoriaController.text == item
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
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selecionada != null) {
      setState(() {
        categoriaController.text = selecionada;
        grupoMuscularController.text = selecionada;
      });
    }
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget infoCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'A biblioteca será usada para montar fichas de treino mais rápido.',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editando = exercicio != null;

    return AppScaffold(
      title: editando ? 'Editar exercício' : 'Novo exercício',
      subtitle: 'Biblioteca de exercícios',
      currentIndex: 4,
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            infoCard(),

            input(
              controller: nomeController,
              label: 'Nome do exercício',
              hint: 'Ex: Supino reto',
              icon: Icons.fitness_center_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome do exercício';
                }
                return null;
              },
            ),

            input(
              controller: categoriaController,
              label: 'Categoria',
              hint: 'Ex: Peito, Pernas, Mobilidade',
              icon: Icons.category_rounded,
              readOnly: true,
              onTap: selecionarCategoria,
            ),

            input(
              controller: grupoMuscularController,
              label: 'Grupo muscular',
              hint: 'Ex: Peitoral, Quadríceps, Lombar',
              icon: Icons.accessibility_new_rounded,
            ),

            input(
              controller: descricaoController,
              label: 'Descrição / orientação',
              hint: 'Explique como executar ou cuidados importantes',
              icon: Icons.notes_rounded,
              maxLines: 4,
            ),

            input(
              controller: videoUrlController,
              label: 'Link de vídeo ou GIF',
              hint: 'https://...',
              icon: Icons.play_circle_outline_rounded,
            ),

            const SizedBox(height: 8),

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
                label: Text(
                  editando ? 'Salvar alterações' : 'Cadastrar exercício',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
