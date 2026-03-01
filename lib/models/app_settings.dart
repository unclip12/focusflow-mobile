// =============================================================
// AppSettings, NotificationConfig, QuietHoursConfig, MenuItemConfig
// =============================================================

import 'package:focusflow_mobile/utils/constants.dart';

class MenuItemConfig {
  final String id;
  final bool visible;

  const MenuItemConfig({required this.id, required this.visible});

  factory MenuItemConfig.fromJson(Map<String, dynamic> j) => MenuItemConfig(
        id: j['id'] ?? '',
        visible: j['visible'] ?? true,
      );

  Map<String, dynamic> toJson() => {'id': id, 'visible': visible};

  MenuItemConfig copyWith({String? id, bool? visible}) => MenuItemConfig(
        id: id ?? this.id,
        visible: visible ?? this.visible,
      );
}

class NotificationConfig {
  final bool enabled;
  final String mode;
  final Map<String, bool> types;

  const NotificationConfig({
    required this.enabled,
    required this.mode,
    required this.types,
  });

  factory NotificationConfig.fromJson(Map<String, dynamic> j) =>
      NotificationConfig(
        enabled: j['enabled'] ?? true,
        mode: j['mode'] ?? 'normal',
        types: j['types'] != null
            ? Map<String, bool>.from(j['types'])
            : const {'blockTimers': true, 'breaks': true, 'mentorNudges': true, 'dailySummary': true},
      );

  factory NotificationConfig.defaults() => const NotificationConfig(
        enabled: true,
        mode: 'normal',
        types: {'blockTimers': true, 'breaks': true, 'mentorNudges': true, 'dailySummary': true},
      );

  Map<String, dynamic> toJson() => {'enabled': enabled, 'mode': mode, 'types': types};

  NotificationConfig copyWith({bool? enabled, String? mode, Map<String, bool>? types}) =>
      NotificationConfig(
        enabled: enabled ?? this.enabled,
        mode: mode ?? this.mode,
        types: types ?? this.types,
      );
}

class QuietHoursConfig {
  final bool enabled;
  final String start;
  final String end;

  const QuietHoursConfig({required this.enabled, required this.start, required this.end});

  factory QuietHoursConfig.fromJson(Map<String, dynamic> j) => QuietHoursConfig(
        enabled: j['enabled'] ?? false,
        start: j['start'] ?? '22:00',
        end: j['end'] ?? '07:00',
      );

  factory QuietHoursConfig.defaults() =>
      const QuietHoursConfig(enabled: false, start: '22:00', end: '07:00');

  Map<String, dynamic> toJson() => {'enabled': enabled, 'start': start, 'end': end};

  QuietHoursConfig copyWith({bool? enabled, String? start, String? end}) => QuietHoursConfig(
        enabled: enabled ?? this.enabled,
        start: start ?? this.start,
        end: end ?? this.end,
      );
}

class AppSettings {
  final bool darkMode;
  final String? themeId;
  final String primaryColor;
  final String fontSize;
  final NotificationConfig notifications;
  final QuietHoursConfig quietHours;
  final String? ankiHost;
  final String? ankiTagPrefix;
  final String? desktopLayout;
  final List<MenuItemConfig>? menuConfiguration;
  // G4: bottom nav customisation
  final List<String>? pinnedTabs;
  final bool? fullScreenMode;

  // G10: Exam dates (stored as 'yyyy-MM-dd' strings)
  final String? fmgeDate;
  final String? step1Date;

  // G10: Daily routine
  final String? wakeTime;
  final String? sleepTime;
  final int? dailyFAGoal;
  final int? ankiBatchSize;

  // Streak system
  final int? dayStartHour;      // hour (0-23) when study day starts (default 5 = 5 AM)
  final bool? streakAutoCredit;  // auto-deduct credits on missed target

  // Study plan start date — auto-set on first FA page read, editable in settings
  final String? studyPlanStartDate; // ISO8601 date (yyyy-MM-dd)

  const AppSettings({
    required this.darkMode,
    this.themeId,
    required this.primaryColor,
    required this.fontSize,
    required this.notifications,
    required this.quietHours,
    this.ankiHost,
    this.ankiTagPrefix,
    this.desktopLayout,
    this.menuConfiguration,
    this.pinnedTabs,
    this.fullScreenMode,
    this.fmgeDate,
    this.step1Date,
    this.wakeTime,
    this.sleepTime,
    this.dailyFAGoal,
    this.ankiBatchSize,
    this.dayStartHour,
    this.streakAutoCredit,
    this.studyPlanStartDate,
  });

  factory AppSettings.defaults() => AppSettings(
        darkMode: false,
        themeId: 'default',
        primaryColor: 'indigo',
        fontSize: 'medium',
        notifications: NotificationConfig.defaults(),
        quietHours: QuietHoursConfig.defaults(),
        ankiHost: 'http://localhost:8765',
        ankiTagPrefix: 'FA_Page::',
        menuConfiguration: kDefaultMenuOrder
            .map((id) => MenuItemConfig(id: id, visible: true))
            .toList(),
        pinnedTabs: kDefaultPinnedTabs,
        fullScreenMode: false,
        fmgeDate: '2026-06-28',
        step1Date: '2026-06-15',
        wakeTime: '06:00',
        sleepTime: '23:00',
        dailyFAGoal: 10,
        ankiBatchSize: 50,
        dayStartHour: 5,
        streakAutoCredit: false,
        studyPlanStartDate: null,
      );

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        darkMode: j['darkMode'] ?? false,
        themeId: j['themeId'],
        primaryColor: j['primaryColor'] ?? 'indigo',
        fontSize: j['fontSize'] ?? 'medium',
        notifications: j['notifications'] != null
            ? NotificationConfig.fromJson(j['notifications'])
            : NotificationConfig.defaults(),
        quietHours: j['quietHours'] != null
            ? QuietHoursConfig.fromJson(j['quietHours'])
            : QuietHoursConfig.defaults(),
        ankiHost: j['ankiHost'],
        ankiTagPrefix: j['ankiTagPrefix'],
        desktopLayout: j['desktopLayout'],
        menuConfiguration: j['menuConfiguration'] != null
            ? (j['menuConfiguration'] as List)
                .map((m) => MenuItemConfig.fromJson(m))
                .toList()
            : null,
        pinnedTabs: j['pinnedTabs'] != null
            ? List<String>.from(j['pinnedTabs'] as List)
            : null,
        fullScreenMode: j['fullScreenMode'] as bool?,
        fmgeDate: j['fmgeDate'] as String?,
        step1Date: j['step1Date'] as String?,
        wakeTime: j['wakeTime'] as String?,
        sleepTime: j['sleepTime'] as String?,
        dailyFAGoal: j['dailyFAGoal'] as int?,
        ankiBatchSize: j['ankiBatchSize'] as int?,
        dayStartHour: j['dayStartHour'] as int?,
        streakAutoCredit: j['streakAutoCredit'] as bool?,
        studyPlanStartDate: j['studyPlanStartDate'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'darkMode': darkMode,
        if (themeId != null) 'themeId': themeId,
        'primaryColor': primaryColor,
        'fontSize': fontSize,
        'notifications': notifications.toJson(),
        'quietHours': quietHours.toJson(),
        if (ankiHost != null) 'ankiHost': ankiHost,
        if (ankiTagPrefix != null) 'ankiTagPrefix': ankiTagPrefix,
        if (desktopLayout != null) 'desktopLayout': desktopLayout,
        if (menuConfiguration != null)
          'menuConfiguration':
              menuConfiguration!.map((m) => m.toJson()).toList(),
        if (pinnedTabs != null) 'pinnedTabs': pinnedTabs,
        if (fullScreenMode != null) 'fullScreenMode': fullScreenMode,
        if (fmgeDate != null) 'fmgeDate': fmgeDate,
        if (step1Date != null) 'step1Date': step1Date,
        if (wakeTime != null) 'wakeTime': wakeTime,
        if (sleepTime != null) 'sleepTime': sleepTime,
        if (dailyFAGoal != null) 'dailyFAGoal': dailyFAGoal,
        if (ankiBatchSize != null) 'ankiBatchSize': ankiBatchSize,
        if (dayStartHour != null) 'dayStartHour': dayStartHour,
        if (streakAutoCredit != null) 'streakAutoCredit': streakAutoCredit,
        if (studyPlanStartDate != null) 'studyPlanStartDate': studyPlanStartDate,
      };

  AppSettings copyWith({
    bool? darkMode,
    String? themeId,
    String? primaryColor,
    String? fontSize,
    NotificationConfig? notifications,
    QuietHoursConfig? quietHours,
    String? ankiHost,
    String? ankiTagPrefix,
    String? desktopLayout,
    List<MenuItemConfig>? menuConfiguration,
    List<String>? pinnedTabs,
    bool? fullScreenMode,
    String? fmgeDate,
    String? step1Date,
    String? wakeTime,
    String? sleepTime,
    int? dailyFAGoal,
    int? ankiBatchSize,
    int? dayStartHour,
    bool? streakAutoCredit,
    String? studyPlanStartDate,
  }) =>
      AppSettings(
        darkMode: darkMode ?? this.darkMode,
        themeId: themeId ?? this.themeId,
        primaryColor: primaryColor ?? this.primaryColor,
        fontSize: fontSize ?? this.fontSize,
        notifications: notifications ?? this.notifications,
        quietHours: quietHours ?? this.quietHours,
        ankiHost: ankiHost ?? this.ankiHost,
        ankiTagPrefix: ankiTagPrefix ?? this.ankiTagPrefix,
        desktopLayout: desktopLayout ?? this.desktopLayout,
        menuConfiguration: menuConfiguration ?? this.menuConfiguration,
        pinnedTabs: pinnedTabs ?? this.pinnedTabs,
        fullScreenMode: fullScreenMode ?? this.fullScreenMode,
        fmgeDate: fmgeDate ?? this.fmgeDate,
        step1Date: step1Date ?? this.step1Date,
        wakeTime: wakeTime ?? this.wakeTime,
        sleepTime: sleepTime ?? this.sleepTime,
        dailyFAGoal: dailyFAGoal ?? this.dailyFAGoal,
        ankiBatchSize: ankiBatchSize ?? this.ankiBatchSize,
        dayStartHour: dayStartHour ?? this.dayStartHour,
        streakAutoCredit: streakAutoCredit ?? this.streakAutoCredit,
        studyPlanStartDate: studyPlanStartDate ?? this.studyPlanStartDate,
      );
}
