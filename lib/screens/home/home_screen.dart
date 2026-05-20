import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/agenda_model.dart';
import '../../models/cliente_model.dart';
import '../../models/ordem_servico_model.dart';
import '../../models/produto_model.dart';
import '../../widgets/app_scaffold.dart';
import '../agenda/agenda_form_screen.dart';
import '../clientes/cliente_form_screen.dart';
import '../ordens/ordem_form_screen.dart';
import '../../core/tipo_servico_app.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loading = true;
  String tipoServico = TipoServicoApp.geral;

  List<ClienteModel> clientes = [];
  List<OrdemServicoModel> ordens = [];
  List<ProdutoModel> produtos = [];
  List<AgendaModel> agendaHoje = [];

  double recebido = 0;
  double pendente = 0;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  String dataSql(DateTime data) {
    return '${data.year.toString().padLeft(4, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }

  Future<void> carregarDados() async {
    setState(() => loading = true);

    tipoServico = await AppDatabase.instance.buscarTipoServicoApp();
    clientes = await AppDatabase.instance.listarClientes();
    ordens = await AppDatabase.instance.listarOrdensServico();
    produtos = await AppDatabase.instance.listarProdutos();
    agendaHoje = await AppDatabase.instance.listarAgendaPorData(
      dataSql(DateTime.now()),
    );

    final resumo = await AppDatabase.instance.resumoFinanceiro();
    recebido = resumo['recebido'] ?? 0;
    pendente = resumo['pendente'] ?? 0;

    if (mounted) {
      setState(() => loading = false);
    }
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  List<OrdemServicoModel> get ordensAbertas {
    return ordens
        .where((o) => o.status != 'PAGO' && o.status != 'CANCELADO')
        .take(5)
        .toList();
  }

  List<ProdutoModel> get estoqueBaixo {
    return produtos
        .where((p) => p.estoqueAtual <= 3 && p.ativo == 1)
        .take(5)
        .toList();
  }

  Future<void> novaOrdem() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrdemFormScreen()),
    );
    carregarDados();
  }

  Future<void> novoCliente() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClienteFormScreen()),
    );
    carregarDados();
  }

  Future<void> novoAgendamento() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AgendaFormScreen()),
    );
    carregarDados();
  }

  Widget topCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _miniFinanceiro(
              title: 'Recebido',
              value: dinheiro(recebido),
              icon: Icons.trending_up_rounded,
            ),
          ),
          Container(width: 1, height: 46, color: AppColors.border),
          Expanded(
            child: _miniFinanceiro(
              title: 'Pendente',
              value: dinheiro(pendente),
              icon: Icons.schedule_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniFinanceiro({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primary, size: 18),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget actionSmall({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 96,
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primary.withOpacity(0.80), size: 21),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget metricCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      height: 70,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 22),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title, {VoidCallback? onTap}) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
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
          if (onTap != null)
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'Ver tudo',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color corStatus(String status) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    switch (status) {
      case 'PAGO':
        return AppColors.success;
      case 'CONCLUIDO':
        return primary;
      case 'AGUARDANDO_PAGAMENTO':
        return AppColors.warning;
      case 'CANCELADO':
        return AppColors.danger;
      default:
        return secondary;
    }
  }

  String labelStatus(String status) {
    switch (status) {
      case 'ORCAMENTO':
        return 'Orçamento';
      case 'APROVADO':
        return 'Aprovado';
      case 'EM_ANDAMENTO':
        return 'Em andamento';
      case 'CONCLUIDO':
        return 'Concluído';
      case 'AGUARDANDO_PAGAMENTO':
        return 'Aguardando pagamento';
      case 'PAGO':
        return 'Pago';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Widget agendaCard(AgendaModel item) {
    Color cor = AppColors.warning;

    if (item.status == 'CONCLUIDO') cor = AppColors.success;
    if (item.status == 'CANCELADO') cor = AppColors.danger;
    if (item.status == 'FALTOU') cor = AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AgendaFormScreen(agenda: item)),
          );
          carregarDados();
        },
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: cor.withOpacity(0.10),
          child: Icon(Icons.event_available_rounded, color: cor, size: 18),
        ),
        title: Text(
          item.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          '${item.horaInicio} - ${item.horaFim.isEmpty ? '--:--' : item.horaFim} • ${item.status}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 13,
          color: AppColors.navInactive,
        ),
      ),
    );
  }

  Widget ordemCard(OrdemServicoModel ordem) {
    final cor = corStatus(ordem.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrdemFormScreen(ordem: ordem)),
          );
          carregarDados();
        },
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: cor.withOpacity(0.10),
          child: Icon(Icons.assignment_rounded, color: cor, size: 18),
        ),
        title: Text(
          'OS #${ordem.id} • ${ordem.titulo}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          '${labelStatus(ordem.status)} • ${dinheiro(ordem.total)}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 13,
          color: AppColors.navInactive,
        ),
      ),
    );
  }

  Widget estoqueCard(ProdutoModel produto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.danger.withOpacity(0.10),
          child: const Icon(
            Icons.inventory_2_rounded,
            color: AppColors.danger,
            size: 18,
          ),
        ),
        title: Text(
          produto.nome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          'Estoque: ${produto.estoqueAtual.toStringAsFixed(0)} ${produto.unidade}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Atende Fácil',
      subtitle: 'Painel do negócio',
      currentIndex: 0,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregarDados,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  topCard(),

                  const SizedBox(height: 14),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      actionSmall(
                        icon: Icons.note_add_rounded,
                        title: 'Nova OS',
                        onTap: novaOrdem,
                      ),
                      actionSmall(
                        icon: Icons.calendar_month_rounded,
                        title: 'Agenda',
                        onTap: novoAgendamento,
                      ),
                      actionSmall(
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'Cliente',
                        onTap: novoCliente,
                      ),
                      actionSmall(
                        icon: Icons.payments_rounded,
                        title: 'Financeiro',
                        onTap: () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/financeiro',
                          );
                        },
                      ),
                      if (tipoServico == TipoServicoApp.personalTrainer ||
                          tipoServico == TipoServicoApp.fisioterapeuta)
                        actionSmall(
                          icon: Icons.fitness_center_rounded,
                          title: 'Treinos',
                          onTap: () {
                            Navigator.pushNamed(context, '/treinos');
                          },
                        ),

                      if (tipoServico == TipoServicoApp.personalTrainer ||
                          tipoServico == TipoServicoApp.fisioterapeuta)
                        actionSmall(
                          icon: Icons.assignment_ind_rounded,
                          title: 'Anamnese',
                          onTap: () {
                            Navigator.pushNamed(context, '/anamnese');
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  metricCard(
                    value: ordensAbertas.length.toString(),
                    label: 'OS abertas',
                    icon: Icons.assignment_rounded,
                  ),

                  sectionTitle(
                    'Agenda de hoje',
                    onTap: () {
                      Navigator.pushNamed(context, '/agenda');
                    },
                  ),

                  if (agendaHoje.isEmpty)
                    const Text(
                      'Nenhum atendimento agendado para hoje',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    )
                  else
                    ...agendaHoje.take(4).map(agendaCard),

                  sectionTitle(
                    'Ordens em andamento',
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/ordens');
                    },
                  ),

                  if (ordensAbertas.isEmpty)
                    const Text(
                      'Nenhuma ordem em andamento',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    )
                  else
                    ...ordensAbertas.map(ordemCard),

                  sectionTitle('Estoque baixo'),

                  if (estoqueBaixo.isEmpty)
                    const Text(
                      'Nenhum produto com estoque baixo',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    )
                  else
                    ...estoqueBaixo.map(estoqueCard),
                ],
              ),
            ),
    );
  }
}
