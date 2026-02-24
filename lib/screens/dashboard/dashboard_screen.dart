// =============================================================
// DashboardScreen — main landing page
// Uses AppScaffold, shows welcome, TodayGlance, Activity chart,
// Due Now list (KB + FMGE entries where nextRevisionAt ≤ now)
// Pull-to-refresh, shimmer loading, proper empty states.
// Performance: RepaintBoundary, const children, context.select.
// =============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/app_router.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/utils/date_utils.dart' as du;
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/widgets/stats_card.dart';
import 'package:focusflow_mobile/widgets/activity_graph.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Selective rebuilds: only watch the fields we need ─────────
    final loaded = context.select<AppProvider, bool>((p) => p.loaded);

    if (!loaded) {
      return AppScaffold(
        screenName: 'Dashboard',
        body: _ShimmerLoading(),
      );
    }

    return const AppScaffold(
      screenName: 'Dashboard',
      body: _DashboardBody(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// DASHBOARD BODY — separated to allow fine-grained selects
// ══════════════════════════════════════════════════════════════════

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final todayStr = du.AppDateUtils.todayKey();
    final displayName = app.userProfile?.displayName ?? 'Student';
    final now = DateTime.now();

    // ── Today's plan data ────────────────────────────────────────
    final DayPlan? todayPlan = app.getDayPlan(todayStr);
    final blocks = todayPlan?.blocks ?? [];
    final blocksDone = blocks.where((b) => b.status.value == 'COMPLETED').length;
    final blocksTotal = blocks.length;

    // ── Study hours today (from timeLogs) ────────────────────────
    final todayLogs =
        app.timeLogs.where((l) => l.date == todayStr).toList();
    final studyMinutesToday =
        todayLogs.fold<int>(0, (sum, l) => sum + l.durationMinutes);
    final studyHoursToday = studyMinutesToday / 60.0;

    // ── 14-day activity data ─────────────────────────────────────
    final minutesByDate = <String, int>{};
    for (final log in app.timeLogs) {
      minutesByDate[log.date] =
          (minutesByDate[log.date] ?? 0) + log.durationMinutes;
    }

    // ── Due Now: KB entries ──────────────────────────────────────
    final dueKB = app.knowledgeBase.where((e) {
      if (e.nextRevisionAt == null) return false;
      final next = DateTime.tryParse(e.nextRevisionAt!);
      return next != null && now.isAfter(next);
    }).toList();

    // ── Due Now: FMGE entries ────────────────────────────────────
    final dueFMGE = app.fmgeEntries.where((e) {
      if (e.nextRevisionAt == null) return false;
      final next = DateTime.tryParse(e.nextRevisionAt!);
      return next != null && now.isAfter(next);
    }).toList();

    // ── Streak (consecutive days with ≥1 time log) ──────────────
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final d = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      if (minutesByDate.containsKey(dateStr) && minutesByDate[dateStr]! > 0) {
        streak++;
      } else {
        // Allow today to be empty without breaking streak
        if (i == 0) continue;
        break;
      }
    }

    return AppScaffold(
      screenName: 'Dashboard',
      streakCount: streak,
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: () => app.loadAll(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // ── Welcome ─────────────────────────────────────────────
            Text(
              'Hey, $displayName 👋',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, d MMMM').format(now),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),

            // ── Today's Glance ──────────────────────────────────────
            RepaintBoundary(
              child: blocksTotal > 0
                  ? TodayGlanceCard(
                      blocksDone: blocksDone,
                      blocksTotal: blocksTotal,
                      studyHoursToday: studyHoursToday,
                    )
                  : _SectionEmptyState(
                      icon: Icons.checklist_outlined,
                      message: "No tasks for today — add one!",
                      buttonLabel: "Today's Plan",
                      routeName: Routes.todaysPlan,
                    ),
            ),
            const SizedBox(height: 16),

            // ── Quick Stats Row ─────────────────────────────────────
            RepaintBoundary(
              child: Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      icon: Icons.menu_book_rounded,
                      label: 'KB Pages',
                      value: '${app.knowledgeBase.length}',
                      accentColor: const Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      icon: Icons.replay_rounded,
                      label: 'Due Now',
                      value: '${dueKB.length + dueFMGE.length}',
                      accentColor: const Color(0xFFF43F5E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Activity Graph / Study Streak ───────────────────────
            RepaintBoundary(
              child: minutesByDate.isNotEmpty
                  ? ActivityGraph(minutesByDate: minutesByDate)
                  : _SectionEmptyState(
                      icon: Icons.local_fire_department_outlined,
                      message: "No study sessions yet — start your streak!",
                      buttonLabel: 'Focus Timer',
                      routeName: Routes.focusTimer,
                    ),
            ),
            const SizedBox(height: 20),

            // ── Due Now list ────────────────────────────────────────
            if (dueKB.isNotEmpty || dueFMGE.isNotEmpty) ...[
              Text('📋 Due for Revision',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...dueKB.take(5).map((e) => RepaintBoundary(
                    child: _DueTile(
                      icon: Icons.menu_book_rounded,
                      title: 'Page ${e.pageNumber}',
                      subtitle: e.title,
                      color: const Color(0xFF6366F1),
                    ),
                  )),
              ...dueFMGE.take(5).map((e) => RepaintBoundary(
                    child: _DueTile(
                      icon: Icons.medical_services_rounded,
                      title: e.subject,
                      subtitle: 'Slides ${e.slideStart}–${e.slideEnd}',
                      color: const Color(0xFF10B981),
                    ),
                  )),
              const SizedBox(height: 8),
            ],

            // ── Empty state — no due revisions ──────────────────────
            if (dueKB.isEmpty && dueFMGE.isEmpty)
              _SectionEmptyState(
                icon: Icons.auto_awesome_outlined,
                message: "No revisions due — you're all caught up!",
                buttonLabel: 'Knowledge Base',
                routeName: Routes.knowledgeBase,
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// PER-SECTION EMPTY STATE
// ══════════════════════════════════════════════════════════════════

class _SectionEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String buttonLabel;
  final String routeName;

  const _SectionEmptyState({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 28, color: cs.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.goNamed(routeName),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SHIMMER LOADING PLACEHOLDER
// ══════════════════════════════════════════════════════════════════

class _ShimmerLoading extends StatefulWidget {
  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final shimmer = cs.onSurface.withValues(
            alpha: 0.04 + 0.04 * _ctrl.value);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Welcome placeholder
            _shimmerBox(shimmer, 200, 28),
            const SizedBox(height: 8),
            _shimmerBox(shimmer, 140, 14),
            const SizedBox(height: 24),
            // Glance card placeholder
            _shimmerBox(shimmer, double.infinity, 100, radius: 16),
            const SizedBox(height: 16),
            // Stats row placeholder
            Row(
              children: [
                Expanded(child: _shimmerBox(shimmer, double.infinity, 72, radius: 12)),
                const SizedBox(width: 12),
                Expanded(child: _shimmerBox(shimmer, double.infinity, 72, radius: 12)),
              ],
            ),
            const SizedBox(height: 16),
            // Activity graph placeholder
            _shimmerBox(shimmer, double.infinity, 140, radius: 16),
          ],
        );
      },
    );
  }

  Widget _shimmerBox(Color color, double width, double height,
      {double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Due revision tile ───────────────────────────────────────────
class _DueTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _DueTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    )),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: cs.onSurface.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}
