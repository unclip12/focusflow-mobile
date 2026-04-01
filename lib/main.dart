import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/app_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/background_timer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Initialise notifications and request permission
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();
  await BackgroundTimerService.initialize();

  // Portrait-only layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load providers (reads SharedPreferences — fast)
  final appProvider = AppProvider();
  final settingsProvider = SettingsProvider();
  try {
    await appProvider.loadAll();
    await appProvider.seedPrayerRoutines();
  } catch (e) {
    debugPrint('loadAll failed — splash screen will handle DB init: $e');
  }
  await settingsProvider.loadSettings();

  // Schedule persistent daily notifications after data is ready
  _scheduleStartupNotifications(appProvider, settingsProvider);

  // ── UI is up immediately ──────────────────────────────────────
  // All heavy work (DB init, seeding FA/Sketchy/Pathoma/UWorld)
  // happens inside SplashScreen widget AFTER first frame renders.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<AppProvider>.value(value: appProvider),
      ],
      child: const FocusFlowApp(),
    ),
  );
}

/// Schedule all recurring daily notifications (fire-and-forget).
void _scheduleStartupNotifications(
  AppProvider app,
  SettingsProvider settings,
) {
  final ns = NotificationService.instance;
  final revisionCount = app.revisionItems
      .where((r) {
        final dt = DateTime.tryParse(r.nextRevisionAt);
        if (dt == null) return false;
        return dt.isBefore(DateTime.now().add(const Duration(days: 1)));
      })
      .length;

  // Daily 8 AM morning summary
  ns.scheduleMorningSummary(dueCount: revisionCount);

  // Daily 8 AM revision reminder (only if there are items due)
  if (revisionCount > 0) {
    ns.scheduleDailyRevisionReminder(revisionCount: revisionCount);
  }

  ns.syncPlannedTaskReminders(
    plans: app.dayPlans,
    config: settings.timerReminders,
  );
}

