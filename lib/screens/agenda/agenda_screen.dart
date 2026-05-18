import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/agenda_model.dart';
import '../../models/cliente_model.dart';
import '../../widgets/app_fab.dart';
import '../../widgets/app_scaffold.dart';
import 'agenda_form_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  bool loading = true;

  DateTime dataSelecionada = DateTime.now();

  List<AgendaModel> agenda = [];
  List<ClienteModel> clientes = [];

  int totalDia = 0;
  int totalSemana = 0;
  int totalMes = 0;

  String visualizacao = 'DIA';

  final Map<String, List<AgendaModel>> agendaAgrupada = {};

  @override
  void initState() {
    super.initState();
    carregarAgenda();
  }

  String dataSql(DateTime data) {
    return '${data.year.toString().padLeft(4, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }

  String dataBr(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}';
  }

  DateTime inicioSemana(DateTime data) {
    return data.subtract(Duration(days: data.weekday - 1));
  }

  DateTime fimSemana(DateTime data) {
    return inicioSemana(data).add(const Duration(days: 6));
  }

  Future<void> carregarAgenda() async {
    setState(() => loading = true);

    clientes = await AppDatabase.instance.listarClientes();

    agenda = await AppDatabase.instance.listarAgendaDoDiaComRecorrencia(
      dataSelecionada,
    );

    totalDia = agenda.where((a) => a.status != 'CANCELADO').length;

    totalSemana = await contarPeriodo(
      inicio: inicioSemana(dataSelecionada),
      fim: fimSemana(dataSelecionada),
    );

    totalMes = await contarPeriodo(
      inicio: DateTime(dataSelecionada.year, dataSelecionada.month, 1),
      fim: DateTime(dataSelecionada.year, dataSelecionada.month + 1, 0),
    );

    await montarAgrupamentos();

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> montarAgrupamentos() async {
    agendaAgrupada.clear();

    if (visualizacao == 'SEMANA') {
      final inicio = inicioSemana(dataSelecionada);

      for (int i = 0; i < 7; i++) {
        final data = inicio.add(Duration(days: i));

        final itens = await AppDatabase.instance
            .listarAgendaDoDiaComRecorrencia(data);

        if (itens.isNotEmpty) {
          agendaAgrupada[dataBr(data)] = itens;
        }
      }
    }

    if (visualizacao == 'MES') {
      final inicio = DateTime(dataSelecionada.year, dataSelecionada.month, 1);

      final fim = DateTime(dataSelecionada.year, dataSelecionada.month + 1, 0);

      DateTime atual = inicio;

      while (!atual.isAfter(fim)) {
        final itens = await AppDatabase.instance
            .listarAgendaDoDiaComRecorrencia(atual);

        if (itens.isNotEmpty) {
          agendaAgrupada[dataBr(atual)] = itens;
        }

        atual = atual.add(const Duration(days: 1));
      }
    }
  }

  Future<int> contarPeriodo({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    int total = 0;

    DateTime atual = inicio;

    while (!atual.isAfter(fim)) {
      final itens = await AppDatabase.instance.listarAgendaDoDiaComRecorrencia(
        atual,
      );

      total += itens.where((i) => i.status != 'CANCELADO').length;

      atual = atual.add(const Duration(days: 1));
    }

    return total;
  }

  Future<void> abrirFormulario({AgendaModel? item}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AgendaFormScreen(agenda: item)),
    );

    carregarAgenda();
  }

  Future<void> excluir(AgendaModel item) async {
    if (item.id == null) return;

    await AppDatabase.instance.deletarAgenda(item.id!);

    carregarAgenda();
  }

  ClienteModel? buscarCliente(int? clienteId) {
    if (clienteId == null) return null;

    try {
      return clientes.firstWhere((c) => c.id == clienteId);
    } catch (_) {
      return null;
    }
  }

  String diaSemana(DateTime data) {
    const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return dias[data.weekday - 1];
  }

  Future<void> enviarWhatsapp(AgendaModel item) async {
    final cliente = buscarCliente(item.clienteId);

    if (cliente == null || cliente.telefone.trim().isEmpty) {
      return;
    }

    final telefone = cliente.telefone.replaceAll(RegExp(r'\D'), '');

    final mensagem =
        '''
Olá ${cliente.nome}, tudo bem?

Lembrando do seu atendimento:

${item.titulo}

Data: ${item.dataInicio}
Horário: ${item.horaInicio}
''';

    final uri = Uri.parse(
      'https://wa.me/55$telefone?text=${Uri.encodeComponent(mensagem)}',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget resumoCard({
    required String label,
    required int total,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 84,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    total.toString(),
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget diaChip(DateTime data) {
    final selected = dataSql(data) == dataSql(dataSelecionada);

    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () async {
        setState(() => dataSelecionada = data);

        await carregarAgenda();
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 62,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? primary : AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              diaSemana(data),
              style: TextStyle(
                color: selected ? Colors.white70 : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.day.toString().padLeft(2, '0'),
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget agendaCard(AgendaModel item) {
    final cliente = buscarCliente(item.clienteId);

    Color statusColor = Theme.of(context).colorScheme.secondary;

    if (item.status == 'CONCLUIDO') {
      statusColor = AppColors.success;
    }

    if (item.status == 'CANCELADO') {
      statusColor = AppColors.danger;
    }

    if (item.status == 'FALTOU') {
      statusColor = AppColors.textMuted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => abrirFormulario(item: item),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.12),
          child: Icon(Icons.event_available_rounded, color: statusColor),
        ),
        title: Text(
          item.titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          '${cliente?.nome ?? 'Cliente não informado'}\n'
          '${item.horaInicio} - ${item.horaFim.isEmpty ? '--:--' : item.horaFim}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => enviarWhatsapp(item),
              icon: const Icon(Icons.chat_rounded, color: Colors.green),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'editar') {
                  abrirFormulario(item: item);
                }

                if (value == 'excluir') {
                  excluir(item);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(value: 'excluir', child: Text('Excluir')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget agrupamentoAgenda() {
    if (visualizacao == 'DIA') {
      if (agenda.isEmpty) {
        return const Text(
          'Nenhum atendimento agendado',
          style: TextStyle(color: AppColors.textMuted),
        );
      }

      return Column(children: agenda.map(agendaCard).toList());
    }

    if (agendaAgrupada.isEmpty) {
      return const Text(
        'Nenhum atendimento encontrado',
        style: TextStyle(color: AppColors.textMuted),
      );
    }

    return Column(
      children: agendaAgrupada.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                entry.key,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ...entry.value.map(agendaCard),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final inicio = inicioSemana(dataSelecionada);

    final dias = List.generate(7, (index) => inicio.add(Duration(days: index)));

    return AppScaffold(
      title: 'Agenda',
      subtitle: 'Atendimentos',
      currentIndex: 1,
      showBack: true,
      floatingActionButton: AppFab(onPressed: () => abrirFormulario()),
      body: RefreshIndicator(
        onRefresh: carregarAgenda,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            Row(
              children: [
                resumoCard(
                  label: 'Hoje',
                  total: totalDia,
                  icon: Icons.today_rounded,
                  color: primary,
                ),
                const SizedBox(width: 10),
                resumoCard(
                  label: 'Semana',
                  total: totalSemana,
                  icon: Icons.view_week_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 10),
                resumoCard(
                  label: 'Mês',
                  total: totalMes,
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.success,
                ),
              ],
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Dia'),
                      selected: visualizacao == 'DIA',
                      onSelected: (_) async {
                        visualizacao = 'DIA';
                        await carregarAgenda();
                      },
                    ),
                  ),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Semana'),
                      selected: visualizacao == 'SEMANA',
                      onSelected: (_) async {
                        visualizacao = 'SEMANA';
                        await carregarAgenda();
                      },
                    ),
                  ),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Mês'),
                      selected: visualizacao == 'MES',
                      onSelected: (_) async {
                        visualizacao = 'MES';
                        await carregarAgenda();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: dias.map(diaChip).toList()),
            ),

            const SizedBox(height: 18),

            agrupamentoAgenda(),
          ],
        ),
      ),
    );
  }
}
