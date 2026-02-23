import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'utils/app_theme.dart';
import 'app_router.dart';

class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final theme = AppTheme.buildTheme(
          themeName: settings.themeName,
          accentColor: settings.accentColor,
          isDark: settings.isDarkMode,
          fontSize: settings.fontSize,
        );
        return MaterialApp.router(
          title: 'FocusFlow',
          theme: theme,
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
