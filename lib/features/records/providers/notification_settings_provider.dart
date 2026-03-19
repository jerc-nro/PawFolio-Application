import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/pet_model.dart';
import '../../../models/record_model.dart';
import '../../../services/notification_services.dart';
import '../../auth/providers/auth_provider.dart';

const _kNotifEnabled = 'notifications_enabled';
const _kPermAsked = 'notifications_permission_asked';

class NotificationSettingsState {
  final bool enabled;
  final bool permissionAsked;
  final bool loading;

  const NotificationSettingsState({
    this.enabled = false,
    this.permissionAsked = false,
    this.loading = false,
  });

  NotificationSettingsState copyWith({
    bool? enabled,
    bool? permissionAsked,
    bool? loading,
  }) =>
      NotificationSettingsState(
        enabled: enabled ?? this.enabled,
        permissionAsked: permissionAsked ?? this.permissionAsked,
        loading: loading ?? this.loading,
      );
}

class NotificationSettingsController extends Notifier<NotificationSettingsState> {
  @override
  NotificationSettingsState build() {
    _load();
    return const NotificationSettingsState(loading: true);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kNotifEnabled) ?? false;
    final permAsked = prefs.getBool(_kPermAsked) ?? false;

    final allowed = await NotificationService.isAllowed();
    final actualEnabled = enabled && allowed;

    state = state.copyWith(
      enabled: actualEnabled,
      permissionAsked: permAsked,
      loading: false,
    );
  }

  /// Triggered on first launch to request native permissions.
  Future<void> askOnFirstLaunch() async {
    if (!state.permissionAsked) {
      final granted = await NotificationService.requestPermission();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPermAsked, true);
      await prefs.setBool(_kNotifEnabled, granted);
      
      state = state.copyWith(
        enabled: granted,
        permissionAsked: true,
      );

      if (granted) {
        await _rescheduleAll();
      }
    }
  }

  Future<void> toggle() async {
    state = state.copyWith(loading: true);
    try {
      if (state.enabled) {
        await _setEnabled(false);
        await NotificationService.cancelAll();
      } else {
        final allowed = await NotificationService.isAllowed();
        if (!allowed) {
          final granted = await NotificationService.requestPermission();
          await _markPermAsked();
          if (!granted) {
            state = state.copyWith(loading: false);
            return;
          }
        }
        await _setEnabled(true);
        await _rescheduleAll();
      }
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> _setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifEnabled, value);
    state = state.copyWith(enabled: value);
  }

  Future<void> _markPermAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPermAsked, true);
    state = state.copyWith(permissionAsked: true);
  }

  Future<void> _rescheduleAll() async {
    final uid = ref.read(authProvider).user?.userID;
    if (uid == null) return;

    await NotificationService.cancelAll();

    final firestore = FirebaseFirestore.instance;
    final petsSnap = await firestore
        .collection('users')
        .doc(uid)
        .collection('pets')
        .where('isArchived', isEqualTo: false)
        .where('isAlive', isEqualTo: true)
        .get();

    final collections = [
      'medications',
      'vaccinations',
      'preventatives',
      'vet_visits',
      'groom_visits',
    ];

    for (final petDoc in petsSnap.docs) {
      final pet = Pet.fromMap(petDoc.data(), petDoc.id);
      await NotificationService.scheduleBirthday(pet);

      for (final col in collections) {
        final recordsSnap = await firestore
            .collection('users')
            .doc(uid)
            .collection('pets')
            .doc(pet.petID)
            .collection(col)
            .where('status', isEqualTo: 'Upcoming')
            .get();

        for (final recordDoc in recordsSnap.docs) {
          final record = PetRecord.fromDoc(recordDoc, col);
          await NotificationService.scheduleForRecord(record);
        }
      }
    }
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsController, NotificationSettingsState>(
  () => NotificationSettingsController(),
);