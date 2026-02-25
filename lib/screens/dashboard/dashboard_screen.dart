// =============================================================
// DashboardScreen — G8 full rebuild
// 6 sections: Exam Countdown, Study Stats, FA Progress,
// Revision Queue, Activity Heatmap, Subject Breakdown
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/utils/date_utils.dart' as du;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loaded = context.select<AppProvider, bool>((p) => p.loaded);

    Widget content;
    if (!loaded) {
      content = Scaffold(
        appBar: _buildAppBar(context),
        body: _ShimmerLoading(),
      );
    } else {
      content = const _DashboardBody();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit FocusFlow?'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: content,
    );
  }

  static PreferredSizeWidget _buildAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FocusFlow',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: cs.onSurface,
            ),
          ),
          Text(
            'Your Study OS',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// DASHBOARD BODY
// ══════════════════════════════════════════════════════════════════

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;

    final todayStr = du.AppDateUtils.todayKey();
    final now = DateTime.now();

    // ── Exam dates ──────────────────────────────────────────────
    final fmgeDate = DateTime(2026, 6, 28);
    final step1Date = DateTime(2026, 6, 15);
    final today = DateTime(now.year, now.month, now.day);
    final fmgeDays = fmgeDate.difference(today).inDays;
    final step1Days = step1Date.difference(today).inDays;

    // ── Study time calculations ─────────────────────────────────
    final todayLogs = app.timeLogs.where((l) => l.date == todayStr).toList();
    final studyMinutesToday =
        todayLogs.fold<int>(0, (sum, l) => sum + l.durationMinutes);

    // This week (Mon–today)
    final weekday = now.weekday; // 1=Mon, 7=Sun
    final monday = today.subtract(Duration(days: weekday - 1));
    int weekMinutes = 0;
    for (final log in app.timeLogs) {
      final logDate = du.AppDateUtils.parseDate(log.date);
      if (logDate != null &&
          !logDate.isBefore(monday) &&
          !logDate.isAfter(today)) {
        weekMinutes += log.durationMinutes;
      }
    }
    final weekHours = weekMinutes ~/ 60;

    // ── Streak ──────────────────────────────────────────────────
    final logDates = <String>{};
    for (final log in app.timeLogs) {
      logDates.add(log.date);
    }
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final d = today.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      if (logDates.contains(dateStr)) {
        streak++;
      } else {
        if (i == 0) continue; // today might not have a log yet
        break;
      }
    }

    // ── FA Progress ─────────────────────────────────────────────
    final readPages =
        app.faPages.where((p) => p.status != 'unread').length;
    final ankiDone =
        app.faPages.where((p) => p.status == 'anki_done').length;
    final unread =
        app.faPages.where((p) => p.status == 'unread').length;

    // ── Revision due ────────────────────────────────────────────
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final dueRevisions = app.revisionItems.where((r) {
      final due = DateTime.tryParse(r.nextRevisionAt);
      return due != null && !due.isAfter(todayEnd);
    }).length;

    // ── Activity heatmap (last 7 days) ──────────────────────────
    final last7 = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    // ── Subject breakdown ───────────────────────────────────────
    final subjectMinutes = <String, int>{};
    for (final log in app.timeLogs) {
      final key = log.activity.isNotEmpty ? log.activity : 'Other';
      subjectMinutes[key] = (subjectMinutes[key] ?? 0) + log.durationMinutes;
    }
    final sortedSubjects = subjectMinutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topSubjects = sortedSubjects.take(4).toList();
    final maxSubjectMinutes =
        topSubjects.isNotEmpty ? topSubjects.first.value : 1;

    return Scaffold(
      appBar: DashboardScreen._buildAppBar(context),
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: () => app.loadAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ═══ SECTION 1: Exam Countdown ═══════════════════
              _sectionHeader(context, 'EXAM COUNTDOWN'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ExamCountdownCard(
                      label: 'FMGE',
                      daysRemaining: fmgeDays,
                      subtitle: 'Jun 28, 2026',
                      accentColor: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ExamCountdownCard(
                      label: 'Step 1',
                      daysRemaining: step1Days,
                      subtitle: 'Jun 15, 2026',
                      accentColor: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ═══ SECTION 2: Today's Study Stats ══════════════
              _sectionHeader(context, "TODAY'S STUDY"),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Today',
                      value: _formatHM(studyMinutesToday),
                      icon: Icons.schedule_rounded,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'This Week',
                      value: '${weekHours}h',
                      icon: Icons.date_range_rounded,
                      color: cs.tertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Streak',
                      value: '$streak days 🔥',
                      icon: Icons.local_fire_department_rounded,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ═══ SECTION 3: FA 2025 Progress ═════════════════
              _sectionHeader(context, 'FIRST AID 2025'),
              const SizedBox(height: 8),
              _FAProgressCard(
                readPages: readPages,
                ankiDone: ankiDone,
                unread: unread,
                onNavigate: () => context.go('/tracker'),
              ),
              const SizedBox(height: 20),

              // ═══ SECTION 4: Revision Queue ═══════════════════
              _sectionHeader(context, 'REVISION QUEUE'),
              const SizedBox(height: 8),
              _RevisionCard(
                dueCount: dueRevisions,
                onNavigate: () => context.go('/revision'),
              ),
              const SizedBox(height: 20),

              // ═══ SECTION 5: Activity Heatmap ═════════════════
              _sectionHeader(context, 'LAST 7 DAYS'),
              const SizedBox(height: 8),
              _ActivityHeatmap(
                days: last7,
                logDates: logDates,
                today: today,
              ),
              const SizedBox(height: 20),

              // ═══ SECTION 6: Subject Breakdown ════════════════
              _sectionHeader(context, 'TIME BY SUBJECT'),
              const SizedBox(height: 8),
              _SubjectBreakdownCard(
                topSubjects: topSubjects,
                maxMinutes: maxSubjectMinutes,
              ),

              const SizedBox(height: 80), // bottom nav clearance
            ],
          ),
        ),
      ),
    );
  }

  static Widget _sectionHeader(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: cs.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }

  static String _formatHM(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

// ══════════════════════════════════════════════════════════════════
// SECTION 1: Exam Countdown Card
// ══════════════════════════════════════════════════════════════════

class _ExamCountdownCard extends StatelessWidget {
  final String label;
  final int daysRemaining;
  final String subtitle;
  final Color accentColor;

  const _ExamCountdownCard({
    required this.label,
    required this.daysRemaining,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: accentColor, width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$daysRemaining',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            Text(
              'days left',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SECTION 2: Mini Stat Card
// ══════════════════════════════════════════════════════════════════

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SECTION 3: FA Progress Card
// ══════════════════════════════════════════════════════════════════

class _FAProgressCard extends StatelessWidget {
  final int readPages;
  final int ankiDone;
  final int unread;
  final VoidCallback onNavigate;

  const _FAProgressCard({
    required this.readPages,
    required this.ankiDone,
    required this.unread,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = readPages / 676;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'First Aid 2025',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                ActionChip(
                  label: const Text('Mark Pages →'),
                  onPressed: onNavigate,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: cs.surfaceContainerHighest,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$readPages / 676 pages read',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '$ankiDone Anki Done',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '|',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
                Text(
                  '$unread Unread',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SECTION 4: Revision Queue Card
// ══════════════════════════════════════════════════════════════════

class _RevisionCard extends StatelessWidget {
  final int dueCount;
  final VoidCallback onNavigate;

  const _RevisionCard({
    required this.dueCount,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revision Due',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (dueCount == 0)
                    Text(
                      '✅ All caught up!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade600,
                      ),
                    )
                  else
                    Text(
                      '$dueCount pages due',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange.shade700,
                      ),
                    ),
                ],
              ),
            ),
            if (dueCount > 0)
              IconButton.filled(
                onPressed: onNavigate,
                icon: const Icon(Icons.arrow_forward_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.onPrimaryContainer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SECTION 5: Activity Heatmap (7 days)
// ══════════════════════════════════════════════════════════════════

class _ActivityHeatmap extends StatelessWidget {
  final List<DateTime> days;
  final Set<String> logDates;
  final DateTime today;

  const _ActivityHeatmap({
    required this.days,
    required this.logDates,
    required this.today,
  });

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((d) {
            final dateStr = DateFormat('yyyy-MM-dd').format(d);
            final studied = logDates.contains(dateStr);
            final isToday = d.year == today.year &&
                d.month == today.month &&
                d.day == today.day;
            final dayLabel = _dayLabels[d.weekday - 1];

            return Column(
              children: [
                Text(
                  dayLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: studied
                        ? Colors.green.withValues(alpha: 0.15)
                        : cs.surfaceContainerHighest,
                    border: isToday
                        ? Border.all(color: cs.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: studied ? Colors.green : cs.outline.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SECTION 6: Subject Breakdown Card
// ══════════════════════════════════════════════════════════════════

class _SubjectBreakdownCard extends StatelessWidget {
  final List<MapEntry<String, int>> topSubjects;
  final int maxMinutes;

  const _SubjectBreakdownCard({
    required this.topSubjects,
    required this.maxMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (topSubjects.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Start logging study sessions to see breakdown',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: topSubjects.map((entry) {
            final fraction = entry.value / maxMinutes;
            final h = entry.value ~/ 60;
            final m = entry.value % 60;
            final timeLabel =
                h > 0 ? (m > 0 ? '${h}h ${m}m' : '${h}h') : '${m}m';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor: cs.surfaceContainerHighest,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
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
        final shimmer =
            cs.onSurface.withValues(alpha: 0.04 + 0.04 * _ctrl.value);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Row(
              children: [
                Expanded(child: _shimmerBox(shimmer, double.infinity, 100, radius: 12)),
                const SizedBox(width: 12),
                Expanded(child: _shimmerBox(shimmer, double.infinity, 100, radius: 12)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _shimmerBox(shimmer, double.infinity, 72, radius: 12)),
                const SizedBox(width: 8),
                Expanded(child: _shimmerBox(shimmer, double.infinity, 72, radius: 12)),
                const SizedBox(width: 8),
                Expanded(child: _shimmerBox(shimmer, double.infinity, 72, radius: 12)),
              ],
            ),
            const SizedBox(height: 16),
            _shimmerBox(shimmer, double.infinity, 120, radius: 12),
            const SizedBox(height: 16),
            _shimmerBox(shimmer, double.infinity, 70, radius: 12),
            const SizedBox(height: 16),
            _shimmerBox(shimmer, double.infinity, 60, radius: 12),
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
