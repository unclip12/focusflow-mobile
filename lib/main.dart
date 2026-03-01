import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/app_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only lightweight, truly necessary init before UI
  await NotificationService.instance.init();

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
