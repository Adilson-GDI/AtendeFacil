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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loading = true;

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
        .where((o) {
          return o.status != 'PAGO' && o.status != 'CANCELADO';
        })
        .take(5)
        .toList();
  }

  List<ProdutoModel> get estoqueBaixo {
    return produtos
        .where((p) {
          return p.estoqueAtual <= 3 && p.ativo == 1;
        })
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
    final secondary = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: AppColors.success,
              icon: Icons.check_circle_rounded,
            ),
          ),
          Container(width: 1.5, height: 58, color: secondary),
          Expanded(
            child: _miniFinanceiro(
              title: 'Pendente',
              value: dinheiro(pendente),
              color: AppColors.warning,
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
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 112,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget metricCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 90,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
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
                      fontWeight: FontWeight.w600,
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

  Widget sectionTitle(String title, {VoidCallback? onTap}) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (onTap != null)
            InkWell(
              onTap: onTap,
              child: Text(
                'Ver tudo',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AgendaFormScreen(agenda: item)),
          );
          carregarDados();
        },
        leading: CircleAvatar(
          backgroundColor: cor.withOpacity(0.12),
          child: Icon(Icons.event_available_rounded, color: cor),
        ),
        title: Text(
          item.titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          '${item.horaInicio} - ${item.horaFim.isEmpty ? '--:--' : item.horaFim} • ${item.status}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 15,
          color: AppColors.navInactive,
        ),
      ),
    );
  }

  Widget ordemCard(OrdemServicoModel ordem) {
    final cor = corStatus(ordem.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrdemFormScreen(ordem: ordem)),
          );
          carregarDados();
        },
        leading: CircleAvatar(
          backgroundColor: cor.withOpacity(0.12),
          child: Icon(Icons.assignment_rounded, color: cor),
        ),
        title: Text(
          'OS #${ordem.id} • ${ordem.titulo}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          '${labelStatus(ordem.status)} • ${dinheiro(ordem.total)}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 15,
          color: AppColors.navInactive,
        ),
      ),
    );
  }

  Widget estoqueCard(ProdutoModel produto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.danger.withOpacity(0.12),
          child: const Icon(Icons.inventory_2_rounded, color: AppColors.danger),
        ),
        title: Text(
          produto.nome,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          'Estoque: ${produto.estoqueAtual.toStringAsFixed(0)} ${produto.unidade}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return AppScaffold(
      title: 'Atende Fácil',
      subtitle: 'Painel do negócio',
      currentIndex: 0,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregarDados,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  topCard(),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      actionCard(
                        icon: Icons.note_add_rounded,
                        title: 'Nova OS',
                        subtitle: 'Criar serviço',
                        color: primary,
                        onTap: novaOrdem,
                      ),
                      const SizedBox(width: 12),
                      actionCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'Agenda',
                        subtitle: 'Agendar',
                        color: AppColors.warning,
                        onTap: novoAgendamento,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      actionCard(
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'Cliente',
                        subtitle: 'Novo cadastro',
                        color: secondary,
                        onTap: novoCliente,
                      ),
                      const SizedBox(width: 12),
                      actionCard(
                        icon: Icons.payments_rounded,
                        title: 'Financeiro',
                        subtitle: 'Receber',
                        color: AppColors.success,
                        onTap: () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/financeiro',
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      actionCard(
                        icon: Icons.inventory_2_rounded,
                        title: 'Produtos',
                        subtitle: 'Estoque',
                        color: const Color(0xFF4F46E5),
                        onTap: () {
                          Navigator.pushNamed(context, '/produtos');
                        },
                      ),
                      const SizedBox(width: 12),
                      actionCard(
                        icon: Icons.settings_rounded,
                        title: 'Mais',
                        subtitle: 'Configurações',
                        color: AppColors.textMuted,
                        onTap: () {
                          Navigator.pushNamed(context, '/configuracoes');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      metricCard(
                        value: clientes.length.toString(),
                        label: 'Clientes',
                        icon: Icons.people_alt_rounded,
                        color: primary,
                      ),
                      const SizedBox(width: 12),
                      metricCard(
                        value: ordensAbertas.length.toString(),
                        label: 'OS abertas',
                        icon: Icons.assignment_rounded,
                        color: AppColors.warning,
                      ),
                    ],
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
                      style: TextStyle(color: AppColors.textMuted),
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
                      style: TextStyle(color: AppColors.textMuted),
                    )
                  else
                    ...ordensAbertas.map(ordemCard),

                  sectionTitle('Estoque baixo'),

                  if (estoqueBaixo.isEmpty)
                    const Text(
                      'Nenhum produto com estoque baixo',
                      style: TextStyle(color: AppColors.textMuted),
                    )
                  else
                    ...estoqueBaixo.map(estoqueCard),
                ],
              ),
            ),
    );
  }
}
