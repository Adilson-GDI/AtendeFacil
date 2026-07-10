import '../database/app_database.dart';
import 'admin_api_service.dart';

class ServiceLocationSyncService {
  static Future<void> sincronizar() async {
    final user = await AppDatabase.instance.buscarAppUser();
    if (user == null || (user.remoteUserId ?? '').isEmpty) return;
    final pending = await AppDatabase.instance
        .listarServiceLocationsPendentes();
    if (pending.isEmpty) return;
    try {
      final ids = await AdminApiService.instance.sincronizarLocais(
        user: user,
        locations: pending,
      );
      await AppDatabase.instance.concluirSyncServiceLocations(ids);
    } catch (_) {}
  }
}
