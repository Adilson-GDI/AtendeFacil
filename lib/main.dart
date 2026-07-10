import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'app/app_definition.dart';
import 'app/app_runtime.dart';
import 'app/relationship_platform_app.dart';
import 'core/app_theme_controller.dart';
import 'products/fitcheck/fitcheck_app_definition.dart';
import 'services/local_notification_service.dart';
import 'services/feature_flag_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppRuntime.configure(fitCheckDefinition);

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // O FitCheck precisa continuar abrindo mesmo sem Firebase configurado.
  }

  final themeController = AppThemeController();
  await themeController.carregarTema();
  await FeatureFlagService.instance.loadLocalFlags();

  await LocalNotificationService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDefinition>.value(value: fitCheckDefinition),
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: FeatureFlagService.instance),
      ],
      child: RelationshipPlatformApp(definition: fitCheckDefinition),
    ),
  );
}
