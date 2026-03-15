// =============================================================
// AnalyticsScreen — full analytics dashboard (G13)
// Sections: FA Progress, Study Time, Subject Breakdown,
//           UWorld Performance, Resource Completion.
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final settings = context.watch<SettingsProvider>();

    return AppScaffold(
      screenName: 'Analytics',
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 72 + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SECTION 1: FA Progress Overview ────────────
            _FAProgressCard(app: app, settings: settings),
            const SizedBox(height: 16),

            // ── SECTION 2: Study Time ─────────────────────
            _StudyTimeCard(app: app),
            const SizedBox(height: 16),

            // ── SECTION 3: Subject Breakdown ──────────────
            _SubjectBreakdownCard(app: app),
            const SizedBox(height: 16),

            // ── SECTION 4: UWorld Performance ─────────────
            _UWorldCard(app: app),
            const SizedBox(height: 16),

            // ── SECTION 5: Resource Completion ────────────
            _ResourceTrackerCard(app: app),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ══════════════════════════════════════════════════════════════════

/// Standard card wrapper with 12px radius and 16px padding inside.
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? DashboardColors.glassBorderDark
                  : DashboardColors.glassBorderLight,
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 12),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small stat chip.
class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Format minutes as "Xh Ym".
String _fmtMinutes(int mins) {
  final h = mins ~/ 60;
  final m = mins % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Returns list of last 7 days (DateTime), oldest first.
List<DateTime> _last7Days() {
  final now = DateTime.now();
  return List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
}

/// Day abbreviation (Mon, Tue...).
String _dayAbbr(DateTime d) => DateFormat('E').format(d).substring(0, 3);

/// Date key.
String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

// ══════════════════════════════════════════════════════════════════
// SECTION 1: FA PROGRESS OVERVIEW
// ══════════════════════════════════════════════════════════════════

class _FAProgressCard extends StatelessWidget {
  final AppProvider app;
  final SettingsProvider settings;

  const _FAProgressCard({required this.app, required this.settings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    const totalPages = 676;

    final readCount = app.faPages
        .where((p) => p.status == 'read' || p.status == 'anki_done')
        .length;
    final ankiCount = app.faPages.where((p) => p.status == 'anki_done').length;
    final remainCount = app.faPages.where((p) => p.status == 'unread').length;

    final pct = totalPages > 0 ? (readCount / totalPages * 100) : 0.0;
    final progress = totalPages > 0 ? readCount / totalPages : 0.0;

    final dailyGoal = settings.dailyFAGoal;

    // Build last 7 days proxy pages from timeLogs
    final days = _last7Days();
    final dayProxyPages = <String, double>{};
    for (final log in app.timeLogs) {
      if (log.category.value == 'STUDY' ||
          log.activity.toLowerCase().contains('fa')) {
        dayProxyPages[log.date] =
            (dayProxyPages[log.date] ?? 0) + log.durationMinutes / 3.0;
      }
    }

    return _SectionCard(
      title: 'First Aid 2025',
      children: [
        // Stat chips
        Row(
          children: [
            _StatChip(label: '$readCount Read', color: cs.primary),
            const SizedBox(width: 8),
            _StatChip(label: '$ankiCount Anki Done', color: Colors.deepPurple),
            const SizedBox(width: 8),
            _StatChip(
                label: '$remainCount Remaining', color: cs.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: 12),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: cs.onSurface.withValues(alpha: 0.07),
            valueColor: AlwaysStoppedAnimation(cs.primary),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$readCount / $totalPages pages · ${pct.toStringAsFixed(1)}% complete',
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 16),

        // Bar chart title
        Text(
          'Pages Read Last 7 Days',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),

        // Bar chart
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: _barMaxY(days, dayProxyPages, dailyGoal.toDouble()),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    '${rod.toY.toStringAsFixed(0)} pg',
                    TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= days.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          _dayAbbr(days[i]),
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval:
                    _barMaxY(days, dayProxyPages, dailyGoal.toDouble()) / 3,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: cs.onSurface.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: dailyGoal.toDouble(),
                    color: cs.error.withValues(alpha: 0.5),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      labelResolver: (_) => 'Goal: $dailyGoal',
                      style: TextStyle(
                        fontSize: 9,
                        color: cs.error.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              barGroups: List.generate(days.length, (i) {
                final key = _dateKey(days[i]);
                final val = (dayProxyPages[key] ?? 0).roundToDouble();
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: val,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                    color: cs.primary,
                  ),
                ]);
              }),
            ),
            duration: const Duration(milliseconds: 300),
          ),
        ),
      ],
    );
  }

  double _barMaxY(List<DateTime> days, Map<String, double> proxy, double goal) {
    double mx = goal;
    for (final d in days) {
      final v = proxy[_dateKey(d)] ?? 0;
      if (v > mx) mx = v;
    }
    return mx < 1 ? 2 : (mx * 1.3).ceilToDouble();
  }
}

// ══════════════════════════════════════════════════════════════════
// SECTION 2: STUDY TIME — LAST 7 DAYS
// ══════════════════════════════════════════════════════════════════

class _StudyTimeCard extends StatelessWidget {
  final AppProvider app;

  const _StudyTimeCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final days = _last7Days();

    // Minutes per day
    final dayMins = <String, int>{};
    for (final log in app.timeLogs) {
      dayMins[log.date] = (dayMins[log.date] ?? 0) + log.durationMinutes;
    }

    // Only last 7 days
    int weekTotal = 0;
    for (final d in days) {
      weekTotal += dayMins[_dateKey(d)] ?? 0;
    }
    final avgMins = days.isNotEmpty ? weekTotal ~/ 7 : 0;

    final maxMins = days.fold<int>(
        0,
        (m, d) =>
            (dayMins[_dateKey(d)] ?? 0) > m ? (dayMins[_dateKey(d)] ?? 0) : m);
    final yMax = maxMins < 30 ? 60.0 : (maxMins * 1.3).ceilToDouble();

    return _SectionCard(
      title: 'Study Time — Last 7 Days',
      children: [
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: yMax,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    _fmtMinutes(rod.toY.toInt()),
                    TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= days.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          _dayAbbr(days[i]),
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yMax / 3,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: cs.onSurface.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(days.length, (i) {
                final key = _dateKey(days[i]);
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: (dayMins[key] ?? 0).toDouble(),
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.teal,
                  ),
                ]);
              }),
            ),
            duration: const Duration(milliseconds: 300),
          ),
        ),
        const SizedBox(height: 12),

        // Summary chips
        Row(
          children: [
            _StatChip(
              label: 'This week: ${_fmtMinutes(weekTotal)}',
              color: Colors.teal,
            ),
            const SizedBox(width: 8),
            _StatChip(
              label: 'Daily avg: ${_fmtMinutes(avgMins)}',
              color: Colors.teal,
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SECTION 3: SUBJECT BREAKDOWN (Time by Subject)
// ══════════════════════════════════════════════════════════════════

class _SubjectBreakdownCard extends StatelessWidget {
  final AppProvider app;

  const _SubjectBreakdownCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // Group timeLogs by activity/category → top 5 by minutes
    final grouped = <String, int>{};
    for (final log in app.timeLogs) {
      final key = log.activity.isNotEmpty ? log.activity : log.category.value;
      grouped[key] = (grouped[key] ?? 0) + log.durationMinutes;
    }

    if (grouped.isEmpty) {
      return _SectionCard(
        title: 'Time by Subject',
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No time logs yet',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final sorted = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();
    final maxMins = top5.first.value;

    const barColors = [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
    ];

    return _SectionCard(
      title: 'Time by Subject',
      children: [
        ...List.generate(top5.length, (i) {
          final entry = top5[i];
          final frac = maxMins > 0 ? entry.value / maxMins : 0.0;
          final color = barColors[i % barColors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    entry.key,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: frac.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: cs.onSurface.withValues(alpha: 0.07),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _fmtMinutes(entry.value),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SECTION 4: UWORLD PERFORMANCE
// ══════════════════════════════════════════════════════════════════

class _UWorldCard extends StatelessWidget {
  final AppProvider app;

  const _UWorldCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sessions = app.uWorldSessions;

    if (sessions.isEmpty) {
      return _SectionCard(
        title: 'UWorld Q-Bank',
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No UWorld sessions logged yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
              ),
            ),
          ),
        ],
      );
    }

    // Overall stats
    final totalQs = sessions.fold<int>(0, (s, e) => s + e.done);
    final totalCorrect = sessions.fold<int>(0, (s, e) => s + e.correct);
    final overallPct = totalQs > 0 ? (totalCorrect / totalQs * 100) : 0.0;

    // Last 10 sessions for line chart
    final recent = sessions.length > 10
        ? sessions.sublist(sessions.length - 10)
        : sessions;

    return _SectionCard(
      title: 'UWorld Q-Bank',
      children: [
        // Overall stats row
        Row(
          children: [
            _StatChip(label: 'Total Qs: $totalQs', color: Colors.orange),
            const SizedBox(width: 8),
            _StatChip(
                label: 'Overall: ${overallPct.toStringAsFixed(0)}%',
                color: Colors.orange),
            const SizedBox(width: 8),
            _StatChip(
                label: 'Sessions: ${sessions.length}', color: Colors.orange),
          ],
        ),
        const SizedBox(height: 16),

        // Line chart or message
        if (recent.length < 2)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                'Log more sessions to see trend',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
              ),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                clipData: const FlClipData.all(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map((s) => LineTooltipItem(
                              '${s.y.toStringAsFixed(0)}%',
                              TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= recent.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: cs.onSurface.withValues(alpha: 0.06),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(recent.length, (i) {
                      final s = recent[i];
                      final pct = s.done > 0 ? s.correct / s.done * 100 : 0.0;
                      return FlSpot(i.toDouble(), pct);
                    }),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: Colors.orange,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3,
                        color: Colors.orange,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SECTION 5: RESOURCE COMPLETION
// ══════════════════════════════════════════════════════════════════

class _ResourceTrackerCard extends StatelessWidget {
  final AppProvider app;

  const _ResourceTrackerCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // FA
    const faTotal = 676;
    final faRead = app.faPages
        .where((p) => p.status == 'read' || p.status == 'anki_done')
        .length;
    final faPct = faTotal > 0 ? (faRead / faTotal * 100) : 0.0;

    // Sketchy
    final skTotal = app.sketchyItems.length;
    final skDone = app.sketchyItems
        .where((s) => s.status == 'watched' || s.status == 'mastered')
        .length;

    // Pathoma
    final paTotal = app.pathomaItems.length;
    final paDone = app.pathomaItems
        .where((p) => p.status == 'watched' || p.status == 'reviewed')
        .length;

    return _SectionCard(
      title: 'Resource Tracker',
      children: [
        _ResourceRow(
          label: 'First Aid 2025',
          done: faRead,
          total: faTotal,
          suffix: '${faPct.toStringAsFixed(0)}%',
          color: cs.primary,
        ),
        const SizedBox(height: 10),
        _ResourceRow(
          label: 'Sketchy',
          done: skDone,
          total: skTotal,
          suffix: '$skDone / $skTotal watched',
          color: const Color(0xFF8B5CF6),
        ),
        const SizedBox(height: 10),
        _ResourceRow(
          label: 'Pathoma',
          done: paDone,
          total: paTotal,
          suffix: '$paDone / $paTotal chapters',
          color: const Color(0xFFEC4899),
        ),
      ],
    );
  }
}

class _ResourceRow extends StatelessWidget {
  final String label;
  final int done;
  final int total;
  final String suffix;
  final Color color;

  const _ResourceRow({
    required this.label,
    required this.done,
    required this.total,
    required this.suffix,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final frac = total > 0 ? done / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              suffix,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: frac.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: cs.onSurface.withValues(alpha: 0.07),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
