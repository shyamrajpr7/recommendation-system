import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _darkModeKey = 'settings_dark_mode';
  static const _notificationsKey = 'settings_notifications';
  static const _autoPlayKey = 'settings_autoplay';
  static const _locationKey = 'settings_location';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  bool get darkMode => _prefs.getBool(_darkModeKey) ?? true;
  bool get notifications => _prefs.getBool(_notificationsKey) ?? true;
  bool get autoPlayTrailers => _prefs.getBool(_autoPlayKey) ?? false;
  bool get locationEnabled => _prefs.getBool(_locationKey) ?? true;

  Future<void> setDarkMode(bool value) => _prefs.setBool(_darkModeKey, value);
  Future<void> setNotifications(bool value) => _prefs.setBool(_notificationsKey, value);
  Future<void> setAutoPlayTrailers(bool value) => _prefs.setBool(_autoPlayKey, value);
  Future<void> setLocationEnabled(bool value) => _prefs.setBool(_locationKey, value);
}

final settingsServiceProvider = FutureProvider<SettingsService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return SettingsService(prefs);
});

final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier(ref);
});

class DarkModeNotifier extends StateNotifier<bool> {
  final Ref _ref;

  DarkModeNotifier(this._ref) : super(true) {
    _load();
  }

  Future<void> _load() async {
    final service = await _ref.read(settingsServiceProvider.future);
    state = service.darkMode;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final service = await _ref.read(settingsServiceProvider.future);
    await service.setDarkMode(value);
  }
}

extension ThemeModeX on WidgetRef {
  ThemeMode get themeMode => watch(darkModeProvider) ? ThemeMode.dark : ThemeMode.light;
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, bool>((ref) {
  return NotificationsNotifier(ref);
});

class NotificationsNotifier extends StateNotifier<bool> {
  final Ref _ref;

  NotificationsNotifier(this._ref) : super(true) {
    _load();
  }

  Future<void> _load() async {
    final service = await _ref.read(settingsServiceProvider.future);
    state = service.notifications;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final service = await _ref.read(settingsServiceProvider.future);
    await service.setNotifications(value);
  }
}

final autoPlayTrailersProvider = StateNotifierProvider<AutoPlayTrailersNotifier, bool>((ref) {
  return AutoPlayTrailersNotifier(ref);
});

class AutoPlayTrailersNotifier extends StateNotifier<bool> {
  final Ref _ref;

  AutoPlayTrailersNotifier(this._ref) : super(false) {
    _load();
  }

  Future<void> _load() async {
    final service = await _ref.read(settingsServiceProvider.future);
    state = service.autoPlayTrailers;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final service = await _ref.read(settingsServiceProvider.future);
    await service.setAutoPlayTrailers(value);
  }
}

final locationServicesProvider = StateNotifierProvider<LocationServicesNotifier, bool>((ref) {
  return LocationServicesNotifier(ref);
});

class LocationServicesNotifier extends StateNotifier<bool> {
  final Ref _ref;

  LocationServicesNotifier(this._ref) : super(true) {
    _load();
  }

  Future<void> _load() async {
    final service = await _ref.read(settingsServiceProvider.future);
    state = service.locationEnabled;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final service = await _ref.read(settingsServiceProvider.future);
    await service.setLocationEnabled(value);
  }
}
