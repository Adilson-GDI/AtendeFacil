import '../database/app_database.dart';
import '../models/app_remote_status_model.dart';
import '../models/app_user_model.dart';
import 'admin_api_service.dart';
import 'app_device_service.dart';
import 'push_service.dart';

class AppBootstrapResult {
  final bool precisaCadastro;
  final AppRemoteStatusModel status;
  final String? erroOnline;

  AppBootstrapResult({
    required this.precisaCadastro,
    required this.status,
    this.erroOnline,
  });
}

class AppBootstrapService {
  static final AppBootstrapService instance = AppBootstrapService._();

  AppBootstrapService._();

  Future<AppBootstrapResult> iniciar() async {
    final user = await AppDatabase.instance.buscarAppUser();
    final cachedStatus =
        await AppDatabase.instance.buscarRemoteStatusCache() ??
        AppRemoteStatusModel.liberado();

    if (user == null) {
      return AppBootstrapResult(precisaCadastro: true, status: cachedStatus);
    }

    try {
      final token = await PushService.instance.prepararPermissaoEObterToken();
      var syncedUser = user;

      if (token != null && token != user.fcmToken && user.id != null) {
        await AppDatabase.instance.atualizarAppUserToken(
          userId: user.id!,
          remoteUserId: user.remoteUserId,
          fcmToken: token,
        );
        syncedUser = user.copyWith(fcmToken: token);
      }

      if ((syncedUser.remoteUserId ?? '').isEmpty && syncedUser.id != null) {
        final response = await AdminApiService.instance.cadastrarUsuario(
          syncedUser,
        );
        final remoteUserId =
            response['user_id']?.toString() ??
            response['remote_user_id']?.toString() ??
            response['id']?.toString();

        await AppDatabase.instance.atualizarAppUserToken(
          userId: syncedUser.id!,
          remoteUserId: remoteUserId,
          fcmToken: syncedUser.fcmToken,
        );
        syncedUser = syncedUser.copyWith(remoteUserId: remoteUserId);
      }

      if (token != null) {
        await AdminApiService.instance.registrarToken(
          user: syncedUser,
          token: token,
        );
      }

      final status = await AdminApiService.instance.verificarStatus(syncedUser);
      await AppDatabase.instance.salvarRemoteStatusCache(status);
      PushService.instance.ouvirAtualizacaoToken(syncedUser);

      return AppBootstrapResult(precisaCadastro: false, status: status);
    } catch (e) {
      PushService.instance.ouvirAtualizacaoToken(user);

      return AppBootstrapResult(
        precisaCadastro: false,
        status: cachedStatus,
        erroOnline: e.toString(),
      );
    }
  }

  Future<AppBootstrapResult> cadastrarProfissional({
    required String nome,
    required String telefone,
  }) async {
    final device = await AppDeviceService.instance.carregar();
    final token = await PushService.instance.prepararPermissaoEObterToken();
    final agora = DateTime.now().toIso8601String();

    var user = AppUserModel(
      nome: nome,
      email: '',
      telefone: telefone,
      profissao: 'Personal Trainer',
      cidade: '',
      estado: '',
      deviceId: device.deviceId,
      plataforma: device.plataforma,
      appVersion: device.appVersion,
      fcmToken: token,
      createdAt: agora,
    );

    final localId = await AppDatabase.instance.salvarAppUser(user);
    user = user.copyWith(id: localId);

    try {
      final response = await AdminApiService.instance.cadastrarUsuario(user);
      final remoteUserId =
          response['user_id']?.toString() ??
          response['remote_user_id']?.toString() ??
          response['id']?.toString();

      await AppDatabase.instance.atualizarAppUserToken(
        userId: localId,
        remoteUserId: remoteUserId,
        fcmToken: token,
      );

      user = user.copyWith(remoteUserId: remoteUserId);

      if (token != null) {
        await AdminApiService.instance.registrarToken(user: user, token: token);
      }

      final status = await AdminApiService.instance.verificarStatus(user);
      await AppDatabase.instance.salvarRemoteStatusCache(status);
      PushService.instance.ouvirAtualizacaoToken(user);

      return AppBootstrapResult(precisaCadastro: false, status: status);
    } catch (e) {
      final cached = await AppDatabase.instance.buscarRemoteStatusCache();
      PushService.instance.ouvirAtualizacaoToken(user);

      return AppBootstrapResult(
        precisaCadastro: false,
        status: cached ?? AppRemoteStatusModel.liberado(),
        erroOnline: e.toString(),
      );
    }
  }
}
