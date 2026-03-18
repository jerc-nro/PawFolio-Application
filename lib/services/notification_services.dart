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

    tz.initializeTimeZones();

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Reminders for pet birthdays, medications, vet visits, and more.',
          importance: Importance.max,
        ));

    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
      ),
    );
  }

  // ─── Permission check ─────────────────────────────────────────────────────
  static Future<bool> isAllowed() async {
    if (kIsWeb) return false;
    final granted = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return granted ?? false;
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
        // Annual repeat — push to next year
        scheduleTime = tz.TZDateTime(
          tz.local,
          scheduleTime.year + 1,
          scheduleTime.month,
          scheduleTime.day,
          scheduleTime.hour,
          scheduleTime.minute,
        );
      } else {
        // One-time notification already passed — skip
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

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC: Schedule from a PetRecord
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> scheduleForRecord(PetRecord record) async {
    if (kIsWeb) return;
    final reminder = record.reminderDate;
    if (reminder == null) return;

    final _Msg msg = _buildMessage(record);

    await _schedule(
      id:            record.notificationId,
      title:         msg.title,
      body:          msg.body,
      scheduledDate: reminder,
    );

    // For medications: also notify on the last day of the course
    final endDate = record.medicationEndDate;
    if (endDate != null) {
      final endReminder = DateTime(
          endDate.year, endDate.month, endDate.day, 9, 0);
      await _schedule(
        id:            record.notificationId + 1,
        title:         '💊 Last dose today — ${record.petName}',
        body:          "Today is the final day of ${record.title} for ${record.petName}. Make sure they get their last dose!",
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

    // Fire at 8:00 AM every year on the pet's birthday
    final birthdayThisYear = DateTime(
      DateTime.now().year, dob.month, dob.day, 8, 0,
    );

    await _schedule(
      id:              pet.birthdayNotifyId,
      title:           '🎂 Happy Birthday, ${pet.name}!',
      body:            "Today is ${pet.name}'s special day! Give them extra love and maybe a treat. 🐾",
      scheduledDate:   birthdayThisYear,
      matchComponents: DateTimeComponents.dateAndTime,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC: Cancel all notifications tied to a record
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> cancelForRecord(PetRecord record) async {
    await cancel(record.notificationId);
    // Also cancel the medication end-of-course notification if present
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
          body:  "$name's $title vaccination is scheduled for tomorrow. Make sure they're ready!",
        );

      case 'Vet Visit':
        return _Msg(
          title: '🏥 Vet visit tomorrow — $name',
          body:  "$name's vet appointment is tomorrow. Prepare any questions and bring their records.",
        );

      case 'Grooming':
        return _Msg(
          title: '✂️ Grooming session tomorrow — $name',
          body:  "$name has a grooming appointment tomorrow. Time to get pampered! 🛁",
        );

      case 'Preventative':
        return _Msg(
          title: '🛡️ Preventative care due — $name',
          body:  "$name's $title is scheduled for tomorrow. Stay on top of their protection!",
        );

      default:
        return _Msg(
          title: '🐾 Reminder for $name',
          body:  "You have an upcoming $title for $name.",
        );
    }
  }
}

// ─── Internal message model ───────────────────────────────────────────────────
class _Msg {
  final String title, body;
  const _Msg({required this.title, required this.body});
}