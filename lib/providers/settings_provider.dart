// =============================================================
// SettingsProvider — ChangeNotifier wrapping AppSettings
// Loaded from DatabaseService, drives theme in app.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/app_settings.dart';
import 'package:focusflow_mobile/services/database_service.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings.defaults();
  bool _loaded = false;

  AppSettings get settings => _settings;
  bool get loaded => _loaded;

  // ── Convenience getters used by app.dart ───────────────────────
  String get currentTheme => _settings.themeId ?? 'default';
  bool get isDarkMode => _settings.darkMode;
  String get primaryColor => _settings.primaryColor;
  String get fontSize => _settings.fontSize;

  // ── Load from SQLite ──────────────────────────────────────────
  Future<void> loadSettings() async {
    final json = await DatabaseService.instance.getSettings();
    if (json != null) {
      _settings = AppSettings.fromJson(json);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await DatabaseService.instance.saveSettings(_settings.toJson());
    notifyListeners();
  }

  // ── Theme ─────────────────────────────────────────────────────
  Future<void> changeTheme(String themeId) async {
    _settings = _settings.copyWith(themeId: themeId);
    await _persist();
  }

  Future<void> toggleDarkMode() async {
    _settings = _settings.copyWith(darkMode: !_settings.darkMode);
    await _persist();
  }

  Future<void> setDarkMode(bool value) async {
    _settings = _settings.copyWith(darkMode: value);
    await _persist();
  }

  // ── Accent Color ──────────────────────────────────────────────
  Future<void> changePrimaryColor(String color) async {
    _settings = _settings.copyWith(primaryColor: color);
    await _persist();
  }

  // ── Font Size ─────────────────────────────────────────────────
  Future<void> changeFontSize(String size) async {
    _settings = _settings.copyWith(fontSize: size);
    await _persist();
  }

  // ── Menu Configuration ────────────────────────────────────────
  Future<void> updateMenuConfig(List<MenuItemConfig> config) async {
    _settings = _settings.copyWith(menuConfiguration: config);
    await _persist();
  }

  List<MenuItemConfig> get menuConfiguration =>
      _settings.menuConfiguration ?? [];

  // ── Notifications ─────────────────────────────────────────────
  Future<void> updateNotifications(NotificationConfig config) async {
    _settings = _settings.copyWith(notifications: config);
    await _persist();
  }

  Future<void> updateQuietHours(QuietHoursConfig config) async {
    _settings = _settings.copyWith(quietHours: config);
    await _persist();
  }

  // ── Anki ──────────────────────────────────────────────────────
  Future<void> updateAnkiHost(String host) async {
    _settings = _settings.copyWith(ankiHost: host);
    await _persist();
  }

  Future<void> updateAnkiTagPrefix(String prefix) async {
    _settings = _settings.copyWith(ankiTagPrefix: prefix);
    await _persist();
  }

  // ── Full replace (backup restore) ─────────────────────────────
  Future<void> replaceSettings(AppSettings s) async {
    _settings = s;
    await _persist();
  }
}
