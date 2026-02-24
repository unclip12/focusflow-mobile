import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
      builder: (context, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            
            final location = GoRouterState.of(context).uri.toString();
            if (location == '/dashboard' || location == '/') {
              final shouldExit = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Exit App?'),
                  content: const Text('Are you sure you want to exit FocusFlow?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              );

              if (shouldExit == true) {
                SystemNavigator.pop(); // Completely exits the app on Android
              }
            } else {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
              } else {
                GoRouter.of(context).go('/dashboard');
              }
            }
          },
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
