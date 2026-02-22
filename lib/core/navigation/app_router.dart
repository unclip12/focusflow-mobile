import 'package:go_router/go_router.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/todays_plan/todays_plan_screen.dart';
import '../../features/knowledge_base/knowledge_base_screen.dart';
import '../../features/fa_logger/fa_logger_screen.dart';
import '../../features/focus_timer/focus_timer_screen.dart';
import '../../features/fmge/fmge_screen.dart';
import '../../features/time_logger/time_logger_screen.dart';
import '../../features/revision/revision_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/study_tracker/study_tracker_screen.dart';
import '../../features/ai_chat/ai_chat_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../widgets/navigation_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/today',
  routes: [
    ShellRoute(
      builder: (context, state, child) => NavigationShell(child: child),
      routes: [
        GoRoute(path: '/dashboard',  builder: (c, s) => const DashboardScreen()),
        GoRoute(path: '/today',      builder: (c, s) => const TodaysPlanScreen()),
        GoRoute(path: '/knowledge',  builder: (c, s) => const KnowledgeBaseScreen()),
        GoRoute(path: '/fa-logger',  builder: (c, s) => const FALoggerScreen()),
        GoRoute(path: '/timer',      builder: (c, s) => const FocusTimerScreen()),
        GoRoute(path: '/fmge',       builder: (c, s) => const FMGEScreen()),
        GoRoute(path: '/time-logger',builder: (c, s) => const TimeLoggerScreen()),
        GoRoute(path: '/revision',   builder: (c, s) => const RevisionScreen()),
        GoRoute(path: '/calendar',   builder: (c, s) => const CalendarScreen()),
        GoRoute(path: '/tracker',    builder: (c, s) => const StudyTrackerScreen()),
        GoRoute(path: '/ai-chat',    builder: (c, s) => const AIChatScreen()),
        GoRoute(path: '/analytics',  builder: (c, s) => const AnalyticsScreen()),
        GoRoute(path: '/settings',   builder: (c, s) => const SettingsScreen()),
      ],
    ),
  ],
);
