import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/app_runtime.dart';
import '../models/app_remote_status_model.dart';
import '../models/app_user_model.dart';

class AdminApiService {
  static final AdminApiService instance = AdminApiService._();

  AdminApiService._();

  static const String baseUrl = String.fromEnvironment(
    'FITCHECK_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  Uri _uri(String path) {
    return Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/$path');
  }

  Future<Map<String, dynamic>> cadastrarUsuario(AppUserModel user) async {
    return _postJson('app_users/register', {
      'app_code': AppRuntime.definition.appId,
      'nome': user.nome,
      'email': user.email,
      'telefone': user.telefone,
      'profissao': user.profissao,
      'cidade': user.cidade,
      'estado': user.estado,
      'device_id': user.deviceId,
      'platform': user.plataforma,
      'app_version': user.appVersion,
      'fcm_token': user.fcmToken ?? '',
    });
  }

  Future<void> registrarToken({
    required AppUserModel user,
    required String token,
  }) async {
    await _postJson('fcm_tokens/register', {
      'app_code': AppRuntime.definition.appId,
      'user_id': user.remoteUserId ?? user.id?.toString() ?? '',
      'local_user_id': user.id?.toString() ?? '',
      'device_id': user.deviceId,
      'fcm_token': token,
      'platform': user.plataforma,
      'app_version': user.appVersion,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<AppRemoteStatusModel> verificarStatus(AppUserModel user) async {
    final data = await _postJson('app/status', {
      'app_code': AppRuntime.definition.appId,
      'user_id': user.remoteUserId ?? user.id?.toString() ?? '',
      'local_user_id': user.id?.toString() ?? '',
      'device_id': user.deviceId,
      'platform': user.plataforma,
      'app_version': user.appVersion,
      'fcm_token': user.fcmToken ?? '',
    });

    return AppRemoteStatusModel.fromApi(data);
  }

  Future<Map<String, dynamic>> enviarMensagemSuporte({
    required AppUserModel? user,
    required String message,
    required String localCreatedAt,
  }) async {
    return _postJson('support/messages', {
      'app_code': AppRuntime.definition.appId,
      'user_id': user?.remoteUserId ?? user?.id?.toString() ?? '',
      'local_user_id': user?.id?.toString() ?? '',
      'name': user?.nome ?? '',
      'email': user?.email ?? '',
      'phone': user?.telefone ?? '',
      'message': message,
      'local_created_at': localCreatedAt,
      'platform': user?.plataforma ?? '',
      'app_version': user?.appVersion ?? '',
    });
  }

  Future<List<int>> sincronizarLocais({
    required AppUserModel user,
    required List<Map<String, Object?>> locations,
  }) async {
    final data = await _postJson('service-locations/sync', {
      'app_code': AppRuntime.definition.appId,
      'professional_id': user.remoteUserId,
      'device_id': user.deviceId,
      'locations': locations
          .map(
            (i) => {
              'local_id': i['id'],
              'deleted': i['is_deleted'] == 1,
              'name': i['name'],
              'address': i['address'],
              'neighborhood': i['neighborhood'],
              'city': i['city'],
              'state': i['state'],
              'zip_code': i['zip_code'],
              'latitude': i['latitude'],
              'longitude': i['longitude'],
              'type': i['type'],
              'notes': i['notes'],
              'is_public': i['is_public'] == 1,
            },
          )
          .toList(),
    });
    return (data['synced_local_ids'] as List? ?? [])
        .map((id) => int.parse(id.toString()))
        .toList();
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          _uri(path),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TimeoutException('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Resposta invalida da API');
    }

    if (decoded['success'] == false) {
      throw StateError(decoded['message']?.toString() ?? 'Erro na API');
    }

    return decoded;
  }
}
