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
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/models/revision_item.dart';
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
    final sp = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;

    final dayStartHour = sp.dayStartHour;
    final todayStr = du.AppDateUtils.effectiveDateKey(DateTime.now(), dayStartHour);
    final now = DateTime.now();

    // ── Exam dates (from Settings) ──────────────────────────────
    final fmgeDate = DateTime.parse(sp.fmgeDate);
    final step1Date = DateTime.parse(sp.step1Date);
    final today = DateTime(now.year, now.month, now.day);
    final fmgeDays = fmgeDate.difference(today).inDays;
    final step1Days = step1Date.difference(today).inDays;

    // ── Study time calculations ─────────────────────────────────
    // Today: timeLogs + studyEntries on effective date
    int studyMinutesToday = 0;
    for (final l in app.timeLogs) {
      if (l.date == todayStr) studyMinutesToday += l.durationMinutes;
    }
    for (final e in app.studyEntries) {
      if (e.date == todayStr) studyMinutesToday += (e.durationMinutes ?? 0);
    }

    // Last 7 days (rolling window)
    int last7DaysMinutes = 0;
    final sevenAgo = today.subtract(const Duration(days: 6));
    for (final l in app.timeLogs) {
      final d = du.AppDateUtils.parseDate(l.date);
      if (d != null && !d.isBefore(sevenAgo) && !d.isAfter(today)) {
        last7DaysMinutes += l.durationMinutes;
      }
    }
    for (final e in app.studyEntries) {
      final d = du.AppDateUtils.parseDate(e.date);
      if (d != null && !d.isBefore(sevenAgo) && !d.isAfter(today)) {
        last7DaysMinutes += (e.durationMinutes ?? 0);
      }
    }

    // ── Streak (from AppProvider streakData) ─────────────────────
    final streak = app.streakData.currentStreak;
    final creditBalance = app.streakData.creditBalance;
    final dailyGoal = sp.dailyFAGoal;
    final todayPagesRead = app.getTodayPagesRead(dayStartHour);
    final pagesRemaining = (dailyGoal - todayPagesRead).clamp(0, dailyGoal);
    final streakDeadline = app.getStreakDeadline(dayStartHour);
    final streakAtRisk = pagesRemaining > 0 && streakDeadline != null;
    Duration? timeUntilDeadline;
    if (streakDeadline != null) {
      timeUntilDeadline = streakDeadline.difference(now);
      if (timeUntilDeadline.isNegative) timeUntilDeadline = Duration.zero;
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
    }).toList();
    final dueRevisionCount = dueRevisions.length;

    // ── Activity heatmap (last 7 days) — include timeLogs + studyEntries ─
    final last7 = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final dayMinutes = <String, int>{};
    for (final l in app.timeLogs) {
      dayMinutes[l.date] = (dayMinutes[l.date] ?? 0) + l.durationMinutes;
    }
    for (final e in app.studyEntries) {
      dayMinutes[e.date] = (dayMinutes[e.date] ?? 0) + (e.durationMinutes ?? 0);
    }

    // ── Subject breakdown — include studyEntries ─────────────────
    final subjectMinutes = <String, int>{};
    for (final log in app.timeLogs) {
      final key = log.activity.isNotEmpty ? log.activity : 'Other';
      subjectMinutes[key] = (subjectMinutes[key] ?? 0) + log.durationMinutes;
    }
    for (final e in app.studyEntries) {
      final key = e.taskName.isNotEmpty ? e.taskName : 'Other';
      subjectMinutes[key] = (subjectMinutes[key] ?? 0) + (e.durationMinutes ?? 0);
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

              // ── Streak at risk banner ─────────────────────────
              if (streakAtRisk && streak > 0)
                _StreakAtRiskBanner(
                  pagesRemaining: pagesRemaining,
                  timeRemaining: timeUntilDeadline ?? Duration.zero,
                  dailyGoal: dailyGoal,
                  todayRead: todayPagesRead,
                ),
              if (streakAtRisk && streak > 0) const SizedBox(height: 12),

              // ═══ SECTION 1: Exam Countdown ═══════════════════
              _sectionHeader(context, 'EXAM COUNTDOWN'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ExamCountdownCard(
                      label: 'FMGE',
                      daysRemaining: fmgeDays,
                      subtitle: DateFormat('MMM d, y').format(fmgeDate),
                      accentColor: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ExamCountdownCard(
                      label: 'Step 1',
                      daysRemaining: step1Days,
                      subtitle: DateFormat('MMM d, y').format(step1Date),
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
                      label: 'Last 7 Days',
                      value: _formatHM(last7DaysMinutes),
                      icon: Icons.date_range_rounded,
                      color: cs.tertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StreakStatCard(
                      streak: streak,
                      credits: creditBalance,
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
                faPages: app.faPages,
                dayStartHour: dayStartHour,
                onNavigate: () => context.go('/tracker'),
              ),
              const SizedBox(height: 20),

              // ═══ SECTION 4: Revision Queue ═══════════════════
              _sectionHeader(context, 'REVISION QUEUE'),
              const SizedBox(height: 8),
              _RevisionCard(
                dueCount: dueRevisionCount,
                dueItems: dueRevisions.take(3).toList(),
                onNavigate: () => context.go('/revision'),
              ),
              const SizedBox(height: 20),

              // ═══ SECTION 5: Activity Heatmap ═════════════════
              _sectionHeader(context, 'LAST 7 DAYS'),
              const SizedBox(height: 8),
              _ActivityHeatmap(
                days: last7,
                dayMinutes: dayMinutes,
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
// SECTION 2b: Streak Stat Card (animated fire + credit badge)
// ══════════════════════════════════════════════════════════════════

class _StreakStatCard extends StatefulWidget {
  final int streak;
  final int credits;

  const _StreakStatCard({required this.streak, required this.credits});

  @override
  State<_StreakStatCard> createState() => _StreakStatCardState();
}

class _StreakStatCardState extends State<_StreakStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.streak >= 10) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_StreakStatCard old) {
    super.didUpdateWidget(old);
    if (widget.streak >= 10 && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (widget.streak < 10 && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Fire size & color intensity based on streak
    double iconSize;
    Color fireColor;
    if (widget.streak >= 10) {
      iconSize = 24;
      fireColor = Colors.deepOrange;
    } else if (widget.streak >= 4) {
      iconSize = 22;
      fireColor = Colors.orange;
    } else {
      iconSize = 18;
      fireColor = Colors.orange.shade300;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) {
                final scale = widget.streak >= 10
                    ? 1.0 + 0.15 * _ctrl.value
                    : 1.0;
                final glow = widget.streak >= 10
                    ? _ctrl.value * 0.6
                    : 0.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: glow > 0
                          ? [
                              BoxShadow(
                                color: fireColor.withValues(alpha: glow),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      size: iconSize,
                      color: fireColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.streak} days',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Streak',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                if (widget.credits > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.credits}★',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Streak At Risk Banner
// ══════════════════════════════════════════════════════════════════

class _StreakAtRiskBanner extends StatelessWidget {
  final int pagesRemaining;
  final Duration timeRemaining;
  final int dailyGoal;
  final int todayRead;

  const _StreakAtRiskBanner({
    required this.pagesRemaining,
    required this.timeRemaining,
    required this.dailyGoal,
    required this.todayRead,
  });

  @override
  Widget build(BuildContext context) {
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;
    final timeStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade700,
            Colors.deepOrange.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Streak at risk!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$pagesRemaining pages remaining · $timeStr left',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 2),
                // Progress bar for today's pages
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: todayRead / dailyGoal,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
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
  final List<FAPage> faPages;
  final int dayStartHour;
  final VoidCallback onNavigate;

  const _FAProgressCard({
    required this.readPages,
    required this.ankiDone,
    required this.unread,
    required this.faPages,
    required this.dayStartHour,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalPages = faPages.isNotEmpty ? faPages.length : 676;
    final progress = readPages / totalPages;

    // Calculate averages from firstReadAt timestamps
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Overall avg: pages with firstReadAt / days since first read
    final readDates = faPages
        .where((p) => p.firstReadAt != null)
        .map((p) => DateTime.tryParse(p.firstReadAt!))
        .whereType<DateTime>()
        .toList();
    double overallAvg = 0;
    if (readDates.isNotEmpty) {
      readDates.sort();
      final firstReadDay = DateTime(
          readDates.first.year, readDates.first.month, readDates.first.day);
      final daysSinceFirst = today.difference(firstReadDay).inDays;
      if (daysSinceFirst > 0) {
        overallAvg = readPages / daysSinceFirst;
      }
    }

    // 7-day rolling avg
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final last7Pages = readDates.where((d) => d.isAfter(sevenDaysAgo)).length;
    final weeklyAvg = last7Pages / 7.0;

    // ETA
    final remaining = totalPages - readPages;
    String eta = '--';
    if (weeklyAvg > 0 && remaining > 0) {
      final daysNeeded = (remaining / weeklyAvg).ceil();
      final etaDate = today.add(Duration(days: daysNeeded));
      eta = '${etaDate.day}/${etaDate.month}/${etaDate.year}';
    } else if (remaining <= 0) {
      eta = 'Done! 🎉';
    }

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
              '$readPages / $totalPages pages read',
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
            const Divider(height: 20),
            // Avg metrics row
            Row(
              children: [
                Expanded(
                  child: _metricTile(
                    cs,
                    '📈 Overall Avg',
                    '${overallAvg.toStringAsFixed(1)} pg/day',
                  ),
                ),
                Expanded(
                  child: _metricTile(
                    cs,
                    '📅 7-Day Avg',
                    '${weeklyAvg.toStringAsFixed(1)} pg/day',
                  ),
                ),
                Expanded(
                  child: _metricTile(
                    cs,
                    '🎯 ETA',
                    eta,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTile(ColorScheme cs, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SECTION 4: Revision Queue Card
// ══════════════════════════════════════════════════════════════════

class _RevisionCard extends StatelessWidget {
  final int dueCount;
  final List<RevisionItem> dueItems;
  final VoidCallback onNavigate;

  const _RevisionCard({
    required this.dueCount,
    required this.dueItems,
    required this.onNavigate,
  });

  void _showRevisionSheet(BuildContext context) {
    final app = context.read<AppProvider>();
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Do Now: items whose nextRevisionAt is at or before now
    final doNow = app.revisionItems.where((r) {
      final due = DateTime.tryParse(r.nextRevisionAt);
      return due != null && !due.isAfter(now);
    }).toList();

    // Upcoming: items whose nextRevisionAt is after now but within today
    final upcoming = app.revisionItems.where((r) {
      final due = DateTime.tryParse(r.nextRevisionAt);
      return due != null && due.isAfter(now) && !due.isAfter(todayEnd);
    }).toList();

    final showDoNow = doNow.isNotEmpty;
    final items = showDoNow ? doNow : upcoming;
    final label = showDoNow ? 'Do Now' : 'Upcoming';

    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$label (${items.length})',
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onNavigate();
                    },
                    child: const Text('View All →'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 48,
                          color: Colors.green.shade400),
                      const SizedBox(height: 12),
                      Text('All caught up! 🎉',
                        style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = items[i];
                    final display = r.source == 'FA'
                        ? 'FA Page ${r.pageNumber}'
                        : r.title;
                    final subtitle = r.parentTitle.isNotEmpty
                        ? '${r.parentTitle} · Rev ${r.currentRevisionIndex}'
                        : 'Rev ${r.currentRevisionIndex}';
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: showDoNow
                            ? Colors.orange.withValues(alpha: 0.15)
                            : cs.primary.withValues(alpha: 0.1),
                        child: Icon(
                          showDoNow ? Icons.priority_high_rounded : Icons.schedule_rounded,
                          size: 16,
                          color: showDoNow ? Colors.orange.shade700 : cs.primary,
                        ),
                      ),
                      title: Text(display, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14)),
                      subtitle: Text(subtitle,
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

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
                      '$dueCount items due',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  // Show top 3 due items
                  if (dueItems.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...dueItems.map((item) {
                      final displayStr =
                          item.source == 'FA' ? 'Page ${item.pageNumber}' : item.title;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• $displayStr',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            IconButton.filled(
              onPressed: () => _showRevisionSheet(context),
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
  final Map<String, int> dayMinutes;
  final DateTime today;

  const _ActivityHeatmap({
    required this.days,
    required this.dayMinutes,
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
            final minutes = dayMinutes[dateStr] ?? 0;
            final studied = minutes > 0;
            final isToday = d.year == today.year &&
                d.month == today.month &&
                d.day == today.day;
            final dayLabel = _dayLabels[d.weekday - 1];

            // Color intensity based on study minutes
            final intensity = studied
                ? (minutes / 120.0).clamp(0.3, 1.0)
                : 0.0;

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
                        ? Colors.green.withValues(alpha: intensity * 0.3)
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
                        color: studied
                            ? Colors.green.withValues(alpha: intensity)
                            : cs.outline.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                if (studied) ...[
                  const SizedBox(height: 2),
                  Text(
                    _DashboardBody._formatHM(minutes),
                    style: TextStyle(
                      fontSize: 8,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
