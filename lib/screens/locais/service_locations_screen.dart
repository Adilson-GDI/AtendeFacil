import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../services/service_location_sync_service.dart';
import '../../models/service_location_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_scaffold.dart';
import 'service_location_form_screen.dart';

class ServiceLocationsScreen extends StatefulWidget {
  const ServiceLocationsScreen({super.key});

  @override
  State<ServiceLocationsScreen> createState() => _ServiceLocationsScreenState();
}

class _ServiceLocationsScreenState extends State<ServiceLocationsScreen> {
  bool loading = true;
  List<ServiceLocationModel> locations = [];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    if (mounted) setState(() => loading = true);

    final result = await AppDatabase.instance.listarServiceLocations();

    if (!mounted) return;

    setState(() {
      locations = result;
      loading = false;
    });
  }

  Future<void> abrirFormulario({ServiceLocationModel? location}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceLocationFormScreen(location: location),
      ),
    );

    await carregar();
  }

  Future<void> excluir(ServiceLocationModel location) async {
    if (location.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir local'),
        content: Text('Deseja excluir "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await AppDatabase.instance.deletarServiceLocation(location.id!);
    await ServiceLocationSyncService.sincronizar();
    await carregar();
  }

  Widget emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_on_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum local cadastrado',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cadastre academias, estudios, domicilios ou outros pontos de atendimento.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Adicionar Local de Atendimento',
            icon: Icons.add_location_alt_rounded,
            onPressed: abrirFormulario,
          ),
        ],
      ),
    );
  }

  Widget locationCard(ServiceLocationModel location) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: primary.withValues(alpha: 0.10),
          child: Icon(Icons.place_rounded, color: primary),
        ),
        title: Text(
          location.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          '${location.typeLabel} - ${location.shortAddress}\n'
          '${location.isPublic ? 'Publico' : 'Privado'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'editar') abrirFormulario(location: location);
            if (value == 'excluir') excluir(location);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'editar', child: Text('Editar')),
            PopupMenuItem(value: 'excluir', child: Text('Excluir')),
          ],
        ),
        onTap: () => abrirFormulario(location: location),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Locais',
      subtitle: 'Locais de atendimento',
      currentIndex: 4,
      showBack: true,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  AppButton(
                    label: 'Adicionar Local de Atendimento',
                    icon: Icons.add_location_alt_rounded,
                    onPressed: abrirFormulario,
                  ),
                  const SizedBox(height: 16),
                  if (locations.isEmpty)
                    emptyState()
                  else
                    ...locations.map(locationCard),
                ],
              ),
            ),
    );
  }
}
