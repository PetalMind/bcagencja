import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'favorites_provider.dart';

const String _keyPushEnabled = 'notif_push_enabled';
const String _keyEmailEnabled = 'notif_email_enabled';
const String _keyEmailAddress = 'notif_email_address';

/// Preferencje powiadomień: push, email (mock – zapis lokalny; wysyłka wymaga backendu).
class NotificationPreferences {
  const NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.emailAddress,
  });

  final bool pushEnabled;
  final bool emailEnabled;
  final String? emailAddress;

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    String? emailAddress,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      emailAddress: emailAddress ?? this.emailAddress,
    );
  }
}

class NotificationPreferencesNotifier extends Notifier<NotificationPreferences> {
  @override
  NotificationPreferences build() => const NotificationPreferences();

  SharedPreferences? get _prefs => ref.read(sharedPreferencesProvider);

  Future<void> _load() async {
    final prefs = _prefs;
    if (prefs == null) return;
    state = NotificationPreferences(
      pushEnabled: prefs.getBool(_keyPushEnabled) ?? true,
      emailEnabled: prefs.getBool(_keyEmailEnabled) ?? true,
      emailAddress: prefs.getString(_keyEmailAddress),
    );
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_keyPushEnabled, state.pushEnabled);
    await prefs.setBool(_keyEmailEnabled, state.emailEnabled);
    if (state.emailAddress != null) {
      await prefs.setString(_keyEmailAddress, state.emailAddress as String);
    } else {
      await prefs.remove(_keyEmailAddress);
    }
  }

  Future<void> initialize() async => _load();

  Future<void> setPushEnabled(bool value) async {
    state = state.copyWith(pushEnabled: value);
    await _save();
  }

  Future<void> setEmailEnabled(bool value) async {
    state = state.copyWith(emailEnabled: value);
    await _save();
  }

  Future<void> setEmailAddress(String? value) async {
    state = state.copyWith(emailAddress: value?.trim().isEmpty == true ? null : value);
    await _save();
  }
}

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
  NotificationPreferencesNotifier.new,
);
