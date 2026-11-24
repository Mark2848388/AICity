import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/task.dart';

/// Локальные уведомления + заготовка под FCM.
/// На телефоне работают сразу после разрешения.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // iOS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  Future<void> showTaskCompleted(Task task) async {
    await _show(
      id: task.id.hashCode,
      title: 'Задача выполнена ✅',
      body: task.title + (task.result != null ? '\n${task.result}' : ''),
      payload: 'task:${task.id}',
    );
  }

  Future<void> showTaskFailed(Task task) async {
    await _show(
      id: task.id.hashCode,
      title: 'Ошибка выполнения ❌',
      body: '${task.title}\n${task.error ?? "Неизвестная ошибка"}',
      payload: 'task:${task.id}',
    );
  }

  Future<void> showApkReady({required String repo, required String downloadUrl}) async {
    await _show(
      id: downloadUrl.hashCode,
      title: 'APK готов 📦',
      body: '$repo\nМожно скачивать',
      payload: 'apk:$downloadUrl',
    );
  }

  Future<void> showProgress(String title, int percent) async {
    await _show(
      id: title.hashCode,
      title: 'Прогресс: $percent%',
      body: title,
    );
  }

  Future<void> showSimple(String title, String body) async {
    await _show(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: body,
    );
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'agent_city_tasks',
      'Задачи агентов',
      channelDescription: 'Уведомления о статусе задач AI-агентов и сборках APK',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(id, title, body, details, payload: payload);
  }
}
