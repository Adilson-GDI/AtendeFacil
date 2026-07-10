import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../models/app_remote_status_model.dart';
import '../models/app_user_model.dart';
import 'admin_api_service.dart';

enum FeatureConfigSource { defaults, localCache, remote }

abstract final class FeatureDefaults {
  static const values = <String, Object>{
    'students.enabled': true,
    'students.max_limit': 5,
    'workouts.enabled': true,
    'workouts.share_whatsapp': true,
    'schedule.enabled': true,
    'progress.enabled': true,
    'progress.measurements': true,
    'progress.weight': true,
    'progress.photos': false,
    'locations.enabled': true,
    'locations.max_workplaces': 1,
    'cloud_backup.enabled': false,
    'push_notifications.enabled': false,
    'subscription.enabled': false,
    'ai.enabled': false,
    'ai.workout_suggestions': false,
  };
}

class FeatureFlagService extends ChangeNotifier {
  static final instance = FeatureFlagService._();
  FeatureFlagService._();
  final Map<String, Object> _values = {...FeatureDefaults.values};
  bool _refreshing = false;
  FeatureConfigSource source = FeatureConfigSource.defaults;
  DateTime? lastSuccessfulSync;

  Future<void> loadLocalFlags() async {
    final cached = await AppDatabase.instance.buscarRemoteStatusCache();
    if (cached == null) return;
    _applyStatus(cached);
    source = FeatureConfigSource.localCache;
    lastSuccessfulSync = DateTime.tryParse(cached.updatedAt);
  }

  Future<void> refreshInBackground(
    AppUserModel user, {
    bool force = false,
  }) async {
    if (_refreshing) return;
    if (!force &&
        lastSuccessfulSync != null &&
        DateTime.now().difference(lastSuccessfulSync!) <
            const Duration(hours: 6)) {
      return;
    }
    _refreshing = true;
    try {
      final status = await AdminApiService.instance.verificarStatus(user);
      await AppDatabase.instance.salvarRemoteStatusCache(status);
      _applyStatus(status);
      source = FeatureConfigSource.remote;
      lastSuccessfulSync = DateTime.now();
      notifyListeners();
    } catch (_) {
      // Falha de rede/configuracao e condicao normal: preserve cache/defaults.
    } finally {
      _refreshing = false;
    }
  }

  void _applyStatus(AppRemoteStatusModel s) {
    _values['schedule.enabled'] = s.agendaEnabled;
    _values['cloud_backup.enabled'] = s.backupEnabled;
  }

  bool isEnabled(String key, {required bool defaultValue}) =>
      (_values[key] as bool?) ?? defaultValue;
  int getInt(String key, {required int defaultValue}) =>
      (_values[key] as int?) ?? defaultValue;
}
