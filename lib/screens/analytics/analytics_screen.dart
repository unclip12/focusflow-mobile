// =============================================================
// AnalyticsScreen — full analytics dashboard
// Sections: Study Hours bar chart, Category pie chart,
//           Block completion line chart, Streak history,
//           Subject breakdown.
// Time range selector: 7d / 30d / 90d in header.
// Android rules: resizeToAvoidBottomInset: true (AppScaffold).
// =============================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/screens/analytics/analytics_chart_card.dart';
import 'package:focusflow_mobile/screens/analytics/subject_breakdown_card.dart';

// ── Colour palette for pie / legend ──────────────────────────────
const _kPieColors = [
  Color(0xFF6366F1), // indigo  – study
  Color(0xFF8B5CF6), // violet  – revision
  Color(0xFFEC4899), // pink    – qbank
  Color(0xFFF59E0B), // amber   – anki
  Color(0xFF3B82F6), // blue    – video
  Color(0xFF10B981), // emerald – notes
  Color(0xFF94A3B8), // slate   – other
];

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _rangeDays = 7; // 7 | 30 | 90

  // ── Range helper ───────────────────────────────────────────────
  String get _rangeBadge => '${_rangeDays}d';

  // ── Build date-range filter ────────────────────────────────────
  bool _inRange(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return false;
    return DateTime.now().difference(date).inDays < _rangeDays;
  }

  // ── Daily hours map ────────────────────────────────────────────
  Map<String, double> _buildDailyHours(AppProvider app) {
    final map = <String, double>{};
    for (final log in app.timeLogs) {
      if (!_inRange(log.date)) continue;
      map[log.date] = (map[log.date] ?? 0) + log.durationMinutes / 60.0;
    }
    return map;
  }

  // ── Category breakdown ─────────────────────────────────────────
  Map<TimeLogCategory, double> _buildCategoryHours(AppProvider app) {
    final map = <TimeLogCategory, double>{};
    for (final log in app.timeLogs) {
      if (!_inRange(log.date)) continue;
      map[log.category] =
          (map[log.category] ?? 0) + log.durationMinutes / 60.0;
    }
    return map;
  }

  // ── Block completion rate per day ──────────────────────────────
  /// Returns list of (date, completionFraction) sorted ascending.
  List<_DayCompletion> _buildCompletionRate(AppProvider app) {
    final result = <_DayCompletion>[];
    for (final plan in app.dayPlans) {
      if (!_inRange(plan.date)) continue;
      final blocks = plan.blocks ?? [];
      if (blocks.isEmpty) continue;
      final done =
          blocks.where((b) => b.status.value == 'COMPLETED').length;
      result.add(_DayCompletion(
        date:     plan.date,
        fraction: done / blocks.length,
      ));
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  // ── Subject breakdown (from timeLogs.activity) ─────────────────
  /// Returns `AppProvider.getSubjectBreakdown()` equivalent:
  /// group by activity (subject label) for study/revision logs only.
  List<SubjectEntry> _buildSubjectBreakdown(AppProvider app) {
    final map = <String, double>{};
    final studyCats = {
      TimeLogCategory.study,
      TimeLogCategory.revision,
      TimeLogCategory.video,
      TimeLogCategory.qbank,
      TimeLogCategory.anki,
    };

    for (final log in app.timeLogs) {
      if (!_inRange(log.date)) continue;
      if (!studyCats.contains(log.category)) continue;
      final subject = log.activity.isNotEmpty ? log.activity : 'Other';
      map[subject] = (map[subject] ?? 0) + log.durationMinutes / 60.0;
    }

    if (map.isEmpty) return [];

    final total = map.values.fold<double>(0, (s, v) => s + v);
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.map((e) {
      final frac = total > 0 ? e.value / total : 0.0;
      return SubjectEntry(
        subject:    e.key,
        hours:      e.value,
        fraction:   frac,
        percentage: (frac * 100).round(),
      );
    }).take(8).toList();
  }

  // ── Streak history (rolling window) ───────────────────────────
  /// Returns map of dateStr → bool (had activity).
  List<_StreakDay> _buildStreakHistory(AppProvider app) {
    final minutesByDate = <String, int>{};
    for (final log in app.timeLogs) {
      minutesByDate[log.date] =
          (minutesByDate[log.date] ?? 0) + log.durationMinutes;
    }

    final days = <_StreakDay>[];
    final now  = DateTime.now();
    for (int i = _rangeDays - 1; i >= 0; i--) {
      final d       = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      days.add(_StreakDay(date: d, hasActivity: (minutesByDate[dateStr] ?? 0) > 0));
    }
    return days;
  }

  // ── Total hours in range ───────────────────────────────────────
  double _totalHours(AppProvider app) {
    return app.timeLogs
        .where((l) => _inRange(l.date))
        .fold<double>(0, (s, l) => s + l.durationMinutes / 60.0);
  }

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    final dailyHours      = _buildDailyHours(app);
    final categoryHours   = _buildCategoryHours(app);
    final completionRates = _buildCompletionRate(app);
    final subjectData     = _buildSubjectBreakdown(app);
    final streakHistory   = _buildStreakHistory(app);
    final totalHrs        = _totalHours(app);

    return AppScaffold(
      screenName: 'Analytics',
      actions: [
        // ── Range selector ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [7, 30, 90].map((d) {
              final selected = _rangeDays == d;
              return GestureDetector(
                onTap: () => setState(() => _rangeDays = d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${d}d',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected
                          ? cs.onPrimary
                          : cs.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          // ── Summary strip ────────────────────────────────────
          _SummaryStrip(
            totalHours: totalHrs,
            studyDays:  dailyHours.length,
            rangeDays:  _rangeDays,
          ),
          const SizedBox(height: 16),

          // ── 1. Study Hours bar chart ─────────────────────────
          AnalyticsChartCard(
            title:      'Study Hours',
            subtitle:   'Daily hours studied',
            rangeBadge: _rangeBadge,
            child: _StudyHoursChart(
              dailyHours: dailyHours,
              rangeDays:  _rangeDays,
            ),
          ),
          const SizedBox(height: 14),

          // ── 2. Category Pie ──────────────────────────────────
          AnalyticsChartCard(
            title:      'Time Breakdown',
            subtitle:   'Study type distribution',
            rangeBadge: _rangeBadge,
            child: _CategoryPieChart(categoryHours: categoryHours),
          ),
          const SizedBox(height: 14),

          // ── 3. Block completion line chart ───────────────────
          AnalyticsChartCard(
            title:      'Block Completion Rate',
            subtitle:   'Daily plan completion (%)',
            rangeBadge: _rangeBadge,
            child: completionRates.isEmpty
                ? _EmptyChartPlaceholder(
                    'No block data for $_rangeBadge')
                : _CompletionLineChart(data: completionRates),
          ),
          const SizedBox(height: 14),

          // ── 4. Streak history heatmap row ────────────────────
          AnalyticsChartCard(
            title:      'Activity Streak',
            subtitle:   'Days with study sessions',
            rangeBadge: _rangeBadge,
            contentPadding:
                const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: _StreakGrid(days: streakHistory),
          ),
          const SizedBox(height: 14),

          // ── 5. Subject breakdown ─────────────────────────────
          AnalyticsChartCard(
            title:      'Top Subjects',
            subtitle:   'Hours per subject (study + revision)',
            rangeBadge: _rangeBadge,
            child: SubjectBreakdownCard(
              subjects:   subjectData,
              rangeBadge: _rangeBadge,
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SUMMARY STRIP
// ══════════════════════════════════════════════════════════════════

class _SummaryStrip extends StatelessWidget {
  final double totalHours;
  final int    studyDays;
  final int    rangeDays;

  const _SummaryStrip({
    required this.totalHours,
    required this.studyDays,
    required this.rangeDays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    final avg = studyDays > 0 ? totalHours / studyDays : 0.0;

    return Row(
      children: [
        _StatPill(
          cs:    cs, theme: theme,
          label: 'Total',
          value: '${totalHours.toStringAsFixed(1)}h',
          icon:  Icons.timer_rounded,
          color: cs.primary,
        ),
        const SizedBox(width: 10),
        _StatPill(
          cs:    cs, theme: theme,
          label: 'Active days',
          value: '$studyDays',
          icon:  Icons.calendar_today_rounded,
          color: const Color(0xFF10B981),
        ),
        const SizedBox(width: 10),
        _StatPill(
          cs:    cs, theme: theme,
          label: 'Avg/day',
          value: '${avg.toStringAsFixed(1)}h',
          icon:  Icons.trending_up_rounded,
          color: const Color(0xFFF59E0B),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final ColorScheme cs;
  final ThemeData   theme;
  final String      label;
  final String      value;
  final IconData    icon;
  final Color       color;

  const _StatPill({
    required this.cs,
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color:        cs.surface,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                )),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// STUDY HOURS BAR CHART
// ══════════════════════════════════════════════════════════════════

class _StudyHoursChart extends StatelessWidget {
  final Map<String, double> dailyHours;
  final int rangeDays;

  const _StudyHoursChart({
    required this.dailyHours,
    required this.rangeDays,
  });

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final data = List.generate(rangeDays, (i) {
      final d       = now.subtract(Duration(days: rangeDays - 1 - i));
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      return _Bar(
        x:     i.toDouble(),
        hours: dailyHours[dateStr] ?? 0,
        label: DateFormat('d').format(d),
      );
    });

    final maxH = data.fold<double>(0, (m, b) => b.hours > m ? b.hours : m);
    final yMax = maxH < 1 ? 2.0 : (maxH * 1.3).ceilToDouble();

    // Thin bars for >= 30 days
    final barW = rangeDays <= 7 ? 18.0 : (rangeDays <= 30 ? 9.0 : 5.0);
    // Label skip interval
    final labelEvery = rangeDays <= 7 ? 1 : (rangeDays <= 30 ? 5 : 14);

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: yMax,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)}h',
                TextStyle(
                  color:      cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize:   12,
                ),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                reservedSize: 28,
                interval:     yMax < 4 ? 1 : (yMax / 3).ceilToDouble(),
                getTitlesWidget: (v, _) => Text('${v.toInt()}h',
                    style: TextStyle(
                      fontSize: 9,
                      color:    cs.onSurface.withValues(alpha: 0.4),
                    )),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  if (i % labelEvery != 0) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(data[i].label,
                        style: TextStyle(
                          fontSize: 9,
                          color:    cs.onSurface.withValues(alpha: 0.45),
                        )),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show:             true,
            drawVerticalLine: false,
            horizontalInterval: yMax < 4 ? 1 : (yMax / 3).ceilToDouble(),
            getDrawingHorizontalLine: (_) => FlLine(
              color:       cs.onSurface.withValues(alpha: 0.06),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.map((b) {
            final isToday = b.x == data.length - 1;
            return BarChartGroupData(x: b.x.toInt(), barRods: [
              BarChartRodData(
                toY:          b.hours,
                width:        barW,
                borderRadius: BorderRadius.circular(4),
                color:        isToday
                    ? cs.primary
                    : cs.primary.withValues(alpha: 0.35),
              ),
            ]);
          }).toList(),
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class _Bar {
  final double x;
  final double hours;
  final String label;
  const _Bar({required this.x, required this.hours, required this.label});
}

// ══════════════════════════════════════════════════════════════════
// CATEGORY PIE CHART
// ══════════════════════════════════════════════════════════════════

class _CategoryPieChart extends StatefulWidget {
  final Map<TimeLogCategory, double> categoryHours;
  const _CategoryPieChart({required this.categoryHours});

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int _touchedIndex = -1;

  static const _kLabels = {
    TimeLogCategory.study:         'Study',
    TimeLogCategory.revision:      'Revision',
    TimeLogCategory.qbank:         'QBank',
    TimeLogCategory.anki:          'Anki',
    TimeLogCategory.video:         'Video',
    TimeLogCategory.noteTaking:    'Notes',
    TimeLogCategory.breakTime:     'Break',
    TimeLogCategory.personal:      'Personal',
    TimeLogCategory.sleep:         'Sleep',
    TimeLogCategory.entertainment: 'Entertainment',
    TimeLogCategory.outing:        'Outing',
    TimeLogCategory.life:          'Life',
    TimeLogCategory.other:         'Other',
  };

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final entries = widget.categoryHours.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return _EmptyChartPlaceholder('No data');
    }

    final total  = entries.fold<double>(0, (s, e) => s + e.value);
    final colors = List.generate(entries.length,
        (i) => _kPieColors[i % _kPieColors.length]);

    return Row(
      children: [
        // ── Pie chart ────────────────────────────────────────────
        SizedBox(
          width:  140,
          height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace:    2,
              centerSpaceRadius: 30,
              pieTouchData: PieTouchData(
                touchCallback: (ev, pieTouchResponse) {
                  setState(() {
                    if (!ev.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse
                        .touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: List.generate(entries.length, (i) {
                final touched = i == _touchedIndex;
                final pct =
                    total > 0 ? entries[i].value / total * 100 : 0.0;
                return PieChartSectionData(
                  value:      entries[i].value,
                  color:      colors[i],
                  radius:     touched ? 56 : 48,
                  title:      touched ? '${pct.toStringAsFixed(0)}%' : '',
                  titleStyle: TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w700,
                    color:      Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // ── Legend ───────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              entries.length.clamp(0, 6),
              (i) {
                final pct =
                    total > 0 ? entries[i].value / total * 100 : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Container(
                        width:  10, height: 10,
                        decoration: BoxDecoration(
                          color:  colors[i],
                          shape:  BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _kLabels[entries[i].key] ?? entries[i].key.value,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:      colors[i],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// BLOCK COMPLETION LINE CHART
// ══════════════════════════════════════════════════════════════════

class _DayCompletion {
  final String date;
  final double fraction;
  const _DayCompletion({required this.date, required this.fraction});
}

class _CompletionLineChart extends StatelessWidget {
  final List<_DayCompletion> data;
  const _CompletionLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    const color = Color(0xFF10B981);

    final spots = List.generate(data.length,
        (i) => FlSpot(i.toDouble(), data[i].fraction * 100));

    return SizedBox(
      height: 140,
      child: LineChart(
        LineChartData(
          minY: 0, maxY: 100,
          clipData: const FlClipData.all(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) =>
                  LineTooltipItem(
                    '${s.y.toStringAsFixed(0)}%',
                    TextStyle(
                      color:      cs.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize:   12,
                    ),
                  )).toList(),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                reservedSize: 30,
                interval:     25,
                getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                    style: TextStyle(
                      fontSize: 9,
                      color:    cs.onSurface.withValues(alpha: 0.4),
                    )),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  if (data.length > 10 && i % 3 != 0)
                    return const SizedBox();
                  final d = DateTime.tryParse(data[i].date);
                  if (d == null) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(DateFormat('d').format(d),
                        style: TextStyle(
                          fontSize: 9,
                          color:    cs.onSurface.withValues(alpha: 0.45),
                        )),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show:               true,
            drawVerticalLine:   false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(
              color:       cs.onSurface.withValues(alpha: 0.06),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots:        spots,
              isCurved:     true,
              curveSmoothness: 0.35,
              color:        color,
              barWidth:     2.5,
              dotData:      FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color:  color,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show:  true,
                color: color.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// STREAK GRID (mini heatmap dots)
// ══════════════════════════════════════════════════════════════════

class _StreakDay {
  final DateTime date;
  final bool     hasActivity;
  const _StreakDay({required this.date, required this.hasActivity});
}

class _StreakGrid extends StatelessWidget {
  final List<_StreakDay> days;
  const _StreakGrid({required this.days});

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // Current streak count
    int streak = 0;
    for (final d in days.reversed) {
      if (d.hasActivity) {
        streak++;
      } else if (d.date.day == DateTime.now().day) {
        continue; // allow today to be empty
      } else {
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Streak count
        Row(
          children: [
            Text('🔥', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              '$streak day streak',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color:      streak > 0
                    ? const Color(0xFFFF6B35)
                    : cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Dot grid
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: days.map((d) {
            return Tooltip(
              message: DateFormat('d MMM').format(d.date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width:  10,
                height: 10,
                decoration: BoxDecoration(
                  color: d.hasActivity
                      ? cs.primary.withValues(alpha: 0.8)
                      : cs.onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _LegendDot(color: cs.onSurface.withValues(alpha: 0.1),
                label: 'No study'),
            const SizedBox(width: 10),
            _LegendDot(color: cs.primary.withValues(alpha: 0.8),
                label: 'Studied'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color  color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color:        color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        )),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SHARED EMPTY PLACEHOLDER
// ══════════════════════════════════════════════════════════════════

class _EmptyChartPlaceholder extends StatelessWidget {
  final String message;
  const _EmptyChartPlaceholder(this.message);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
