import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../models/agenda_model.dart';
import '../../models/cliente_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_scaffold.dart';

class AgendaFormScreen extends StatefulWidget {
  final AgendaModel? agenda;

  const AgendaFormScreen({super.key, this.agenda});

  @override
  State<AgendaFormScreen> createState() => _AgendaFormScreenState();
}

class _AgendaFormScreenState extends State<AgendaFormScreen> {
  final formKey = GlobalKey<FormState>();

  final tituloController = TextEditingController();
  final descricaoController = TextEditingController();
  final observacoesController = TextEditingController();

  List<ClienteModel> clientes = [];

  int? clienteId;
  DateTime dataInicio = DateTime.now();
  TimeOfDay horaInicio = TimeOfDay.now();
  TimeOfDay? horaFim;

  String status = 'AGENDADO';
  bool recorrente = false;
  String tipoRecorrencia = 'SEMANAL';
  final Set<String> diasSelecionados = {};

  bool loading = true;
  bool salvando = false;

  bool get editando => widget.agenda != null;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  @override
  void dispose() {
    tituloController.dispose();
    descricaoController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  Future<void> carregar() async {
    clientes = await AppDatabase.instance.listarClientes();

    if (editando) {
      final item = widget.agenda!;

      clienteId = item.clienteId;
      tituloController.text = item.titulo;
      descricaoController.text = item.descricao;
      observacoesController.text = item.observacoes;
      status = item.status;
      recorrente = item.recorrente == 1;
      tipoRecorrencia = item.tipoRecorrencia.isEmpty
          ? 'SEMANAL'
          : item.tipoRecorrencia;

      final data = DateTime.tryParse(item.dataInicio);
      if (data != null) dataInicio = data;

      horaInicio = _parseHora(item.horaInicio) ?? TimeOfDay.now();
      horaFim = _parseHora(item.horaFim);

      if (item.diasSemana.isNotEmpty) {
        diasSelecionados.addAll(
          item.diasSemana.split(',').where((e) => e.trim().isNotEmpty),
        );
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  String dataSql(DateTime data) {
    return '${data.year.toString().padLeft(4, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }

  String horaTexto(TimeOfDay? hora) {
    if (hora == null) return '';
    return '${hora.hour.toString().padLeft(2, '0')}:'
        '${hora.minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay? _parseHora(String hora) {
    if (hora.trim().isEmpty) return null;

    final partes = hora.split(':');
    if (partes.length < 2) return null;

    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);

    if (h == null || m == null) return null;

    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: dataInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (data != null) {
      setState(() => dataInicio = data);
    }
  }

  Future<void> selecionarHoraInicio() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: horaInicio,
    );

    if (hora != null) {
      setState(() => horaInicio = hora);
    }
  }

  Future<void> selecionarHoraFim() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: horaFim ?? horaInicio,
    );

    if (hora != null) {
      setState(() => horaFim = hora);
    }
  }

  Future<void> salvar() async {
    if (!formKey.currentState!.validate()) return;

    if (recorrente && diasSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um dia da semana')),
      );
      return;
    }

    setState(() => salvando = true);

    final dataTexto = dataSql(dataInicio);
    final inicioTexto = horaTexto(horaInicio);
    final fimTexto = horaTexto(horaFim);

    final conflito = await AppDatabase.instance.existeConflitoAgenda(
      agendaIdIgnorar: widget.agenda?.id,
      dataInicio: dataTexto,
      horaInicio: inicioTexto,
      horaFim: fimTexto.isEmpty ? inicioTexto : fimTexto,
    );

    if (conflito) {
      final continuar = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Horário já ocupado'),
          content: const Text(
            'Já existe um atendimento nesse horário. Deseja salvar mesmo assim?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar mesmo assim'),
            ),
          ],
        ),
      );

      if (continuar != true) {
        setState(() => salvando = false);
        return;
      }
    }

    final agora = DateTime.now().toIso8601String();

    final item = AgendaModel(
      id: widget.agenda?.id,
      clienteId: clienteId,
      ordemServicoId: widget.agenda?.ordemServicoId,
      titulo: tituloController.text.trim(),
      descricao: descricaoController.text.trim(),
      dataInicio: dataSql(dataInicio),
      horaInicio: horaTexto(horaInicio),
      horaFim: horaTexto(horaFim),
      status: status,
      recorrente: recorrente ? 1 : 0,
      tipoRecorrencia: recorrente ? tipoRecorrencia : '',
      diasSemana: recorrente ? diasSelecionados.join(',') : '',
      dataFimRecorrencia: '',
      observacoes: observacoesController.text.trim(),
      createdAt: widget.agenda?.createdAt ?? agora,
      updatedAt: editando ? agora : null,
    );

    if (editando) {
      await AppDatabase.instance.atualizarAgenda(item);
    } else {
      await AppDatabase.instance.criarAgenda(item);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int minLines = 1,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon, color: AppColors.navInactive),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget selectBox({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.navInactive),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget diaSemanaChip(String value, String label) {
    final selected = diasSelecionados.contains(value);
    final primary = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: primary.withOpacity(0.12),
      labelStyle: TextStyle(
        color: selected ? primary : AppColors.textMuted,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
      ),
      side: BorderSide(color: selected ? primary : AppColors.border),
      onSelected: (_) {
        setState(() {
          if (selected) {
            diasSelecionados.remove(value);
          } else {
            diasSelecionados.add(value);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: editando ? 'Editar agenda' : 'Novo agendamento',
      subtitle: 'Atendimento',
      currentIndex: 4,
      showBack: true,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: clienteId,
                        decoration: InputDecoration(
                          labelText: 'Cliente',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.person_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: clientes
                            .where((cliente) => cliente.id != null)
                            .map((cliente) {
                              return DropdownMenuItem<int>(
                                value: cliente.id!,
                                child: Text(cliente.nome),
                              );
                            })
                            .toList(),
                        onChanged: (value) {
                          setState(() => clienteId = value);
                        },
                      ),

                      const SizedBox(height: 12),

                      input(
                        controller: tituloController,
                        label: 'Título do agendamento',
                        icon: Icons.event_note_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o título';
                          }
                          return null;
                        },
                      ),

                      input(
                        controller: descricaoController,
                        label: 'Descrição',
                        icon: Icons.description_rounded,
                        minLines: 2,
                        maxLines: 4,
                      ),

                      selectBox(
                        label: 'Data',
                        value:
                            '${dataInicio.day.toString().padLeft(2, '0')}/'
                            '${dataInicio.month.toString().padLeft(2, '0')}/'
                            '${dataInicio.year}',
                        icon: Icons.calendar_month_rounded,
                        onTap: selecionarData,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: selectBox(
                              label: 'Início',
                              value: horaTexto(horaInicio),
                              icon: Icons.schedule_rounded,
                              onTap: selecionarHoraInicio,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: selectBox(
                              label: 'Fim',
                              value: horaFim == null
                                  ? '--:--'
                                  : horaTexto(horaFim),
                              icon: Icons.schedule_send_rounded,
                              onTap: selecionarHoraFim,
                            ),
                          ),
                        ],
                      ),

                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.flag_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'AGENDADO',
                            child: Text('Agendado'),
                          ),
                          DropdownMenuItem(
                            value: 'CONCLUIDO',
                            child: Text('Concluído'),
                          ),
                          DropdownMenuItem(
                            value: 'CANCELADO',
                            child: Text('Cancelado'),
                          ),
                          DropdownMenuItem(
                            value: 'FALTOU',
                            child: Text('Faltou'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => status = value);
                        },
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: recorrente,
                              activeColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              title: const Text(
                                'Atendimento recorrente',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              subtitle: const Text(
                                'Repete em dias fixos da semana',
                              ),
                              onChanged: (value) {
                                setState(() => recorrente = value);
                              },
                            ),
                            if (recorrente) ...[
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    diaSemanaChip('SEG', 'Seg'),
                                    diaSemanaChip('TER', 'Ter'),
                                    diaSemanaChip('QUA', 'Qua'),
                                    diaSemanaChip('QUI', 'Qui'),
                                    diaSemanaChip('SEX', 'Sex'),
                                    diaSemanaChip('SAB', 'Sáb'),
                                    diaSemanaChip('DOM', 'Dom'),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      input(
                        controller: observacoesController,
                        label: 'Observações',
                        icon: Icons.notes_rounded,
                        minLines: 2,
                        maxLines: 4,
                      ),

                      const SizedBox(height: 12),

                      AppButton(
                        label: editando
                            ? 'Salvar alterações'
                            : 'Salvar agendamento',
                        loading: salvando,
                        onPressed: salvar,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
