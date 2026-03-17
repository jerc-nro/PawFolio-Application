import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb; // Added for Web safety

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future init() async {
    if (kIsWeb) return; // ✅ Prevents crash on Web

    tz.initializeTimeZones();
    
    // Change this to 'pawfolio' to match your drawable file!
    const androidInit = AndroidInitializationSettings('pawfolio_logo'); 
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'pet_reminders', 
          'Pet App Reminders',
          description: 'Notifications for birthdays, meds, and events',
          importance: Importance.max,
        ));

    await _notifications.initialize(
      const InitializationSettings(android: androidInit),
    );
  }

  static Future<bool> isAllowed() async {
    if (kIsWeb) return false;
    final bool? granted = await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return granted ?? false;
  }

  // ✅ Keeps your APK safe while allowing Web debugging
  static Future cancelAll() async {
    if (kIsWeb) return; 
    await _notifications.cancelAll();
  }

  // ✅ Used when a specific record or pet is deleted
  static Future cancel(int id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }

  static Future schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    DateTimeComponents? matchComponents,
  }) async {
    if (kIsWeb) return;

    var scheduleTime = tz.TZDateTime.from(scheduledDate, tz.local);
    if (scheduleTime.isBefore(tz.TZDateTime.now(tz.local))) {
      if (matchComponents == DateTimeComponents.dateAndTime) {
        scheduleTime = scheduleTime.add(const Duration(days: 365));
      } else {
        return; 
      }
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduleTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pet_reminders', 
          'Pet App Reminders',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'pawfolio_logo', // ✅ Use your custom drawable icon here
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents,
    );
  }

  // ========== TO BE DELETED WHEN TESTING IS DONE ==========

static Future<void> showTestNotification() async {
  if (kIsWeb) return;

  await _notifications.zonedSchedule(
    999,
    "Test Notification! 🐾",
    "If you see this, your icon and channel are working perfectly.",
    tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'pet_reminders',
        'Pet App Reminders',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'pawfolio_logo', 
      ),
    ),
    // ❌ Change this:
    // androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    // ✅ To this:
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, 
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}
}