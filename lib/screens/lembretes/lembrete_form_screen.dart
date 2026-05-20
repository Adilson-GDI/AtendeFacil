import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/lembrete_database.dart';
import '../../models/lembrete_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../services/local_notification_service.dart';

class LembreteFormScreen extends StatefulWidget {
  final LembreteModel? lembrete;

  const LembreteFormScreen({super.key, this.lembrete});

  @override
  State<LembreteFormScreen> createState() => _LembreteFormScreenState();
}

class _LembreteFormScreenState extends State<LembreteFormScreen> {
  final formKey = GlobalKey<FormState>();

  final tituloController = TextEditingController();
  final descricaoController = TextEditingController();
  final horaController = TextEditingController();

  DateTime dataInicio = DateTime.now();

  String tipo = 'GERAL';
  String recorrencia = 'NENHUMA';

  bool ativo = true;
  bool concluido = false;
  bool salvando = false;

  final tipos = const [
    'GERAL',
    'FINANCEIRO',
    'FISCAL',
    'CLIENTE',
    'AGENDA',
    'BACKUP',
    'OUTRO',
  ];

  final recorrencias = const [
    'NENHUMA',
    'DIARIA',
    'SEMANAL',
    'MENSAL',
    'ANUAL',
  ];

  @override
  void initState() {
    super.initState();

    final item = widget.lembrete;

    if (item != null) {
      tituloController.text = item.titulo;
      descricaoController.text = item.descricao;
      horaController.text = item.hora;
      tipo = item.tipo;
      recorrencia = item.recorrencia;
      ativo = item.ativo == 1;
      concluido = item.concluido == 1;

      try {
        dataInicio = DateTime.parse(item.dataInicio);
      } catch (_) {
        dataInicio = DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    tituloController.dispose();
    descricaoController.dispose();
    horaController.dispose();
    super.dispose();
  }

  String dataSql(DateTime data) {
    return '${data.year.toString().padLeft(4, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }

  String dataBr(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  String labelTipo(String value) {
    switch (value) {
      case 'FINANCEIRO':
        return 'Financeiro';
      case 'FISCAL':
        return 'Fiscal';
      case 'CLIENTE':
        return 'Cliente';
      case 'AGENDA':
        return 'Agenda';
      case 'BACKUP':
        return 'Backup';
      case 'OUTRO':
        return 'Outro';
      default:
        return 'Geral';
    }
  }

  String labelRecorrencia(String value) {
    switch (value) {
      case 'DIARIA':
        return 'Diária';
      case 'SEMANAL':
        return 'Semanal';
      case 'MENSAL':
        return 'Mensal';
      case 'ANUAL':
        return 'Anual';
      default:
        return 'Não repetir';
    }
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

  Future<void> selecionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (hora != null) {
      horaController.text =
          '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
    }
  }

  DateTime? montarDataHoraNotificacao() {
    if (horaController.text.trim().isEmpty) return null;

    final partes = horaController.text.trim().split(':');
    if (partes.length != 2) return null;

    final hora = int.tryParse(partes[0]);
    final minuto = int.tryParse(partes[1]);

    if (hora == null || minuto == null) return null;

    return DateTime(
      dataInicio.year,
      dataInicio.month,
      dataInicio.day,
      hora,
      minuto,
    );
  }

  Future<void> salvar() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => salvando = true);

    final agora = DateTime.now().toIso8601String();

    final lembrete = LembreteModel(
      id: widget.lembrete?.id,
      titulo: tituloController.text.trim(),
      descricao: descricaoController.text.trim(),
      tipo: tipo,
      dataInicio: dataSql(dataInicio),
      hora: horaController.text.trim(),
      recorrencia: recorrencia,
      ativo: ativo ? 1 : 0,
      concluido: concluido ? 1 : 0,
      ultimaExecucao: widget.lembrete?.ultimaExecucao ?? '',
      createdAt: widget.lembrete?.createdAt ?? agora,
    );

    int lembreteId;

    if (widget.lembrete == null) {
      lembreteId = await LembreteDatabase.instance.criarLembrete(lembrete);
    } else {
      lembreteId = widget.lembrete!.id!;
      await LembreteDatabase.instance.atualizarLembrete(lembrete);
    }

    final dataHora = montarDataHoraNotificacao();

    await LocalNotificationService.instance.cancelarLembrete(lembreteId);

    if (dataHora != null &&
        ativo &&
        !concluido &&
        dataHora.isAfter(DateTime.now())) {
      await LocalNotificationService.instance.agendarLembrete(
        id: lembreteId,
        titulo: 'Lembrete',
        mensagem: tituloController.text.trim(),
        dataHora: dataHora,
      );
    }

    if (!mounted) return;

    Navigator.pop(context);
  }

  Widget input({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget selectBox({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required String Function(String) labelBuilder,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(labelBuilder(item)));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget switchBox({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.lembrete != null;

    return AppScaffold(
      title: editando ? 'Editar lembrete' : 'Novo lembrete',
      subtitle: 'Tarefas e recorrências',
      showBack: true,
      currentIndex: 0,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Form(
            key: formKey,
            child: Column(
              children: [
                input(
                  controller: tituloController,
                  label: 'Título',
                  icon: Icons.notifications_active_rounded,
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
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),

                selectBox(
                  label: 'Tipo',
                  value: tipo,
                  items: tipos,
                  labelBuilder: labelTipo,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => tipo = value);
                    }
                  },
                ),

                GestureDetector(
                  onTap: selecionarData,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Data inicial: ${dataBr(dataInicio)}',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                input(
                  controller: horaController,
                  label: 'Hora',
                  icon: Icons.schedule_rounded,
                  readOnly: true,
                  onTap: selecionarHora,
                ),

                selectBox(
                  label: 'Recorrência',
                  value: recorrencia,
                  items: recorrencias,
                  labelBuilder: labelRecorrencia,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => recorrencia = value);
                    }
                  },
                ),

                switchBox(
                  title: 'Lembrete ativo',
                  subtitle: 'Exibir este lembrete nas listagens',
                  value: ativo,
                  onChanged: (value) {
                    setState(() => ativo = value);
                  },
                ),

                if (editando)
                  switchBox(
                    title: 'Concluído',
                    subtitle: 'Marcar este lembrete como finalizado',
                    value: concluido,
                    onChanged: (value) {
                      setState(() => concluido = value);
                    },
                  ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: salvando ? null : salvar,
                    icon: salvando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(editando ? 'Salvar alterações' : 'Salvar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
