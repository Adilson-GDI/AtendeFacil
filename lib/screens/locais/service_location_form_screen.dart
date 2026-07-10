import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/app_colors.dart';
import '../../database/app_database.dart';
import '../../services/service_location_sync_service.dart';
import '../../models/service_location_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_scaffold.dart';

class ServiceLocationFormScreen extends StatefulWidget {
  final ServiceLocationModel? location;

  const ServiceLocationFormScreen({super.key, this.location});

  @override
  State<ServiceLocationFormScreen> createState() =>
      _ServiceLocationFormScreenState();
}

class _ServiceLocationFormScreenState extends State<ServiceLocationFormScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final neighborhoodController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipCodeController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  final notesController = TextEditingController();

  String type = ServiceLocationModel.typeGym;
  bool isPublic = false;
  bool loadingLocation = false;
  bool saving = false;

  bool get editing => widget.location != null;

  @override
  void initState() {
    super.initState();

    final location = widget.location;
    if (location != null) {
      nameController.text = location.name;
      addressController.text = location.address;
      neighborhoodController.text = location.neighborhood;
      cityController.text = location.city;
      stateController.text = location.state;
      zipCodeController.text = location.zipCode;
      latitudeController.text = location.latitude?.toString() ?? '';
      longitudeController.text = location.longitude?.toString() ?? '';
      notesController.text = location.notes;
      type = location.type;
      isPublic = location.isPublic;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    neighborhoodController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipCodeController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<bool> confirmarPublico() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Privacidade do local'),
        content: const Text(
          'Este local podera ser usado futuramente para que clientes encontrem profissionais proximos. Voce pode deixar este local privado se quiser usar apenas para sua organizacao.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Manter privado'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tornar publico'),
          ),
        ],
      ),
    );

    return result == true;
  }

  Future<void> usarLocalizacaoAtual() async {
    setState(() => loadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Ative a localizacao do aparelho para continuar.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permissao de localizacao negada.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        latitudeController.text = position.latitude.toStringAsFixed(7);
        longitudeController.text = position.longitude.toStringAsFixed(7);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loadingLocation = false);
    }
  }

  Future<void> salvar() async {
    if (!formKey.currentState!.validate()) return;

    var publico = isPublic;
    if (publico) {
      publico = await confirmarPublico();
      if (!mounted) return;
      setState(() => isPublic = publico);
    }

    setState(() => saving = true);

    final now = DateTime.now().toIso8601String();
    final model = ServiceLocationModel(
      id: widget.location?.id,
      name: nameController.text.trim(),
      address: addressController.text.trim(),
      neighborhood: neighborhoodController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      zipCode: zipCodeController.text.trim(),
      latitude: double.tryParse(latitudeController.text.trim()),
      longitude: double.tryParse(longitudeController.text.trim()),
      type: type,
      notes: notesController.text.trim(),
      isPublic: publico,
      createdAt: widget.location?.createdAt ?? now,
      updatedAt: editing ? now : null,
    );

    if (editing) {
      await AppDatabase.instance.atualizarServiceLocation(model);
    } else {
      await AppDatabase.instance.criarServiceLocation(model);
    }
    await ServiceLocationSyncService.sincronizar();

    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int minLines = 1,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return AppInput(
      controller: controller,
      label: label,
      icon: icon,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: editing ? 'Editar local' : 'Novo local',
      subtitle: 'Local de atendimento',
      currentIndex: 4,
      showBack: true,
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            input(
              controller: nameController,
              label: 'Nome do local',
              icon: Icons.place_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome do local';
                }
                return null;
              },
            ),
            input(
              controller: addressController,
              label: 'Endereco',
              icon: Icons.map_rounded,
            ),
            Row(
              children: [
                Expanded(
                  child: input(
                    controller: neighborhoodController,
                    label: 'Bairro',
                    icon: Icons.location_city_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: input(
                    controller: zipCodeController,
                    label: 'CEP',
                    icon: Icons.markunread_mailbox_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: input(
                    controller: cityController,
                    label: 'Cidade',
                    icon: Icons.apartment_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: input(
                    controller: stateController,
                    label: 'Estado',
                    icon: Icons.flag_rounded,
                  ),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(
                labelText: 'Tipo de local',
                prefixIcon: Icon(Icons.category_rounded),
              ),
              items: const [
                DropdownMenuItem(
                  value: ServiceLocationModel.typeGym,
                  child: Text('Academia'),
                ),
                DropdownMenuItem(
                  value: ServiceLocationModel.typeStudio,
                  child: Text('Estudio'),
                ),
                DropdownMenuItem(
                  value: ServiceLocationModel.typeCondominium,
                  child: Text('Condominio'),
                ),
                DropdownMenuItem(
                  value: ServiceLocationModel.typeHome,
                  child: Text('Domiciliar'),
                ),
                DropdownMenuItem(
                  value: ServiceLocationModel.typePark,
                  child: Text('Parque'),
                ),
                DropdownMenuItem(
                  value: ServiceLocationModel.typeClinic,
                  child: Text('Clinica'),
                ),
                DropdownMenuItem(
                  value: ServiceLocationModel.typeOther,
                  child: Text('Outro'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => type = value);
              },
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(14),
              elevated: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: input(
                          controller: latitudeController,
                          label: 'Latitude',
                          icon: Icons.my_location_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: input(
                          controller: longitudeController,
                          label: 'Longitude',
                          icon: Icons.explore_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppButton(
                    label: 'Usar minha localizacao atual',
                    icon: Icons.gps_fixed_rounded,
                    outlined: true,
                    loading: loadingLocation,
                    onPressed: loadingLocation ? null : usarLocalizacaoAtual,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            input(
              controller: notesController,
              label: 'Observacoes',
              icon: Icons.notes_rounded,
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 2),
            AppCard(
              padding: const EdgeInsets.all(8),
              elevated: false,
              child: SwitchListTile(
                value: isPublic,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                title: const Text(
                  'Publico',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: const Text(
                  'Permitir uso futuro em descoberta de profissionais, somente com consentimento.',
                ),
                onChanged: (value) => setState(() => isPublic = value),
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: editing ? 'Salvar alteracoes' : 'Salvar local',
              icon: Icons.save_rounded,
              loading: saving,
              onPressed: saving ? null : salvar,
            ),
          ],
        ),
      ),
    );
  }
}
