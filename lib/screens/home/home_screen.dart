import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/agenda_model.dart';
import '../../models/cliente_model.dart';
import '../../widgets/app_scaffold.dart';
import '../agenda/agenda_form_screen.dart';
import '../anamnese/anamnese_form_screen.dart';
import '../atendimentos/atendimento_screen.dart';
import '../atendimentos/historico_screen.dart';
import '../clientes/cliente_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loading = true;

  List<ClienteModel> clientes = [];
  List<AgendaModel> agendaHoje = [];

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    if (mounted) {
      setState(() => loading = true);
    }

    final alunos = await AppDatabase.instance.listarClientes();
    final agenda = await AppDatabase.instance.listarAgendaDoDiaComRecorrencia(
      DateTime.now(),
    );

    agenda.sort((a, b) => a.horaInicio.compareTo(b.horaInicio));

    if (!mounted) return;

    setState(() {
      clientes = alunos;
      agendaHoje = agenda;
      loading = false;
    });
  }

  List<AgendaModel> get agendaAtiva {
    return agendaHoje
        .where((item) => item.status != 'CANCELADO' && item.status != 'FALTOU')
        .toList();
  }

  int get totalConcluidos {
    return agendaHoje.where((item) => item.status == 'CONCLUIDO').length;
  }

  int get totalEmAndamento {
    return agendaHoje.where((item) => item.status == 'EM_ANDAMENTO').length;
  }

  int get totalPendentes {
    return agendaAtiva
        .where(
          (item) => item.status != 'CONCLUIDO' && item.status != 'EM_ANDAMENTO',
        )
        .length;
  }

  AgendaModel? get proximoAtendimento {
    final abertos = agendaAtiva
        .where((item) => item.status != 'CONCLUIDO')
        .toList();

    if (abertos.isEmpty) return null;

    final agora = DateTime.now().subtract(const Duration(minutes: 5));

    for (final item in abertos) {
      final horario = horarioHoje(item.horaInicio);

      if (horario == null || !horario.isBefore(agora)) {
        return item;
      }
    }

    return abertos.first;
  }

  DateTime? horarioHoje(String hora) {
    final partes = hora.split(':');
    if (partes.length < 2) return null;

    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);

    if (h == null || m == null) return null;

    final hoje = DateTime.now();
    return DateTime(hoje.year, hoje.month, hoje.day, h, m);
  }

  ClienteModel? clienteDoAgendamento(AgendaModel item) {
    if (item.clienteId == null) return null;

    try {
      return clientes.firstWhere((cliente) => cliente.id == item.clienteId);
    } catch (_) {
      return null;
    }
  }

  String dataHojeLabel() {
    final hoje = DateTime.now();
    const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    const meses = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];

    return '${dias[hoje.weekday - 1]}, ${hoje.day} ${meses[hoje.month - 1]}';
  }

  String horarioAgenda(AgendaModel item) {
    if (item.horaFim.isEmpty) return item.horaInicio;
    return '${item.horaInicio} - ${item.horaFim}';
  }

  String statusLabel(String status) {
    switch (status) {
      case 'EM_ANDAMENTO':
        return 'Em andamento';
      case 'CONCLUIDO':
        return 'Finalizado';
      case 'CANCELADO':
        return 'Cancelado';
      case 'FALTOU':
        return 'Faltou';
      default:
        return 'Agendado';
    }
  }

  Color statusColor(String status) {
    final primary = Theme.of(context).colorScheme.primary;

    switch (status) {
      case 'EM_ANDAMENTO':
        return primary;
      case 'CONCLUIDO':
        return AppColors.success;
      case 'CANCELADO':
        return AppColors.danger;
      case 'FALTOU':
        return AppColors.textMuted;
      default:
        return AppColors.warning;
    }
  }

  Future<void> iniciarFluxo() async {
    final proximo = proximoAtendimento;
    final opcao = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 18),
                const Text(
                  'Rotina do atendimento',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Comece pelo proximo aluno ou escolha outro caminho rapido.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                if (proximo != null)
                  _stepTile(
                    step: '1',
                    icon: Icons.play_arrow_rounded,
                    title: 'Iniciar proximo atendimento',
                    subtitle:
                        '${clienteDoAgendamento(proximo)?.nome ?? 'Aluno nao informado'} - ${horarioAgenda(proximo)}',
                    onTap: () => Navigator.pop(context, 'proximo'),
                  ),
                _stepTile(
                  step: proximo == null ? '1' : '2',
                  icon: Icons.person_search_rounded,
                  title: 'Selecionar aluno',
                  subtitle: clientes.isEmpty
                      ? 'Nenhum aluno cadastrado ainda'
                      : 'Continuar com um aluno existente',
                  enabled: clientes.isNotEmpty,
                  onTap: () => Navigator.pop(context, 'selecionar'),
                ),
                _stepTile(
                  step: proximo == null ? '2' : '3',
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Cadastrar aluno',
                  subtitle: 'Criar cadastro, anamnese e agenda',
                  onTap: () => Navigator.pop(context, 'cadastrar'),
                ),
                _stepTile(
                  step: proximo == null ? '3' : '4',
                  icon: Icons.calendar_month_rounded,
                  title: 'Agendar aula',
                  subtitle: 'Criar horario sem sair do fluxo',
                  onTap: () => Navigator.pop(context, 'agenda'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    switch (opcao) {
      case 'proximo':
        if (proximo != null) {
          await abrirAtendimento(proximo);
        }
        break;
      case 'cadastrar':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClienteFormScreen()),
        );
        break;
      case 'selecionar':
        final aluno = await selecionarAluno();
        if (!mounted) return;
        if (aluno != null) {
          await mostrarAcoesDoAluno(aluno);
        }
        break;
      case 'agenda':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AgendaFormScreen()),
        );
        break;
    }

    await carregarDados();
  }

  Future<ClienteModel?> selecionarAluno() async {
    return showModalBottomSheet<ClienteModel>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              child: Column(
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 18),
                  const Text(
                    'Selecionar aluno',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.builder(
                      itemCount: clientes.length,
                      itemBuilder: (_, index) {
                        final aluno = clientes[index];

                        return _studentTile(
                          aluno: aluno,
                          onTap: () => Navigator.pop(context, aluno),
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
  }

  Future<void> abrirAtendimento(AgendaModel item) async {
    final aluno = clienteDoAgendamento(item);

    if (aluno == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AgendaFormScreen(agenda: item)),
      );
      return;
    }

    final acao = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 18),
                Text(
                  aluno.nome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${horarioAgenda(item)} - ${item.titulo}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _stepTile(
                  step: '1',
                  icon: Icons.play_arrow_rounded,
                  title: 'Iniciar atendimento',
                  subtitle: 'Cronometrar e registrar observacoes',
                  onTap: () => Navigator.pop(context, 'atendimento'),
                ),
                _stepTile(
                  step: '2',
                  icon: Icons.calendar_month_rounded,
                  title: 'Editar agendamento',
                  subtitle: 'Ajustar horario, status ou observacoes',
                  onTap: () => Navigator.pop(context, 'agenda'),
                ),
                _stepTile(
                  step: '3',
                  icon: Icons.badge_rounded,
                  title: 'Perfil completo',
                  subtitle: 'Dados, historico e proximos passos',
                  onTap: () => Navigator.pop(context, 'perfil'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || acao == null) return;

    if (acao == 'atendimento') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AtendimentoScreen(aluno: aluno, agenda: item),
        ),
      );
    } else if (acao == 'agenda') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AgendaFormScreen(agenda: item)),
      );
    } else {
      await abrirAcao(aluno, acao);
    }
  }

  Future<void> mostrarAcoesDoAluno(ClienteModel aluno) async {
    final acao = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 18),
                Text(
                  aluno.nome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'O que voce vai fazer agora?',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _stepTile(
                  step: '1',
                  icon: Icons.play_arrow_rounded,
                  title: 'Iniciar atendimento',
                  subtitle: 'Cronometro, treino realizado e observacoes',
                  onTap: () => Navigator.pop(context, 'atendimento'),
                ),
                _stepTile(
                  step: '2',
                  icon: Icons.calendar_month_rounded,
                  title: 'Agendar aula',
                  subtitle: 'Definir data, horario e recorrencia',
                  onTap: () => Navigator.pop(context, 'agenda'),
                ),
                _stepTile(
                  step: '3',
                  icon: Icons.assignment_ind_rounded,
                  title: 'Anamnese',
                  subtitle: 'Registrar objetivo, lesoes e restricoes',
                  onTap: () => Navigator.pop(context, 'anamnese'),
                ),
                _stepTile(
                  step: '4',
                  icon: Icons.history_rounded,
                  title: 'Historico',
                  subtitle: 'Ver atendimentos anteriores',
                  onTap: () => Navigator.pop(context, 'historico'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || acao == null) return;

    await abrirAcao(aluno, acao);
    await carregarDados();
  }

  Future<void> abrirAcao(ClienteModel aluno, String acao) async {
    switch (acao) {
      case 'atendimento':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AtendimentoScreen(aluno: aluno)),
        );
        break;
      case 'agenda':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AgendaFormScreen(alunoInicial: aluno),
          ),
        );
        break;
      case 'anamnese':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnamneseFormScreen(alunoInicial: aluno),
          ),
        );
        break;
      case 'perfil':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClienteFormScreen(cliente: aluno)),
        );
        break;
      case 'historico':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistoricoScreen(alunoInicial: aluno),
          ),
        );
        break;
    }
  }

  Widget _sheetHandle() {
    return Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _heroCard() {
    final next = proximoAtendimento;
    final aluno = next == null ? null : clienteDoAgendamento(next);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B3F9E), Color(0xFF1464D9)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3F9E).withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.gold,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dataHojeLabel(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.gold.withValues(alpha: 0.95),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            next == null ? 'Agenda pronta' : 'Proximo atendimento',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            next == null ? 'Comece pelo aluno certo' : aluno?.nome ?? 'Aluno',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            next == null
                ? 'Escolha um aluno, cadastre um novo ou crie um agendamento.'
                : '${horarioAgenda(next)} - ${next.titulo}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 190,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: loading ? null : iniciarFluxo,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Iniciar rotina',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1557C0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsRow() {
    return Row(
      children: [
        _metricCard(
          label: 'Hoje',
          value: agendaAtiva.length.toString(),
          icon: Icons.event_available_rounded,
        ),
        const SizedBox(width: 10),
        _metricCard(
          label: 'Em andamento',
          value: totalEmAndamento.toString(),
          icon: Icons.timer_rounded,
        ),
        const SizedBox(width: 10),
        _metricCard(
          label: 'Pendentes',
          value: totalPendentes.toString(),
          icon: Icons.pending_actions_rounded,
        ),
      ],
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final accent = switch (label) {
      'Em andamento' => const Color(0xFFF59E0B),
      'Pendentes' => const Color(0xFF22A447),
      _ => const Color(0xFF2563EB),
    };

    return Expanded(
      child: Container(
        height: 116,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: accent, size: 19),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {String? action, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onTap,
              child: Text(
                action,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
        ],
      ),
    );
  }

  Widget _modulesCarousel() {
    final items = <({IconData icon, String label, String route, Color color})>[
      (
        icon: Icons.people_alt_rounded,
        label: 'Alunos',
        route: '/clientes',
        color: const Color(0xFF2563EB),
      ),
      (
        icon: Icons.calendar_month_rounded,
        label: 'Agenda',
        route: '/agenda',
        color: const Color(0xFF7C3AED),
      ),
      (
        icon: Icons.fitness_center_rounded,
        label: 'Treinos',
        route: '/treinos',
        color: const Color(0xFFF59E0B),
      ),
      (
        icon: Icons.assignment_ind_rounded,
        label: 'Avaliacoes',
        route: '/anamnese',
        color: const Color(0xFF22A447),
      ),
      (
        icon: Icons.sports_gymnastics_rounded,
        label: 'Exercicios',
        route: '/exercicios',
        color: const Color(0xFFEC4899),
      ),
      (
        icon: Icons.chat_bubble_rounded,
        label: 'Mensagens',
        route: '/mensagens-whatsapp',
        color: const Color(0xFF2563EB),
      ),
      (
        icon: Icons.add_location_alt_rounded,
        label: 'Locais',
        route: '/locais-atendimento',
        color: const Color(0xFF0EA5E9),
      ),
      (
        icon: Icons.notifications_active_rounded,
        label: 'Lembretes',
        route: '/lembretes',
        color: const Color(0xFFEF4444),
      ),
      (
        icon: Icons.payments_rounded,
        label: 'Financeiro',
        route: '/financeiro',
        color: const Color(0xFF16A34A),
      ),
      (
        icon: Icons.storefront_rounded,
        label: 'Perfil',
        route: '/empresa',
        color: const Color(0xFF6366F1),
      ),
      (
        icon: Icons.palette_rounded,
        label: 'Aparencia',
        route: '/aparencia',
        color: const Color(0xFFD946EF),
      ),
      (
        icon: Icons.backup_rounded,
        label: 'Backup',
        route: '/backup',
        color: const Color(0xFF64748B),
      ),
      (
        icon: Icons.support_agent_rounded,
        label: 'Suporte',
        route: '/suporte',
        color: const Color(0xFF0891B2),
      ),
    ];

    return Container(
      height: 94,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        itemCount: items.length,
        separatorBuilder: (_, _) => Container(
          width: 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: AppColors.border,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => Navigator.pushNamed(context, item.route),
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 76,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: item.color, size: 27),
                  const SizedBox(height: 7),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _quickActions() {
    return Column(
      children: [
        Row(
          children: [
            _shortcutCard(
              icon: Icons.person_add_alt_1_rounded,
              title: 'Novo aluno',
              subtitle: 'Cadastro guiado',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClienteFormScreen()),
                );
                await carregarDados();
              },
            ),
            const SizedBox(width: 10),
            _shortcutCard(
              icon: Icons.assignment_ind_rounded,
              title: 'Avaliacoes',
              subtitle: 'Saude e objetivo',
              onTap: () => Navigator.pushNamed(context, '/anamnese'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _shortcutCard(
              icon: Icons.fitness_center_rounded,
              title: 'Novo treino',
              subtitle: 'Criar treino',
              onTap: () => Navigator.pushNamed(context, '/treinos'),
            ),
            const SizedBox(width: 10),
            _shortcutCard(
              icon: Icons.history_rounded,
              title: 'Historico',
              subtitle: 'Atendimentos',
              onTap: () => Navigator.pushNamed(context, '/historico'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _shortcutCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.navInactive,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _agendaList() {
    final itens = agendaAtiva.take(5).toList();

    if (itens.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(height: 10),
            const Text(
              'Nenhuma aula agendada hoje',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Use iniciar para cadastrar, selecionar aluno ou agendar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(children: itens.map(_agendaTile).toList());
  }

  Widget _agendaTile(AgendaModel item) {
    final aluno = clienteDoAgendamento(item);
    final color = statusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: () async {
          await abrirAtendimento(item);
          await carregarDados();
        },
        leading: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            item.horaInicio.isEmpty ? '--:--' : item.horaInicio,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        title: Text(
          aluno?.nome ?? item.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          '${statusLabel(item.status)} - ${item.horaFim.isEmpty ? item.titulo : horarioAgenda(item)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: AppColors.navInactive,
          size: 14,
        ),
      ),
    );
  }

  Widget _studentTile({
    required ClienteModel aluno,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: primary.withValues(alpha: 0.10),
          child: Icon(Icons.person_rounded, color: primary),
        ),
        title: Text(
          aluno.nome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          aluno.telefone.isEmpty ? 'Sem telefone' : aluno.telefone,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.navInactive,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _stepTile({
    required String step,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          enabled: enabled,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: primary.withValues(alpha: 0.10),
            child: Text(
              step,
              style: TextStyle(color: primary, fontWeight: FontWeight.w900),
            ),
          ),
          title: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: enabled ? primary : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.navInactive,
          ),
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Personal Trainer',
      subtitle: 'Central do dia',
      currentIndex: 0,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregarDados,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _heroCard(),
                  const SizedBox(height: 14),
                  _metricsRow(),
                  const SizedBox(height: 20),
                  _modulesCarousel(),
                  const SizedBox(height: 24),
                  _sectionHeader('Rotina rapida'),
                  _quickActions(),
                  const SizedBox(height: 20),
                  _sectionHeader(
                    'Agenda de hoje',
                    action: 'Ver agenda',
                    onTap: () => Navigator.pushNamed(context, '/agenda'),
                  ),
                  _agendaList(),
                  if (totalConcluidos > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '$totalConcluidos atendimento(s) concluido(s) hoje',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
