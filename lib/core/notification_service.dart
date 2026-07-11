import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final dynamic timezoneResult = await FlutterTimezone.getLocalTimezone();
      String currentTimeZone;
      if (timezoneResult is String) {
        currentTimeZone = timezoneResult;
      } else {
        // Accessing .name as it's the IANA timezone ID (e.g., 'Asia/Kuala_Lumpur')
        currentTimeZone = timezoneResult.name;
      }
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (e) {
      // Fallback to a default timezone if local detection fails or returns invalid ID
      tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // 🎯 Request Android 13+ Notification Permission
    if (await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission() ?? false) {
      print("Notification permission granted");
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const String defaultTimeZone = 'Asia/Kuala_Lumpur';

    try {
      tz.setLocalLocation(tz.getLocation(defaultTimeZone));
    } catch (e) {
      print('Gagal menetapkan lokasi zon masa: $e');
    }

    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);
    await _plugin.zonedSchedule(
      // Tambah baris ini di dalam zonedSchedule
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      id,
      title,
      body,
      scheduledTZ,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meowtrack_reminders',
          'Meowtrack Reminders',
          channelDescription: 'Reminder notifications for cat appointments and care tasks',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meowtrack_alerts',
          'Meowtrack Alerts',
          channelDescription: 'Emergency and social notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}
