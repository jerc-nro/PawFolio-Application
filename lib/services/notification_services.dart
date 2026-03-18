import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/pet_model.dart';
import '../models/record_model.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'pet_reminders';
  static const _channelName = 'Pet Reminders';
  static const _icon        = 'pawfolio_logo';

  // ─── Init ─────────────────────────────────────────────────────────────────
static Future<void> init() async {
  if (kIsWeb) return;

  // 1. Initialize Timezones
  tz.initializeTimeZones();

  // 2. Setup Android Initialization Settings
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings(_icon);

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await _notifications.initialize(initializationSettings);

  // 3. Resolve Platform Specific Implementation (Fixed Syntax)
  final android = _notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  // 4. Request Permissions & Create Channel
  if (android != null) {
    // Note: This requests the 'POST_NOTIFICATIONS' permission on Android 13+
    await android.requestNotificationsPermission();

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Reminders for pet birthdays, medications, vet visits, and more.',
        importance: Importance.max,
      ),
    );
  }
}

  static Future<bool> isAllowed() async {
    if (kIsWeb) return false;
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    
    // Checks if the user has granted the notification permission
    return await android.areNotificationsEnabled() ?? false;
  }
  // ─── Cancel ───────────────────────────────────────────────────────────────
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  static Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }

  // ─── Low-level scheduler ──────────────────────────────────────────────────
  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    DateTimeComponents? matchComponents,
  }) async {
    if (kIsWeb) return;

    var scheduleTime = tz.TZDateTime.from(scheduledDate, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    if (scheduleTime.isBefore(now)) {
      if (matchComponents == DateTimeComponents.dateAndTime) {
        scheduleTime = tz.TZDateTime(
          tz.local,
          scheduleTime.year + 1,
          scheduleTime.month,
          scheduleTime.day,
          scheduleTime.hour,
          scheduleTime.minute,
        );
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
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          icon: _icon,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents,
    );
  }

  // ─── Immediate notification ────────────────────────────────────────────────
  static Future<void> _showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          icon: _icon,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC: Test notifications (fires immediately)
  // ─────────────────────────────────────────────────────────────────────────

  /// Fires a real upcoming medication record notification immediately.
  /// Falls back to sample data if no upcoming records exist.
  static Future<void> testMedicationReminder({
    String petName = 'Buddy',
    String medName = 'Amoxicillin',
  }) =>
      _showNow(
        id: 9001,
        title: '💊 Medication Reminder — $petName',
        body: "Time to give $petName their $medName. Don't skip a dose!",
      );

  static Future<void> testVetVisitReminder({
    String petName = 'Luna',
  }) =>
      _showNow(
        id: 9002,
        title: '🏥 Vet Visit Tomorrow — $petName',
        body:
            "$petName's vet appointment is tomorrow. Prepare any questions and bring their records.",
      );

  static Future<void> testBirthdayReminder({
    String petName = 'Mochi',
  }) =>
      _showNow(
        id: 9003,
        title: '🎂 Happy Birthday, $petName!',
        body:
            "Today is $petName's special day! Give them extra love and maybe a treat. 🐾",
      );

  /// Fire an immediate overdue alert summarising all overdue records.
  static Future<void> showOverdueAlert({
    required int overdueCount,
    required List<String> petNames,
  }) async {
    if (kIsWeb) return;
    final names = petNames.toSet().join(', ');
    await _showNow(
      id: 9999,
      title: '⚠️ $overdueCount overdue record${overdueCount > 1 ? 's' : ''}',
      body: overdueCount == 1
          ? 'You have 1 overdue record for $names. Tap to review.'
          : 'You have $overdueCount overdue records across: $names. Tap to review.',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC: Schedule from a PetRecord
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> scheduleForRecord(PetRecord record) async {
    if (kIsWeb) return;
    final reminder = record.reminderDate;
    if (reminder == null) return;

    final msg = _buildMessage(record);

    await _schedule(
      id: record.notificationId,
      title: msg.title,
      body: msg.body,
      scheduledDate: reminder,
    );

    final endDate = record.medicationEndDate;
    if (endDate != null) {
      final endReminder =
          DateTime(endDate.year, endDate.month, endDate.day, 9, 0);
      await _schedule(
        id: record.notificationId + 1,
        title: '💊 Last dose today — ${record.petName}',
        body:
            'Today is the final day of ${record.title} for ${record.petName}. Make sure they get their last dose!',
        scheduledDate: endReminder,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC: Schedule annual birthday reminder
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> scheduleBirthday(Pet pet) async {
    if (kIsWeb) return;
    final dob = pet.birthDateTime;
    if (dob == null) return;

    final birthdayThisYear =
        DateTime(DateTime.now().year, dob.month, dob.day, 8, 0);

    await _schedule(
      id: pet.birthdayNotifyId,
      title: '🎂 Happy Birthday, ${pet.name}!',
      body:
          "Today is ${pet.name}'s special day! Give them extra love and maybe a treat. 🐾",
      scheduledDate: birthdayThisYear,
      matchComponents: DateTimeComponents.dateAndTime,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC: Cancel all notifications tied to a record
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> cancelForRecord(PetRecord record) async {
    await cancel(record.notificationId);
    if (record.category == 'Medication') {
      await cancel(record.notificationId + 1);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE: Build title + body per category
  // ─────────────────────────────────────────────────────────────────────────
  static _Msg _buildMessage(PetRecord r) {
    final name  = r.petName;
    final title = r.title;

    switch (r.category) {
      case 'Medication':
        return _Msg(
          title: '💊 Medication reminder — $name',
          body:  "Time to give $name their $title. Don't skip a dose!",
        );
      case 'Vaccination':
        return _Msg(
          title: '💉 Vaccination tomorrow — $name',
          body:
              "$name's $title vaccination is scheduled for tomorrow. Make sure they're ready!",
        );
      case 'Vet Visit':
        return _Msg(
          title: '🏥 Vet visit tomorrow — $name',
          body:
              "$name's vet appointment is tomorrow. Prepare any questions and bring their records.",
        );
      case 'Grooming':
        return _Msg(
          title: '✂️ Grooming session tomorrow — $name',
          body:
              "$name has a grooming appointment tomorrow. Time to get pampered! 🛁",
        );
      case 'Preventative':
        return _Msg(
          title: '🛡️ Preventative care due — $name',
          body:
              "$name's $title is scheduled for tomorrow. Stay on top of their protection!",
        );
      default:
        return _Msg(
          title: '🐾 Reminder for $name',
          body:  'You have an upcoming $title for $name.',
        );
    }
  }
}

class _Msg {
  final String title, body;
  const _Msg({required this.title, required this.body});
}