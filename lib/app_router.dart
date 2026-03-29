// =============================================================
// AppRouter — GoRouter with ShellRoute for bottom nav (G4)
// /session stays outside shell (full-screen focus timer)
// /splash is the true initial route — handles all heavy seeding
// =============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:focusflow_mobile/widgets/main_shell.dart';
import 'package:focusflow_mobile/screens/splash/splash_screen.dart';

// ── Screen imports ──────────────────────────────────────────────
import 'package:focusflow_mobile/screens/dashboard/dashboard_screen.dart';
import 'package:focusflow_mobile/screens/today_plan/today_plan_screen.dart';
import 'package:focusflow_mobile/screens/knowledge_base/knowledge_base_screen.dart';
import 'package:focusflow_mobile/screens/knowledge_base/kb_entry_detail_screen.dart';
import 'package:focusflow_mobile/screens/time_log/time_log_screen.dart';
import 'package:focusflow_mobile/screens/revision_hub/revision_hub_screen.dart';
import 'package:focusflow_mobile/screens/settings/settings_screen.dart';
import 'package:focusflow_mobile/screens/fa_logger/fa_logger_screen.dart';
import 'package:focusflow_mobile/screens/analytics/analytics_screen.dart';
import 'package:focusflow_mobile/screens/session/session_screen.dart';
import 'package:focusflow_mobile/screens/tracker/tracker_screen.dart';
import 'package:focusflow_mobile/screens/import/import_screen.dart';
import 'package:focusflow_mobile/screens/backup/backup_screen.dart';

// ── Route names ─────────────────────────────────────────────────
class Routes {
  Routes._();
  static const splash        = 'splash';
  static const dashboard     = 'dashboard';
  static const todaysPlan    = 'todays-plan';
  static const timeLogger    = 'time-logger';
  static const faLogger      = 'fa-logger';
  static const revision      = 'revision';
  static const knowledgeBase = 'knowledge-base';
  static const kbDetail      = 'kb-detail';
  static const analytics     = 'analytics';
  static const settings      = 'settings';
  static const session       = 'session';
  static const tracker       = 'tracker';
  static const backup        = 'backup';
}

// ── Router ──────────────────────────────────────────────────────
final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'appNavigator');

final GoRouter appRouter = GoRouter(
  navigatorKey: appNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // ── Splash: handles all DB + seed init, then auto-navigates ─
    GoRoute(
      path: '/splash',
      name: Routes.splash,
      builder: (context, state) => const SplashScreen(),
    ),

    // ── Shell: 8 screens share the bottom nav ──────────────────
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return MainShell(
          currentLocation: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          name: Routes.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/todays-plan',
          name: Routes.todaysPlan,
          builder: (context, state) => const TodayPlanScreen(),
        ),
        GoRoute(
          path: '/time-logger',
          name: Routes.timeLogger,
          builder: (context, state) => const TimeLogScreen(),
        ),
        GoRoute(
          path: '/fa-logger',
          name: Routes.faLogger,
          builder: (context, state) => const FALoggerScreen(),
        ),
        GoRoute(
          path: '/revision',
          name: Routes.revision,
          builder: (context, state) => const RevisionHubScreen(),
        ),
        GoRoute(
          path: '/knowledge-base',
          name: Routes.knowledgeBase,
          builder: (context, state) => const KnowledgeBaseScreen(),
          routes: [
            GoRoute(
              path: ':id',
              name: Routes.kbDetail,
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return KBEntryDetailScreen(pageNumber: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/analytics',
          name: Routes.analytics,
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: Routes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/tracker',
          name: Routes.tracker,
          builder: (context, state) => const TrackerScreen(),
        ),
        GoRoute(
          path: '/import',
          builder: (_, __) => const ImportScreen(),
        ),
        GoRoute(
          path: '/backup',
          name: Routes.backup,
          builder: (_, __) => const BackupScreen(),
        ),
      ],
    ),

    // ── Session: outside shell — full screen, no nav bar ───────
    GoRoute(
      path: '/session',
      name: Routes.session,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return SessionScreen(
          block: extra['block'],
          plan: extra['plan'],
        );
      },
    ),
  ],
);
