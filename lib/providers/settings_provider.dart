// =============================================================
// SettingsProvider — ChangeNotifier wrapping AppSettings
// =============================================================

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/app_settings.dart';
import 'package:focusflow_mobile/services/database_service.dart';
import 'package:focusflow_mobile/utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings.defaults().copyWith(darkMode: false);
  bool _loaded = false;

  AppSettings get settings => _settings;
  bool get loaded => _loaded;

  // ── Convenience getters ────────────────────────────────────────
  String get currentTheme => _settings.themeId ?? 'default';
  bool get isDarkMode => _settings.darkMode;
  String get primaryColor => _settings.primaryColor;
  String get fontSize => _settings.fontSize;

  // ── G4: Bottom nav ────────────────────────────────────────────
  List<String> get pinnedTabs => _settings.pinnedTabs ?? kDefaultPinnedTabs;
  bool get fullScreenMode => _settings.fullScreenMode ?? false;

  Future<void> setPinnedTabs(List<String> tabs) async {
    _settings = _settings.copyWith(pinnedTabs: tabs);
    await _persist();
  }

  Future<void> setFullScreenMode(bool value) async {
    _settings = _settings.copyWith(fullScreenMode: value);
    await _persist();
  }

  // ── G10: Exam dates, daily routine ─────────────────────────────
  String get fmgeDate      => _settings.fmgeDate      ?? '2026-06-28';
  String get step1Date     => _settings.step1Date     ?? '2026-06-15';
  String get wakeTime      => _settings.wakeTime      ?? '06:00';
  String get sleepTime     => _settings.sleepTime     ?? '23:00';
  int    get dailyFAGoal   => _settings.dailyFAGoal   ?? 10;
  int    get ankiBatchSize => _settings.ankiBatchSize ?? 50;
  int    get dayStartHour  => _settings.dayStartHour  ?? 5;
  bool   get streakAutoCredit => _settings.streakAutoCredit ?? false;

  Future<void> setFmgeDate(String date) async {
    _settings = _settings.copyWith(fmgeDate: date);
    await _persist();
  }

  Future<void> setStep1Date(String date) async {
    _settings = _settings.copyWith(step1Date: date);
    await _persist();
  }

  Future<void> setWakeTime(String time) async {
    _settings = _settings.copyWith(wakeTime: time);
    await _persist();
  }

  Future<void> setSleepTime(String time) async {
    _settings = _settings.copyWith(sleepTime: time);
    await _persist();
  }

  Future<void> setDailyFAGoal(int pages) async {
    _settings = _settings.copyWith(dailyFAGoal: pages);
    await _persist();
  }

  Future<void> setAnkiBatchSize(int cards) async {
    _settings = _settings.copyWith(ankiBatchSize: cards);
    await _persist();
  }

  Future<void> setDayStartHour(int hour) async {
    _settings = _settings.copyWith(dayStartHour: hour);
    await _persist();
  }

  Future<void> setStreakAutoCredit(bool value) async {
    _settings = _settings.copyWith(streakAutoCredit: value);
    await _persist();
  }

  // ── Study Plan Start Date ─────────────────────────────────────
  String? get studyPlanStartDate => _settings.studyPlanStartDate;

  Future<void> setStudyPlanStartDate(String date) async {
    _settings = _settings.copyWith(studyPlanStartDate: date);
    await _persist();
  }

  /// Auto-initialise study plan start date if not already set.
  Future<void> ensureStudyPlanStartDate() async {
    if (_settings.studyPlanStartDate == null) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await setStudyPlanStartDate(today);
    }
  }

  // ── Load from storage ─────────────────────────────────────────
  Future<void> loadSettings() async {
    final json = await DatabaseService.instance.getSettings();
    if (json != null) {
      var data = Map<String, dynamic>.from(json);
      if (!data.containsKey('darkMode')) {
        data['darkMode'] = false;
      }
      _settings = AppSettings.fromJson(data);
    } else {
      _settings = AppSettings.defaults().copyWith(darkMode: false);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await DatabaseService.instance.saveSettings(_settings.toJson());
    notifyListeners();
  }

  // ── Theme ──────────────────────────────────────────────────────
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

  // ── Accent Color ───────────────────────────────────────────────
  Future<void> changePrimaryColor(String color) async {
    _settings = _settings.copyWith(primaryColor: color);
    await _persist();
  }

  // ── Font Size ──────────────────────────────────────────────────
  Future<void> changeFontSize(String size) async {
    _settings = _settings.copyWith(fontSize: size);
    await _persist();
  }

  // ── Menu Configuration ─────────────────────────────────────────
  Future<void> updateMenuConfig(List<MenuItemConfig> config) async {
    _settings = _settings.copyWith(menuConfiguration: config);
    await _persist();
  }

  List<MenuItemConfig> get menuConfiguration =>
      _settings.menuConfiguration ?? [];

  // ── Notifications ──────────────────────────────────────────────
  Future<void> updateNotifications(NotificationConfig config) async {
    _settings = _settings.copyWith(notifications: config);
    await _persist();
  }

  Future<void> updateQuietHours(QuietHoursConfig config) async {
    _settings = _settings.copyWith(quietHours: config);
    await _persist();
  }

  // ── Anki ───────────────────────────────────────────────────────
  Future<void> updateAnkiHost(String host) async {
    _settings = _settings.copyWith(ankiHost: host);
    await _persist();
  }

  Future<void> updateAnkiTagPrefix(String prefix) async {
    _settings = _settings.copyWith(ankiTagPrefix: prefix);
    await _persist();
  }

  // ── Full replace (backup restore) ──────────────────────────────
  Future<void> replaceSettings(AppSettings s) async {
    _settings = s;
    await _persist();
  }
}
