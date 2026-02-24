import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/app_provider.dart';
import 'providers/settings_provider.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise SQLite — creates all tables on first run
  await DatabaseService.instance.database;

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
