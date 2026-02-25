// =============================================================
// AppRouter — GoRouter with named routes for all live screens.
// G3: 12 dead routes removed. Only active screens remain.
// =============================================================

import 'package:go_router/go_router.dart';

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

// ── Route names ─────────────────────────────────────────────────
class Routes {
  Routes._();
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
}

// ── Router configuration ────────────────────────────────────────
final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    // ── Dashboard (home) ──────────────────────────────────────
    GoRoute(
      path: '/dashboard',
      name: Routes.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),

    // ── Today's Plan ──────────────────────────────────────────
    GoRoute(
      path: '/todays-plan',
      name: Routes.todaysPlan,
      builder: (context, state) => const TodayPlanScreen(),
    ),

    // ── Time Logger ───────────────────────────────────────────
    GoRoute(
      path: '/time-logger',
      name: Routes.timeLogger,
      builder: (context, state) => const TimeLogScreen(),
    ),

    // ── FA Logger (interim — replaced by Tracker in G5) ───────
    GoRoute(
      path: '/fa-logger',
      name: Routes.faLogger,
      builder: (context, state) => const FALoggerScreen(),
    ),

    // ── Revision Hub ──────────────────────────────────────────
    GoRoute(
      path: '/revision',
      name: Routes.revision,
      builder: (context, state) => const RevisionHubScreen(),
    ),

    // ── Knowledge Base ────────────────────────────────────────
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

    // ── Analytics ─────────────────────────────────────────────
    GoRoute(
      path: '/analytics',
      name: Routes.analytics,
      builder: (context, state) => const AnalyticsScreen(),
    ),

    // ── Settings ──────────────────────────────────────────────
    GoRoute(
      path: '/settings',
      name: Routes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),

    // ── Session (focus timer embedded in study blocks) ─────────
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
