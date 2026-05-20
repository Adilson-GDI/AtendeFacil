import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../database/app_database.dart';

class PushService {
  static const String endpoint =
      'https://senhoradasgracas.org.br/push/save_token.php';

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> inicializar() async {
    try {
      await _pedirPermissao();

      await registrarToken();

      FirebaseMessaging.instance.onTokenRefresh.listen((novoToken) async {
        await registrarToken(tokenManual: novoToken);
      });
    } catch (e) {
      print('Erro ao inicializar PushService: $e');
    }
  }

  static Future<void> _pedirPermissao() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      print('Erro ao pedir permissão de notificação: $e');
    }
  }

  static Future<void> registrarToken({String? tokenManual}) async {
    try {
      final token = tokenManual ?? await _messaging.getToken();

      if (token == null || token.isEmpty) {
        print('Token FCM vazio ou nulo');
        return;
      }

      dynamic config;
      String tipoServico = 'GERAL';

      try {
        config = await AppDatabase.instance.buscarConfigApp();
      } catch (e) {
        print('Configuração da empresa ainda não encontrada: $e');
      }

      try {
        final tipo = await AppDatabase.instance.buscarTipoServicoApp();

        if (tipo.trim().isNotEmpty) {
          tipoServico = tipo;
        }
      } catch (e) {
        print('Tipo de serviço ainda não encontrado: $e');
      }

      final deviceName = await _deviceName();
      final packageInfo = await PackageInfo.fromPlatform();
      final permissionSettings = await _messaging.getNotificationSettings();

      final response = await http.post(
        Uri.parse(endpoint),
        body: {
          'token': token,
          'device_name': deviceName,
          'app_version': packageInfo.version,
          'user_id': '0',
          'platform': _platform(),
          'permission': permissionSettings.authorizationStatus.name,

          'nome_empresa': _safe(config?.nomeEmpresa),
          'telefone': _safe(config?.telefone),
          'whatsapp': _safe(config?.whatsapp),
          'instagram': _safe(config?.instagram),
          'documento': _safe(config?.documento),
          'endereco': _safe(config?.endereco),
          'cidade': _safe(config?.cidade),
          'estado': _safe(config?.estado),
          'tipo_servico': tipoServico,
        },
      );

      if (response.statusCode != 200) {
        print('Erro HTTP ao registrar token: ${response.statusCode}');
        print(response.body);
        return;
      }

      final body = response.body.trim();

      print('Resposta push HTTP ${response.statusCode}: $body');

      if (body.isEmpty) {
        print('Servidor retornou resposta vazia');
        return;
      }

      final data = jsonDecode(body);

      if (data is Map && data['status'] == 'error') {
        print('Erro retornado pelo servidor: ${data['msg']}');
        return;
      }

      print('Token FCM registrado com sucesso');
    } catch (e) {
      print('Erro ao registrar token FCM: $e');
    }
  }

  static String _safe(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static String _platform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }

  static Future<String> _deviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        return '${android.manufacturer} ${android.model}';
      }

      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        return '${ios.name} ${ios.model}';
      }

      return 'Unknown';
    } catch (e) {
      print('Erro ao buscar nome do dispositivo: $e');
      return 'Unknown';
    }
  }
}
