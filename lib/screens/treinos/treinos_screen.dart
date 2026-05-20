import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/cliente_model.dart';
import '../../models/treino_model.dart';
import '../../widgets/app_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/treino_item_model.dart';

class TreinosScreen extends StatefulWidget {
  const TreinosScreen({super.key});

  @override
  State<TreinosScreen> createState() => _TreinosScreenState();
}

class _TreinosScreenState extends State<TreinosScreen> {
  bool loading = true;

  List<TreinoModel> treinos = [];
  List<ClienteModel> clientes = [];

  final TextEditingController buscaController = TextEditingController();

  String busca = '';
  String filtroTipo = 'TODOS';
  int? clienteFiltroId;

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

    clientes = await AppDatabase.instance.listarClientes();
    treinos = await AppDatabase.instance.listarTreinos();

    if (mounted) {
      setState(() => loading = false);
    }
  }

  List<TreinoModel> get treinosFiltrados {
    var lista = [...treinos];

    lista.sort((a, b) {
      if (a.clienteId == null && b.clienteId != null) return -1;
      if (a.clienteId != null && b.clienteId == null) return 1;
      return (b.id ?? 0).compareTo(a.id ?? 0);
    });

    if (filtroTipo == 'MODELOS') {
      lista = lista.where((t) => t.clienteId == null).toList();
    }

    if (filtroTipo == 'CLIENTES') {
      lista = lista.where((t) => t.clienteId != null).toList();
    }

    if (clienteFiltroId != null) {
      lista = lista.where((t) => t.clienteId == clienteFiltroId).toList();
    }

    if (busca.trim().isNotEmpty) {
      final termo = busca.toLowerCase().trim();

      lista = lista.where((t) {
        return t.nome.toLowerCase().contains(termo) ||
            (t.divisao ?? '').toLowerCase().contains(termo) ||
            (t.objetivo ?? '').toLowerCase().contains(termo);
      }).toList();
    }

    return lista;
  }

  ClienteModel? clienteDoTreino(TreinoModel treino) {
    if (treino.clienteId == null) return null;

    try {
      return clientes.firstWhere((c) => c.id == treino.clienteId);
    } catch (_) {
      return null;
    }
  }

  Future<void> novoTreino() async {
    await Navigator.pushNamed(context, '/treino-form');
    carregarDados();
  }

  Future<void> abrirTreino(TreinoModel treino) async {
    await Navigator.pushNamed(context, '/treino-form', arguments: treino);

    carregarDados();
  }

  Future<void> excluirTreino(TreinoModel treino) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Excluir treino'),
          content: Text('Deseja excluir "${treino.nome}"?'),
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

    await AppDatabase.instance.deletarTreino(treino.id!);
    carregarDados();
  }

  Future<void> enviarTreinoWhatsApp(TreinoModel treino) async {
    final cliente = clienteDoTreino(treino);

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

    final itens = await AppDatabase.instance.listarItensDoTreino(treino.id!);

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

    final mensagem = montarMensagemTreinoLista(
      treino: treino,
      clienteNome: cliente.nome,
      itens: itens,
    );

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

  String montarMensagemTreinoLista({
    required TreinoModel treino,
    required String clienteNome,
    required List<TreinoItemModel> itens,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Olá $clienteNome, tudo bem?');
    buffer.writeln('');
    buffer.writeln('Segue seu treino:');
    buffer.writeln('');
    buffer.writeln('*${treino.nome}*');

    if ((treino.objetivo ?? '').isNotEmpty) {
      buffer.writeln('Objetivo: ${treino.objetivo}');
    }

    if ((treino.divisao ?? '').isNotEmpty) {
      buffer.writeln('Divisão: ${treino.divisao}');
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

    if ((treino.observacoes ?? '').isNotEmpty) {
      buffer.writeln('Observações gerais:');
      buffer.writeln(treino.observacoes);
      buffer.writeln('');
    }

    buffer.writeln('Bons treinos!');

    return buffer.toString();
  }

  Future<void> vincularTreinoCliente(TreinoModel treino) async {
    if (clientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre um cliente antes de vincular o treino.'),
        ),
      );
      return;
    }

    final cliente = await showModalBottomSheet<ClienteModel>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.70,
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
                    'Vincular treino ao cliente',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Será criada uma cópia do treino para o cliente selecionado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.builder(
                      itemCount: clientes.length,
                      itemBuilder: (_, index) {
                        final item = clientes[index];

                        return ListTile(
                          leading: const Icon(Icons.person_rounded),
                          title: Text(item.nome),
                          subtitle: Text(item.telefone ?? ''),
                          trailing: const Icon(
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
          ),
        );
      },
    );

    if (cliente == null) return;

    await AppDatabase.instance.duplicarTreinoParaCliente(
      treinoModeloId: treino.id!,
      clienteId: cliente.id!,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Treino vinculado para ${cliente.nome}.')),
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
        hintText: 'Buscar treino, divisão ou objetivo',
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

  Widget filtrosTipo() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          filtroChip('TODOS', 'Todos'),
          const SizedBox(width: 8),
          filtroChip('MODELOS', 'Modelos'),
          const SizedBox(width: 8),
          filtroChip('CLIENTES', 'Clientes'),
          if (clienteFiltroId != null) ...[
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('Limpar cliente'),
              avatar: const Icon(Icons.close_rounded, size: 16),
              onPressed: () {
                setState(() {
                  clienteFiltroId = null;
                  filtroTipo = 'TODOS';
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget filtroChip(String value, String label) {
    final selecionado = filtroTipo == value;
    final primary = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Text(label),
      selected: selecionado,
      selectedColor: primary.withOpacity(0.12),
      labelStyle: TextStyle(
        color: selecionado ? primary : AppColors.textMuted,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(
        color: selecionado ? primary.withOpacity(0.30) : AppColors.border,
      ),
      onSelected: (_) {
        setState(() {
          filtroTipo = value;
          if (value != 'CLIENTES') {
            clienteFiltroId = null;
          }
        });
      },
    );
  }

  Widget filtroCliente() {
    if (filtroTipo != 'CLIENTES') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: clienteFiltroId,
          isExpanded: true,
          hint: const Text('Filtrar por cliente'),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Todos os clientes'),
            ),
            ...clientes.map((cliente) {
              return DropdownMenuItem<int?>(
                value: cliente.id,
                child: Text(cliente.nome),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              clienteFiltroId = value;
            });
          },
        ),
      ),
    );
  }

  Widget menuAtalho({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: primary.withOpacity(0.10),
              child: Icon(icon, color: primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.navInactive,
            ),
          ],
        ),
      ),
    );
  }

  Widget treinoCard(TreinoModel treino) {
    final primary = Theme.of(context).colorScheme.primary;
    final cliente = clienteDoTreino(treino);
    final isModelo = treino.clienteId == null;

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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: primary.withOpacity(0.10),
          child: Icon(
            isModelo ? Icons.layers_rounded : Icons.person_rounded,
            color: primary,
          ),
        ),
        title: Text(
          treino.nome,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          [
            isModelo
                ? 'Modelo genérico'
                : 'Cliente: ${cliente?.nome ?? 'Não encontrado'}',
            if (treino.divisao != null && treino.divisao!.isNotEmpty)
              'Divisão ${treino.divisao}',
            if (treino.objetivo != null && treino.objetivo!.isNotEmpty)
              treino.objetivo!,
          ].join(' • '),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'editar') abrirTreino(treino);
            if (value == 'vincular') vincularTreinoCliente(treino);
            if (value == 'whatsapp') enviarTreinoWhatsApp(treino);
            if (value == 'excluir') excluirTreino(treino);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'editar', child: Text('Editar')),

            if (isModelo)
              const PopupMenuItem(
                value: 'vincular',
                child: Text('Vincular cliente'),
              ),

            if (!isModelo)
              const PopupMenuItem(
                value: 'whatsapp',
                child: Text('Enviar WhatsApp'),
              ),

            const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
          ],
        ),
        onTap: () => abrirTreino(treino),
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
            Icons.fitness_center_rounded,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum treino encontrado',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Crie treinos modelo e depois vincule cópias aos clientes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: novoTreino,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Criar treino'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Treinos',
      subtitle: 'Modelos e treinos por cliente',
      currentIndex: 4,
      floatingActionButton: FloatingActionButton(
        onPressed: novoTreino,
        child: const Icon(Icons.add_rounded),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregarDados,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  menuAtalho(
                    icon: Icons.library_books_rounded,
                    title: 'Biblioteca de exercícios',
                    subtitle: 'Cadastrar exercícios por categoria',
                    onTap: () {
                      Navigator.pushNamed(context, '/exercicios');
                    },
                  ),

                  const SizedBox(height: 16),

                  buscaInput(),

                  const SizedBox(height: 12),

                  filtrosTipo(),

                  filtroCliente(),

                  const SizedBox(height: 18),

                  const Text(
                    'Lista de treinos',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (treinosFiltrados.isEmpty)
                    emptyState()
                  else
                    ...treinosFiltrados.map(treinoCard),
                ],
              ),
            ),
    );
  }
}
