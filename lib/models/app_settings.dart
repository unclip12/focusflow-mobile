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
      );
}
