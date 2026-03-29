import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

/// Root widget — wires theme + router together.
/// Theme is driven by SettingsProvider (12 themes, dark mode, accent colour).
/// Router is defined in app_router.dart (GoRouter — Batch 4).
class FocusFlowApp extends StatefulWidget {
  const FocusFlowApp({super.key});

  @override
  State<FocusFlowApp> createState() => _FocusFlowAppState();
}

class _FocusFlowAppState extends State<FocusFlowApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.instance.registerIntentHandler(
      _dispatchNotificationIntent,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.instance.tryDispatchPendingIntent());
    });
  }

  Future<bool> _dispatchNotificationIntent(NotificationIntent intent) async {
    if (appNavigatorKey.currentState == null) return false;

    final currentPath = appRouter.routeInformationProvider.value.uri.path;
    if (currentPath == '/splash') {
      return false;
    }

    switch (intent.targetType) {
      case NotificationIntentTarget.route:
        appRouter.goNamed(intent.routeName ?? Routes.dashboard);
        return true;
      case NotificationIntentTarget.daySession:
        NotificationService.instance.publishTodayPlanLaunchRequest(
          TodayPlanLaunchRequest(
            dateKey: intent.dateKey,
            activityId: intent.activityId,
            openDaySession: true,
          ),
        );
        appRouter.goNamed(Routes.todaysPlan);
        return true;
      case NotificationIntentTarget.todayPlanBlock:
        NotificationService.instance.publishTodayPlanLaunchRequest(
          TodayPlanLaunchRequest(
            dateKey: intent.dateKey,
            blockId: intent.blockId,
            activityId: intent.activityId,
          ),
        );
        appRouter.goNamed(Routes.todaysPlan);
        return true;
      case NotificationIntentTarget.todayPlan:
        NotificationService.instance.publishTodayPlanLaunchRequest(
          TodayPlanLaunchRequest(
            dateKey: intent.dateKey,
            activityId: intent.activityId,
            routineId: intent.routineId,
          ),
        );
        appRouter.goNamed(intent.routeName ?? Routes.todaysPlan);
        return true;
      default:
        appRouter.goNamed(intent.routeName ?? Routes.dashboard);
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final themeMode = settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;

    return MaterialApp.router(
      title: 'FocusFlow',
      restorationScopeId: 'app',
      theme: AppTheme.lightTheme(
        settings.currentTheme,
        settings.primaryColor,
        settings.fontSize,
      ),
      darkTheme: AppTheme.darkTheme(
        settings.currentTheme,
        settings.primaryColor,
        settings.fontSize,
      ),
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
