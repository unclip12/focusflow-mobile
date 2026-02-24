import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'utils/app_theme.dart';
import 'app_router.dart';

/// Root widget — wires theme + router together.
/// Theme is driven by SettingsProvider (12 themes, dark mode, accent colour).
/// Router is defined in app_router.dart (GoRouter — Batch 4).
class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp.router(
      title: 'FocusFlow',
      theme: AppTheme.getTheme(
        settings.currentTheme,
        settings.isDarkMode,
        settings.primaryColor,
        settings.fontSize,
      ),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
