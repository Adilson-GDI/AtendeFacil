import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final LocalNotificationService instance =
      LocalNotificationService._init();

  LocalNotificationService._init();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings: settings);

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> mostrarAgora({
    required String titulo,
    required String mensagem,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'lembretes_channel',
      'Lembretes',
      channelDescription: 'Notificações de lembretes do app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: titulo,
      body: mensagem,
      notificationDetails: details,
    );
  }

  Future<void> agendarLembrete({
    required int id,
    required String titulo,
    required String mensagem,
    required DateTime dataHora,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'lembretes_channel',
      'Lembretes',
      channelDescription: 'Notificações de lembretes do app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id: id,
      title: titulo,
      body: mensagem,
      scheduledDate: tz.TZDateTime.from(dataHora, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelarLembrete(int id) async {
    await _notifications.cancel(id: id);
  }

  Future<void> cancelarTodos() async {
    await _notifications.cancelAll();
  }
}
