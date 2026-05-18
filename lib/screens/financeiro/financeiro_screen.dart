import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/cliente_model.dart';
import '../../models/ordem_servico_model.dart';
import '../../models/pagamento_model.dart';
import '../../widgets/app_scaffold.dart';
import '../ordens/ordem_form_screen.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  bool loading = true;

  String filtroPeriodo = 'MES_ATUAL';
  String busca = '';

  List<OrdemServicoModel> ordens = [];
  List<ClienteModel> clientes = [];
  List<PagamentoModel> pagamentos = [];

  double recebido = 0;
  double pendente = 0;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    setState(() => loading = true);

    final resumo = await AppDatabase.instance.resumoFinanceiro();

    ordens = await AppDatabase.instance.listarOrdensServico();
    clientes = await AppDatabase.instance.listarClientes();
    pagamentos = await AppDatabase.instance.listarPagamentos();

    recebido = resumo['recebido'] ?? 0;
    pendente = resumo['pendente'] ?? 0;

    if (mounted) {
      setState(() => loading = false);
    }
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  double parseValor(String value) {
    return double.tryParse(
          value
              .replaceAll('R\$', '')
              .replaceAll('.', '')
              .replaceAll(',', '.')
              .trim(),
        ) ??
        0;
  }

  OrdemServicoModel? buscarOrdem(int ordemId) {
    try {
      return ordens.firstWhere((o) => o.id == ordemId);
    } catch (_) {
      return null;
    }
  }

  ClienteModel? buscarCliente(int? clienteId) {
    if (clienteId == null) return null;

    try {
      return clientes.firstWhere((c) => c.id == clienteId);
    } catch (_) {
      return null;
    }
  }

  List<PagamentoModel> get pagamentosFiltrados {
    final agora = DateTime.now();

    return pagamentos.where((pagamento) {
      final data = DateTime.tryParse(pagamento.dataPagamento);
      if (data == null) return false;

      bool periodoOk = true;

      if (filtroPeriodo == 'HOJE') {
        periodoOk =
            data.year == agora.year &&
            data.month == agora.month &&
            data.day == agora.day;
      }

      if (filtroPeriodo == 'MES_ATUAL') {
        periodoOk = data.year == agora.year && data.month == agora.month;
      }

      if (filtroPeriodo == 'MES_ANTERIOR') {
        final mesAnterior = DateTime(agora.year, agora.month - 1, 1);
        periodoOk =
            data.year == mesAnterior.year && data.month == mesAnterior.month;
      }

      if (filtroPeriodo == 'TODOS') {
        periodoOk = true;
      }

      final ordem = buscarOrdem(pagamento.ordemServicoId);
      final cliente = buscarCliente(ordem?.clienteId);

      final textoBusca = [
        pagamento.formaPagamento,
        pagamento.observacoes,
        ordem?.titulo ?? '',
        ordem?.id?.toString() ?? '',
        cliente?.nome ?? '',
      ].join(' ').toLowerCase();

      final buscaOk =
          busca.trim().isEmpty || textoBusca.contains(busca.toLowerCase());

      return periodoOk && buscaOk;
    }).toList();
  }

  double get recebidoFiltrado {
    return pagamentosFiltrados.fold(0, (total, p) => total + p.valor);
  }

  List<OrdemServicoModel> get ordensPendentes {
    return ordens.where((ordem) {
      return ordem.valorPendente > 0 && ordem.status != 'CANCELADO';
    }).toList();
  }

  Future<void> abrirOrdem(OrdemServicoModel ordem) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrdemFormScreen(ordem: ordem)),
    );

    carregarDados();
  }

  Future<void> abrirRegistrarPagamento(OrdemServicoModel ordem) async {
    final valorController = TextEditingController(
      text: ordem.valorPendente.toStringAsFixed(2),
    );

    final observacoesController = TextEditingController();

    String formaPagamento = 'PIX';
    bool salvando = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 22,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                    'Registrar pagamento',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'OS #${ordem.id} • ${ordem.titulo}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: valorController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Valor pago',
                      filled: true,
                      fillColor: AppColors.background,
                      prefixIcon: const Icon(Icons.payments_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: formaPagamento,
                    decoration: InputDecoration(
                      labelText: 'Forma de pagamento',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'PIX', child: Text('Pix')),
                      DropdownMenuItem(
                        value: 'DINHEIRO',
                        child: Text('Dinheiro'),
                      ),
                      DropdownMenuItem(value: 'CARTAO', child: Text('Cartão')),
                      DropdownMenuItem(value: 'BOLETO', child: Text('Boleto')),
                      DropdownMenuItem(value: 'OUTRO', child: Text('Outro')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => formaPagamento = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: observacoesController,
                    decoration: InputDecoration(
                      labelText: 'Observações',
                      filled: true,
                      fillColor: AppColors.background,
                      prefixIcon: const Icon(Icons.notes_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: salvando
                          ? null
                          : () async {
                              final valor = parseValor(valorController.text);

                              if (valor <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Informe um valor válido'),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => salvando = true);

                              final agora = DateTime.now().toIso8601String();

                              await AppDatabase.instance.criarPagamento(
                                PagamentoModel(
                                  ordemServicoId: ordem.id!,
                                  valor: valor,
                                  formaPagamento: formaPagamento,
                                  status: 'PAGO',
                                  dataPagamento: agora,
                                  observacoes: observacoesController.text
                                      .trim(),
                                  createdAt: agora,
                                ),
                              );

                              if (mounted) {
                                Navigator.pop(context);
                                carregarDados();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: salvando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Text(
                              'Salvar pagamento',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    valorController.dispose();
    observacoesController.dispose();
  }

  Widget resumoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 106,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 25),
            const Spacer(),
            Text(
              value,
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
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget filtroChip(String value, String label) {
    final selected = filtroPeriodo == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary.withOpacity(0.12),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textMuted,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      onSelected: (_) {
        setState(() => filtroPeriodo = value);
      },
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Financeiro',
      subtitle: 'Recebimentos',
      currentIndex: 3,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregarDados,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  Row(
                    children: [
                      resumoCard(
                        title: 'Recebido no filtro',
                        value: dinheiro(recebidoFiltrado),
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      resumoCard(
                        title: 'Pendente geral',
                        value: dinheiro(pendente),
                        icon: Icons.schedule_rounded,
                        color: AppColors.warning,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        filtroChip('HOJE', 'Hoje'),
                        const SizedBox(width: 8),
                        filtroChip('MES_ATUAL', 'Este mês'),
                        const SizedBox(width: 8),
                        filtroChip('MES_ANTERIOR', 'Mês anterior'),
                        const SizedBox(width: 8),
                        filtroChip('TODOS', 'Todos'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    onChanged: (value) {
                      setState(() => busca = value);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Buscar por cliente, OS ou pagamento',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  sectionTitle('Aguardando pagamento'),

                  if (ordensPendentes.isEmpty)
                    const Text(
                      'Nenhuma ordem pendente',
                      style: TextStyle(color: AppColors.textMuted),
                    )
                  else
                    ...ordensPendentes.map((ordem) {
                      final cliente = buscarCliente(ordem.clienteId);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          onTap: () => abrirOrdem(ordem),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.warning.withOpacity(
                              0.12,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.warning,
                            ),
                          ),
                          title: Text(
                            'OS #${ordem.id} • ${ordem.titulo}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          subtitle: Text(
                            '${cliente?.nome ?? 'Cliente não informado'}\nPendente: ${dinheiro(ordem.valorPendente)}',
                          ),
                          isThreeLine: true,
                          trailing: ElevatedButton(
                            onPressed: () => abrirRegistrarPagamento(ordem),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Pagar'),
                          ),
                        ),
                      );
                    }),

                  sectionTitle('Pagamentos'),

                  if (pagamentosFiltrados.isEmpty)
                    const Text(
                      'Nenhum pagamento encontrado',
                      style: TextStyle(color: AppColors.textMuted),
                    )
                  else
                    ...pagamentosFiltrados.take(80).map((pagamento) {
                      final ordem = buscarOrdem(pagamento.ordemServicoId);
                      final cliente = buscarCliente(ordem?.clienteId);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          onTap: ordem == null ? null : () => abrirOrdem(ordem),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.success.withOpacity(
                              0.12,
                            ),
                            child: const Icon(
                              Icons.payments_rounded,
                              color: AppColors.success,
                            ),
                          ),
                          title: Text(
                            dinheiro(pagamento.valor),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          subtitle: Text(
                            '${cliente?.nome ?? 'Cliente não informado'} • OS #${pagamento.ordemServicoId}\n${pagamento.formaPagamento}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          isThreeLine: true,
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: AppColors.navInactive,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
