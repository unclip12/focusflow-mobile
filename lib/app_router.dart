// =============================================================
// AppRouter — GoRouter with named routes for all 15 screens
// Placeholder screens are used until real screens land in later batches.
// =============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  static const dailyTracker  = 'daily-tracker';
  static const faLogger      = 'fa-logger';
  static const revision      = 'revision';
  static const knowledgeBase = 'knowledge-base';
  static const data          = 'data';
  static const chat          = 'chat';
  static const aiMemory      = 'ai-memory';
  static const settings      = 'settings';
}

// ── Router configuration ────────────────────────────────────────
final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/dashboard',
      name: Routes.dashboard,
      builder: (context, state) => const _Placeholder('Dashboard'),
    ),
    GoRoute(
      path: '/study-tracker',
      name: Routes.studyTracker,
      builder: (context, state) => const _Placeholder('Study Tracker'),
    ),
    GoRoute(
      path: '/todays-plan',
      name: Routes.todaysPlan,
      builder: (context, state) => const _Placeholder("Today's Plan"),
    ),
    GoRoute(
      path: '/focus-timer',
      name: Routes.focusTimer,
      builder: (context, state) => const _Placeholder('Focus Timer'),
    ),
    GoRoute(
      path: '/calendar',
      name: Routes.calendar,
      builder: (context, state) => const _Placeholder('Calendar'),
    ),
    GoRoute(
      path: '/time-logger',
      name: Routes.timeLogger,
      builder: (context, state) => const _Placeholder('Time Logger'),
    ),
    GoRoute(
      path: '/fmge',
      name: Routes.fmge,
      builder: (context, state) => const _Placeholder('FMGE Prep'),
    ),
    GoRoute(
      path: '/daily-tracker',
      name: Routes.dailyTracker,
      builder: (context, state) => const _Placeholder('Daily Tracker'),
    ),
    GoRoute(
      path: '/fa-logger',
      name: Routes.faLogger,
      builder: (context, state) => const _Placeholder('FA Logger'),
    ),
    GoRoute(
      path: '/revision',
      name: Routes.revision,
      builder: (context, state) => const _Placeholder('Revision Hub'),
    ),
    GoRoute(
      path: '/knowledge-base',
      name: Routes.knowledgeBase,
      builder: (context, state) => const _Placeholder('Knowledge Base'),
    ),
    GoRoute(
      path: '/data',
      name: Routes.data,
      builder: (context, state) => const _Placeholder('Info Files'),
    ),
    GoRoute(
      path: '/chat',
      name: Routes.chat,
      builder: (context, state) => const _Placeholder('AI Mentor'),
    ),
    GoRoute(
      path: '/ai-memory',
      name: Routes.aiMemory,
      builder: (context, state) => const _Placeholder('My AI Memory'),
    ),
    GoRoute(
      path: '/settings',
      name: Routes.settings,
      builder: (context, state) => const _Placeholder('Settings'),
    ),
  ],
);

// ── Placeholder screen (replaced in later batches) ──────────────
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
            Text(title,
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Coming soon',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
