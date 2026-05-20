import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/exercicio_model.dart';
import '../../widgets/app_scaffold.dart';

class ExerciciosScreen extends StatefulWidget {
  const ExerciciosScreen({super.key});

  @override
  State<ExerciciosScreen> createState() => _ExerciciosScreenState();
}

class _ExerciciosScreenState extends State<ExerciciosScreen> {
  bool loading = true;
  List<ExercicioModel> exercicios = [];

  final TextEditingController buscaController = TextEditingController();
  String busca = '';

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    setState(() => loading = true);

    exercicios = await AppDatabase.instance.listarExercicios();

    if (mounted) {
      setState(() => loading = false);
    }
  }

  List<ExercicioModel> get exerciciosFiltrados {
    if (busca.trim().isEmpty) return exercicios;

    final termo = busca.toLowerCase().trim();

    return exercicios.where((e) {
      return e.nome.toLowerCase().contains(termo) ||
          (e.categoria ?? '').toLowerCase().contains(termo) ||
          (e.grupoMuscular ?? '').toLowerCase().contains(termo);
    }).toList();
  }

  Future<void> novoExercicio() async {
    await Navigator.pushNamed(context, '/exercicio-form');
    carregarDados();
  }

  Future<void> abrirExercicio(ExercicioModel exercicio) async {
    await Navigator.pushNamed(context, '/exercicio-form', arguments: exercicio);

    carregarDados();
  }

  Future<void> excluirExercicio(ExercicioModel exercicio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Excluir exercício'),
          content: Text('Deseja remover "${exercicio.nome}" da biblioteca?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await AppDatabase.instance.deletarExercicio(exercicio.id!);
    carregarDados();
  }

  Future<void> alternarFavorito(ExercicioModel exercicio) async {
    await AppDatabase.instance.alternarFavoritoExercicio(
      id: exercicio.id!,
      favorito: exercicio.favorito,
    );

    carregarDados();
  }

  Widget buscaInput() {
    return TextField(
      controller: buscaController,
      onChanged: (value) {
        setState(() => busca = value);
      },
      decoration: InputDecoration(
        hintText: 'Buscar exercício, categoria ou grupo muscular',
        prefixIcon: const Icon(Icons.search_rounded),
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
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget exercicioCard(ExercicioModel exercicio) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: primary.withOpacity(0.10),
          child: Icon(Icons.fitness_center_rounded, color: primary, size: 20),
        ),
        title: Text(
          exercicio.nome,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          [
            if ((exercicio.categoria ?? '').isNotEmpty) exercicio.categoria!,
            if ((exercicio.grupoMuscular ?? '').isNotEmpty)
              exercicio.grupoMuscular!,
          ].join(' • '),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'editar') abrirExercicio(exercicio);
            if (value == 'favorito') alternarFavorito(exercicio);
            if (value == 'excluir') excluirExercicio(exercicio);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'editar', child: Text('Editar')),
            PopupMenuItem(
              value: 'favorito',
              child: Text(
                exercicio.favorito == 1
                    ? 'Remover favorito'
                    : 'Marcar favorito',
              ),
            ),
            const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
          ],
        ),
        onTap: () => abrirExercicio(exercicio),
      ),
    );
  }

  Widget emptyState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.library_books_rounded,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum exercício cadastrado',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cadastre exercícios com categoria, grupo muscular, descrição e vídeo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: novoExercicio,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Cadastrar exercício'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Exercícios',
      subtitle: 'Biblioteca de exercícios',
      currentIndex: 4,
      floatingActionButton: FloatingActionButton(
        onPressed: novoExercicio,
        child: const Icon(Icons.add_rounded),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregarDados,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  buscaInput(),
                  const SizedBox(height: 16),

                  if (exerciciosFiltrados.isEmpty)
                    emptyState()
                  else
                    ...exerciciosFiltrados.map(exercicioCard),
                ],
              ),
            ),
    );
  }
}
