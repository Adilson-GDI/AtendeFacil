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

  String dataBrCompleta(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
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

        agendaAgrupada[dataBr(data)] = itens;
      }
    }

    if (visualizacao == 'MES') {
      final inicio = DateTime(dataSelecionada.year, dataSelecionada.month, 1);
      final fim = DateTime(dataSelecionada.year, dataSelecionada.month + 1, 0);

      DateTime atual = inicio;

      while (!atual.isAfter(fim)) {
        final itens = await AppDatabase.instance
            .listarAgendaDoDiaComRecorrencia(atual);

        agendaAgrupada[dataBr(atual)] = itens;

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

  int quantidadeDoDia(DateTime data) {
    final key = dataBr(data);
    final itens = agendaAgrupada[key] ?? [];

    return itens.where((i) => i.status != 'CANCELADO').length;
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
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.12), width: 0.7),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$total\n$label',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget filtroVisualizacao(String value, String label) {
    final selected = visualizacao == value;
    final primary = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: InkWell(
        onTap: () async {
          setState(() => visualizacao = value);
          await carregarAgenda();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
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
    if (agenda.isEmpty) {
      return const Text(
        'Nenhum atendimento agendado',
        style: TextStyle(color: AppColors.textMuted),
      );
    }

    return Column(children: agenda.map(agendaCard).toList());
  }

  Widget cabecalhoCalendario() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              setState(() {
                if (visualizacao == 'SEMANA') {
                  dataSelecionada = dataSelecionada.subtract(
                    const Duration(days: 7),
                  );
                } else {
                  dataSelecionada = DateTime(
                    dataSelecionada.year,
                    dataSelecionada.month - 1,
                    1,
                  );
                }
              });

              await carregarAgenda();
            },
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Center(
              child: Text(
                visualizacao == 'SEMANA'
                    ? '${dataBr(inicioSemana(dataSelecionada))} até ${dataBr(fimSemana(dataSelecionada))}'
                    : '${dataSelecionada.month.toString().padLeft(2, '0')}/${dataSelecionada.year}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              setState(() {
                if (visualizacao == 'SEMANA') {
                  dataSelecionada = dataSelecionada.add(
                    const Duration(days: 7),
                  );
                } else {
                  dataSelecionada = DateTime(
                    dataSelecionada.year,
                    dataSelecionada.month + 1,
                    1,
                  );
                }
              });

              await carregarAgenda();
            },
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget calendarioSemana() {
    final inicio = inicioSemana(dataSelecionada);
    final dias = List.generate(7, (index) => inicio.add(Duration(days: index)));

    return Column(
      children: dias.map((data) {
        final key = dataBr(data);
        final itens = agendaAgrupada[key] ?? [];
        final total = itens.where((i) => i.status != 'CANCELADO').length;
        final selected = dataSql(data) == dataSql(dataSelecionada);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.35)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.10),
                    child: Text(
                      data.day.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${diaSemana(data)} - ${dataBrCompleta(data)}',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: total > 0
                          ? AppColors.success.withOpacity(0.10)
                          : AppColors.textMuted.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      total > 0 ? '$total atend.' : 'Livre',
                      style: TextStyle(
                        color: total > 0
                            ? AppColors.success
                            : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (itens.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 46, bottom: 4),
                  child: Text(
                    'Nenhum horário agendado',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Column(
                  children: itens.map((item) {
                    return agendaCard(item);
                  }).toList(),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget legendaDiasSemana() {
    const dias = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

    return Row(
      children: dias.map((dia) {
        return Expanded(
          child: Center(
            child: Text(
              dia,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.textMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget calendarioMes() {
    final primeiroDia = DateTime(
      dataSelecionada.year,
      dataSelecionada.month,
      1,
    );
    final ultimoDia = DateTime(
      dataSelecionada.year,
      dataSelecionada.month + 1,
      0,
    );

    final diasAntes = primeiroDia.weekday - 1;
    final totalCelulas = diasAntes + ultimoDia.day;

    return Column(
      children: [
        legendaDiasSemana(),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCelulas,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (_, index) {
            if (index < diasAntes) {
              return const SizedBox();
            }

            final dia = index - diasAntes + 1;
            final data = DateTime(
              dataSelecionada.year,
              dataSelecionada.month,
              dia,
            );

            final total = quantidadeDoDia(data);
            final selected = dataSql(data) == dataSql(dataSelecionada);

            return InkWell(
              onTap: () async {
                setState(() {
                  dataSelecionada = data;
                  visualizacao = 'DIA';
                });

                await carregarAgenda();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.10)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    width: 0.6,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.border,
                  ),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        dia.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.textDark,
                        ),
                      ),
                    ),
                    if (total > 0)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 16,
                          constraints: const BoxConstraints(minWidth: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            total.toString(),
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget visualizacaoAgenda() {
    if (visualizacao == 'DIA') {
      return agrupamentoAgenda();
    }

    return Column(
      children: [
        cabecalhoCalendario(),
        const SizedBox(height: 10),
        if (visualizacao == 'SEMANA') calendarioSemana(),
        if (visualizacao == 'MES') calendarioMes(),
      ],
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
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  Row(
                    children: [
                      resumoCard(
                        label: 'Hoje',
                        total: totalDia,
                        icon: Icons.today_rounded,
                        color: primary,
                      ),
                      const SizedBox(width: 8),
                      resumoCard(
                        label: 'Semana',
                        total: totalSemana,
                        icon: Icons.view_week_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      resumoCard(
                        label: 'Mês',
                        total: totalMes,
                        icon: Icons.calendar_month_rounded,
                        color: AppColors.success,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 0.7),
                    ),
                    child: Row(
                      children: [
                        filtroVisualizacao('DIA', 'Dia'),
                        filtroVisualizacao('SEMANA', 'Semana'),
                        filtroVisualizacao('MES', 'Mês'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (visualizacao == 'DIA') ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: dias.map(diaChip).toList()),
                    ),
                    const SizedBox(height: 18),
                  ],

                  visualizacaoAgenda(),
                ],
              ),
      ),
    );
  }
}
