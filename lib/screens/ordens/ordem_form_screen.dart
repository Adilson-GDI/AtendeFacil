import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../core/money_utils.dart';
import '../../database/app_database.dart';
import '../../models/cliente_model.dart';
import '../../models/ordem_servico_item_model.dart';
import '../../models/ordem_servico_model.dart';
import '../../models/produto_model.dart';
import '../../models/servico_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_scaffold.dart';

class OrdemFormScreen extends StatefulWidget {
  final OrdemServicoModel? ordem;

  const OrdemFormScreen({super.key, this.ordem});

  @override
  State<OrdemFormScreen> createState() => _OrdemFormScreenState();
}

class _OrdemFormScreenState extends State<OrdemFormScreen> {
  final formKey = GlobalKey<FormState>();

  final tituloController = TextEditingController();
  final descricaoController = TextEditingController();
  final descontoController = TextEditingController(text: '0');
  final acrescimoController = TextEditingController(text: '0');
  final observacoesController = TextEditingController();

  List<ClienteModel> clientes = [];
  List<ServicoModel> servicos = [];
  List<ProdutoModel> produtos = [];
  List<OrdemServicoItemModel> itens = [];

  int? clienteId;
  String status = 'ORCAMENTO';
  bool loading = true;
  bool salvando = false;

  bool get editando => widget.ordem != null;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    tituloController.dispose();
    descricaoController.dispose();
    descontoController.dispose();
    acrescimoController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    clientes = await AppDatabase.instance.listarClientes();
    servicos = await AppDatabase.instance.listarServicos();
    produtos = await AppDatabase.instance.listarProdutos();

    if (editando) {
      final ordem = widget.ordem!;

      clienteId = ordem.clienteId;
      tituloController.text = ordem.titulo;
      descricaoController.text = ordem.descricao;
      descontoController.text = MoneyUtils.format(ordem.desconto);
      acrescimoController.text = MoneyUtils.format(ordem.acrescimo);
      observacoesController.text = ordem.observacoes;
      status = ordem.status;

      itens = await AppDatabase.instance.listarItensDaOrdem(ordem.id!);
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  double parseValor(String value) {
    return MoneyUtils.parse(value);
  }

  double get subtotal {
    return itens.fold(0, (total, item) => total + item.valorTotal);
  }

  double get desconto => parseValor(descontoController.text);
  double get acrescimo => parseValor(acrescimoController.text);
  double get total => subtotal - desconto + acrescimo;

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  void adicionarServico(ServicoModel servico) {
    abrirEditorItem(
      tipo: 'SERVICO',
      descricao: servico.nome,
      valorInicial: servico.valorPadrao,
      servicoId: servico.id,
    );
  }

  void adicionarProduto(ProdutoModel produto) {
    abrirEditorItem(
      tipo: 'PRODUTO',
      descricao: produto.nome,
      valorInicial: produto.precoVenda,
      produtoId: produto.id,
    );
  }

  Future<void> abrirEditorItem({
    required String tipo,
    required String descricao,
    required double valorInicial,
    int? servicoId,
    int? produtoId,
  }) async {
    final quantidadeController = TextEditingController(text: '1');
    final valorController = TextEditingController(
      text: MoneyUtils.format(valorInicial),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final quantidade = parseValor(quantidadeController.text);
            final valor = parseValor(valorController.text);
            final totalItem = quantidade * valor;

            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 22,
                  bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
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
                    Text(
                      descricao,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: quantidadeController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Quantidade',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: valorController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Valor unitário',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total do item',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dinheiro(totalItem),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (quantidade <= 0) return;

                          final agora = DateTime.now().toIso8601String();

                          setState(() {
                            itens.add(
                              OrdemServicoItemModel(
                                ordemServicoId: widget.ordem?.id ?? 0,
                                tipo: tipo,
                                servicoId: servicoId,
                                produtoId: produtoId,
                                descricao: descricao,
                                quantidade: quantidade,
                                valorUnitario: valor,
                                valorTotal: totalItem,
                                createdAt: agora,
                              ),
                            );
                          });

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Adicionar item',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    quantidadeController.dispose();
    valorController.dispose();
  }

  Future<void> abrirAdicionarItem() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (modalContext) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.of(modalContext).size.height * 0.75,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.gold,
                    tabs: [
                      Tab(text: 'Serviços'),
                      Tab(text: 'Produtos'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        servicos.isEmpty
                            ? const Center(
                                child: Text('Nenhum serviço cadastrado'),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(
                                        modalContext,
                                      ).viewInsets.bottom +
                                      24,
                                ),
                                itemCount: servicos.length,
                                itemBuilder: (context, index) {
                                  final servico = servicos[index];

                                  return ListTile(
                                    leading: const Icon(
                                      Icons.build_circle_rounded,
                                    ),
                                    title: Text(servico.nome),
                                    subtitle: Text(
                                      dinheiro(servico.valorPadrao),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      adicionarServico(servico);
                                    },
                                  );
                                },
                              ),
                        produtos.isEmpty
                            ? const Center(
                                child: Text('Nenhum produto cadastrado'),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(
                                        modalContext,
                                      ).viewInsets.bottom +
                                      24,
                                ),
                                itemCount: produtos.length,
                                itemBuilder: (context, index) {
                                  final produto = produtos[index];

                                  return ListTile(
                                    leading: const Icon(
                                      Icons.inventory_2_rounded,
                                    ),
                                    title: Text(produto.nome),
                                    subtitle: Text(
                                      '${dinheiro(produto.precoVenda)} • Estoque: ${produto.estoqueAtual.toStringAsFixed(0)} ${produto.unidade}',
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      adicionarProduto(produto);
                                    },
                                  );
                                },
                              ),
                      ],
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

  Future<void> salvar() async {
    if (!formKey.currentState!.validate()) return;

    if (itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um serviço ou produto'),
        ),
      );
      return;
    }

    setState(() => salvando = true);

    final agora = DateTime.now().toIso8601String();

    double valorPagoAtual = 0;

    if (widget.ordem?.id != null) {
      valorPagoAtual = await AppDatabase.instance.totalPagoDaOrdem(
        widget.ordem!.id!,
      );
    }

    final valorPendenteAtual = total - valorPagoAtual;

    String statusFinal = status;

    if (valorPagoAtual >= total && total > 0) {
      statusFinal = 'PAGO';
    } else if (valorPagoAtual > 0 && valorPagoAtual < total) {
      statusFinal = 'AGUARDANDO_PAGAMENTO';
    } else if (status == 'PAGO' && valorPagoAtual <= 0) {
      statusFinal = 'AGUARDANDO_PAGAMENTO';
    }

    final ordem = OrdemServicoModel(
      id: widget.ordem?.id,
      clienteId: clienteId,
      titulo: tituloController.text.trim(),
      descricao: descricaoController.text.trim(),
      status: statusFinal,
      dataAbertura: widget.ordem?.dataAbertura ?? agora,
      dataPrevisao: null,
      dataConclusao: statusFinal == 'CONCLUIDO' || statusFinal == 'PAGO'
          ? agora
          : null,
      subtotal: subtotal,
      desconto: desconto,
      acrescimo: acrescimo,
      total: total,
      valorPago: valorPagoAtual,
      valorPendente: valorPendenteAtual < 0 ? 0 : valorPendenteAtual,
      observacoes: observacoesController.text.trim(),
      createdAt: widget.ordem?.createdAt ?? agora,
      updatedAt: editando ? agora : null,
    );

    await AppDatabase.instance.salvarOrdemComItens(ordem: ordem, itens: itens);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon, color: AppColors.navInactive, size: 20),
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget valorInput({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        prefixText: 'R\$ ',
        prefixStyle: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w800,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget clienteDropdown() {
    final primary = Theme.of(context).colorScheme.primary;

    return DropdownButtonFormField<int>(
      value: clienteId,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textMuted,
      ),
      selectedItemBuilder: (context) {
        return clientes.map((cliente) {
          return Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: 18,
                color: primary.withOpacity(0.75),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cliente.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );
        }).toList();
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Cliente',
        prefixIcon: Icon(
          Icons.people_alt_rounded,
          color: primary.withOpacity(0.75),
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(16),
      menuMaxHeight: 320,
      items: clientes.map((cliente) {
        return DropdownMenuItem<int>(
          value: cliente.id,
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_rounded, size: 16, color: primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cliente.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (cliente.telefone.isNotEmpty)
                Text(
                  cliente.telefone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => clienteId = value);
      },
    );
  }

  Widget itemCard(OrdemServicoItemModel item, int index) {
    final cor = item.tipo == 'PRODUTO' ? AppColors.gold : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withOpacity(0.12),
          child: Icon(
            item.tipo == 'PRODUTO'
                ? Icons.inventory_2_rounded
                : Icons.build_circle_rounded,
            color: cor,
          ),
        ),
        title: Text(
          item.descricao,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          '${item.tipo} • ${item.quantidade.toStringAsFixed(2)} x ${dinheiro(item.valorUnitario)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dinheiro(item.valorTotal),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            InkWell(
              onTap: () {
                setState(() => itens.removeAt(index));
              },
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget totaisCard() {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withOpacity(0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo financeiro',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          linhaTotal('Subtotal', subtotal),
          linhaTotal('Desconto', desconto),
          linhaTotal('Acréscimo', acrescimo),
          const Divider(height: 22),
          const Text(
            'Total',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dinheiro(total),
            textAlign: TextAlign.left,
            style: TextStyle(
              color: primary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget linhaTotal(String label, double valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            dinheiro(valor),
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: editando ? 'Editar OS' : 'Nova OS',
      subtitle: 'Ordem de serviço',
      currentIndex: 3,
      showBack: true,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    clienteDropdown(),
                    const SizedBox(height: 12),
                    input(
                      controller: tituloController,
                      label: 'Título da OS',
                      icon: Icons.assignment_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o título da OS';
                        }
                        return null;
                      },
                    ),
                    input(
                      controller: descricaoController,
                      label: 'Descrição',
                      icon: Icons.description_rounded,
                    ),
                    DropdownButtonFormField<String>(
                      value: status,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: 'Status',
                        prefixIcon: const Icon(
                          Icons.flag_rounded,
                          color: AppColors.navInactive,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'ORCAMENTO',
                          child: Text('Orçamento'),
                        ),
                        DropdownMenuItem(
                          value: 'APROVADO',
                          child: Text('Aprovado'),
                        ),
                        DropdownMenuItem(
                          value: 'EM_ANDAMENTO',
                          child: Text('Em andamento'),
                        ),
                        DropdownMenuItem(
                          value: 'CONCLUIDO',
                          child: Text('Concluído'),
                        ),
                        DropdownMenuItem(
                          value: 'AGUARDANDO_PAGAMENTO',
                          child: Text('Aguardando pagamento'),
                        ),
                        DropdownMenuItem(value: 'PAGO', child: Text('Pago')),
                        DropdownMenuItem(
                          value: 'CANCELADO',
                          child: Text('Cancelado'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: abrirAdicionarItem,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Adicionar serviço ou produto'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...itens.asMap().entries.map((entry) {
                      return itemCard(entry.value, entry.key);
                    }),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: valorInput(
                            controller: descontoController,
                            label: 'Desconto',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: valorInput(
                            controller: acrescimoController,
                            label: 'Acréscimo',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    totaisCard(),
                    const SizedBox(height: 16),
                    input(
                      controller: observacoesController,
                      label: 'Observações',
                      icon: Icons.notes_rounded,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: itens.isEmpty ? null : enviarResumoWhatsApp,
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text(
                          'Enviar resumo no WhatsApp',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Salvar O.S',
                      loading: salvando,
                      onPressed: salvar,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> enviarResumoWhatsApp() async {
    ClienteModel? cliente;

    if (clienteId != null) {
      cliente = clientes.firstWhere(
        (c) => c.id == clienteId,
        orElse: () =>
            ClienteModel(nome: '', telefone: '', instagram: '', createdAt: ''),
      );
    }

    if (cliente == null || cliente.telefone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente sem telefone cadastrado')),
      );
      return;
    }

    final telefone = cliente.telefone.replaceAll(RegExp(r'\D'), '');

    final itensTexto = itens
        .map((item) {
          return '- ${item.descricao}: ${item.quantidade.toStringAsFixed(2)} x ${dinheiro(item.valorUnitario)} = ${dinheiro(item.valorTotal)}';
        })
        .join('\n');

    final mensagem =
        '''
Olá ${cliente.nome}, tudo bem?

Segue o resumo da sua ordem de serviço:

${tituloController.text.trim()}

Itens:
$itensTexto

Subtotal: ${dinheiro(subtotal)}
Desconto: ${dinheiro(desconto)}
Acréscimo: ${dinheiro(acrescimo)}
Total: ${dinheiro(total)}

Status: $status

Obrigado pela preferência!
''';

    final mensagemEncoded = Uri.encodeComponent(mensagem);

    final uriWhatsapp = Uri.parse(
      'whatsapp://send?phone=55$telefone&text=$mensagemEncoded',
    );

    final uriWeb = Uri.parse(
      'https://api.whatsapp.com/send?phone=55$telefone&text=$mensagemEncoded',
    );

    if (await canLaunchUrl(uriWhatsapp)) {
      await launchUrl(uriWhatsapp, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(uriWeb)) {
      await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp não encontrado neste aparelho')),
      );
    }
  }
}
