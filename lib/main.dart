import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/app_provider.dart';
import 'providers/settings_provider.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/seed_service.dart';
import 'services/uworld_seed.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise local notifications
  await NotificationService.instance.init();

  // Initialise SQLite — creates all tables on first run
  await DatabaseService.instance.database;

  // Seed FA 2025 pages from bundled JSON on first launch
  await SeedService.seedIfNeeded();

  // Seed UWorld Data (V4)
  await DatabaseService.instance.seedUWorld(uworldSeed);

  // Portrait-only layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Create providers first
  final appProvider = AppProvider();
  final settingsProvider = SettingsProvider();
  
  // Load all persisted data BEFORE rendering any UI
  await appProvider.loadAll();
  await settingsProvider.loadSettings();

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
