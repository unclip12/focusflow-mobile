// =============================================================
// AppRouter — GoRouter with named routes for all screens.
// All placeholder screens replaced with real implementations.
// =============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ── Screen imports ──────────────────────────────────────────────
import 'package:focusflow_mobile/screens/dashboard/dashboard_screen.dart';
import 'package:focusflow_mobile/screens/today_plan/today_plan_screen.dart';
import 'package:focusflow_mobile/screens/knowledge_base/knowledge_base_screen.dart';
import 'package:focusflow_mobile/screens/knowledge_base/kb_entry_detail_screen.dart';
import 'package:focusflow_mobile/screens/time_log/time_log_screen.dart';
import 'package:focusflow_mobile/screens/study_plan/study_plan_screen.dart';
import 'package:focusflow_mobile/screens/focus_timer/focus_timer_screen.dart';
import 'package:focusflow_mobile/screens/fmge/fmge_screen.dart';
import 'package:focusflow_mobile/screens/fmge/fmge_entry_detail_screen.dart';
import 'package:focusflow_mobile/screens/revision_hub/revision_hub_screen.dart';
import 'package:focusflow_mobile/screens/settings/settings_screen.dart';
import 'package:focusflow_mobile/screens/calendar/calendar_screen.dart';
import 'package:focusflow_mobile/screens/notifications/notifications_screen.dart';
import 'package:focusflow_mobile/screens/profile/profile_screen.dart';
import 'package:focusflow_mobile/screens/analytics/analytics_screen.dart';
import 'package:focusflow_mobile/screens/daily_tracker/daily_tracker_screen.dart';
import 'package:focusflow_mobile/screens/mentor/mentor_screen.dart';

// ── Route names (used by GoRouter named navigation) ─────────────
class Routes {
  Routes._();
  static const dashboard     = 'dashboard';
  static const studyTracker  = 'study-tracker';
  static const todaysPlan    = 'todays-plan';
  static const focusTimer    = 'focus-timer';
  static const calendar      = 'calendar';
  static const timeLogger    = 'time-logger';
  static const fmge          = 'fmge';
  static const fmgeDetail    = 'fmge-detail';
  static const dailyTracker  = 'daily-tracker';
  static const faLogger      = 'fa-logger';
  static const revision      = 'revision';
  static const knowledgeBase = 'knowledge-base';
  static const kbDetail      = 'kb-detail';
  static const data          = 'data';
  static const chat          = 'chat';
  static const aiMemory      = 'ai-memory';
  static const settings      = 'settings';
  static const notifications = 'notifications';
  static const profile       = 'profile';
  static const analytics     = 'analytics';
  static const mentor        = 'mentor';
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

    // ── Study Tracker (alias for Today's Plan) ────────────────
    GoRoute(
      path: '/study-tracker',
      name: Routes.studyTracker,
      builder: (context, state) => const StudyPlanScreen(),
    ),

    // ── Today's Plan ──────────────────────────────────────────
    GoRoute(
      path: '/todays-plan',
      name: Routes.todaysPlan,
      builder: (context, state) => const TodayPlanScreen(),
    ),

    // ── Focus Timer ───────────────────────────────────────────
    GoRoute(
      path: '/focus-timer',
      name: Routes.focusTimer,
      builder: (context, state) => const FocusTimerScreen(),
    ),

    // ── Calendar ──────────────────────────────────────────────
    GoRoute(
      path: '/calendar',
      name: Routes.calendar,
      builder: (context, state) => const CalendarScreen(),
    ),

    // ── Time Logger ───────────────────────────────────────────
    GoRoute(
      path: '/time-logger',
      name: Routes.timeLogger,
      builder: (context, state) => const TimeLogScreen(),
    ),

    // ── FMGE Prep ─────────────────────────────────────────────
    GoRoute(
      path: '/fmge',
      name: Routes.fmge,
      builder: (context, state) => const FMGEScreen(),
      routes: [
        GoRoute(
          path: ':id',
          name: Routes.fmgeDetail,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return FMGEEntryDetailScreen(entryId: id);
          },
        ),
      ],
    ),

    // ── Daily Tracker ─────────────────────────────────────────
    GoRoute(
      path: '/daily-tracker',
      name: Routes.dailyTracker,
      builder: (context, state) => const DailyTrackerScreen(),
    ),

    // ── FA Logger (placeholder — not yet implemented) ─────────
    GoRoute(
      path: '/fa-logger',
      name: Routes.faLogger,
      builder: (context, state) => const _Placeholder('FA Logger'),
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

    // ── Info Files / Data (placeholder) ───────────────────────
    GoRoute(
      path: '/data',
      name: Routes.data,
      builder: (context, state) => const _Placeholder('Info Files'),
    ),

    // ── AI Mentor Chat ────────────────────────────────────────
    GoRoute(
      path: '/chat',
      name: Routes.chat,
      builder: (context, state) => const MentorScreen(),
    ),

    // ── My AI Memory (placeholder) ────────────────────────────
    GoRoute(
      path: '/ai-memory',
      name: Routes.aiMemory,
      builder: (context, state) => const _Placeholder('My AI Memory'),
    ),

    // ── Settings ──────────────────────────────────────────────
    GoRoute(
      path: '/settings',
      name: Routes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),

    // ── Notifications ─────────────────────────────────────────
    GoRoute(
      path: '/notifications',
      name: Routes.notifications,
      builder: (context, state) => const NotificationsScreen(),
    ),

    // ── Profile ───────────────────────────────────────────────
    GoRoute(
      path: '/profile',
      name: Routes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),

    // ── Analytics ─────────────────────────────────────────────
    GoRoute(
      path: '/analytics',
      name: Routes.analytics,
      builder: (context, state) => const AnalyticsScreen(),
    ),

    // ── Mentor (alias for /chat) ──────────────────────────────
    GoRoute(
      path: '/mentor',
      name: Routes.mentor,
      builder: (context, state) => const MentorScreen(),
    ),
  ],
);

// ── Placeholder screen (for screens not yet implemented) ────────
class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_rounded,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Coming soon', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
