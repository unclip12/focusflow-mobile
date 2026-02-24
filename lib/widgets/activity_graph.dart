// =============================================================
// ActivityGraph — 14-day study hours bar chart using fl_chart
// Data sourced from AppProvider.timeLogs
// =============================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Bar chart showing study hours per day for the last [days] days.
class ActivityGraph extends StatelessWidget {
  final List<_DayData> _data;
  final int _days;

  const ActivityGraph._({required List<_DayData> data, required int days})
      : _data = data,
        _days = days;

  /// Build from a list of date→durationMinutes pairs.
  /// [minutesByDate] — map of 'YYYY-MM-DD' → total minutes studied.
  factory ActivityGraph({
    Key? key,
    required Map<String, int> minutesByDate,
    int days = 14,
  }) {
    final now = DateTime.now();
    final data = <_DayData>[];
    for (int i = days - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      final mins = minutesByDate[dateStr] ?? 0;
      data.add(_DayData(
        date: d,
        label: DateFormat('d').format(d),
        weekday: DateFormat('E').format(d).substring(0, 2),
        hours: mins / 60.0,
      ));
    }
    return ActivityGraph._(data: data, days: days);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final maxY = _data.fold<double>(0, (m, d) => d.hours > m ? d.hours : m);
    final yMax = maxY < 1 ? 2.0 : (maxY * 1.3).ceilToDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text('Study Activity',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('Last $_days days',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                    fontSize: 12,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: yMax,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gi, rod, ri) {
                      final d = _data[group.x.toInt()];
                      return BarTooltipItem(
                        '${d.hours.toStringAsFixed(1)}h',
                        TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: yMax < 4 ? 1 : (yMax / 3).ceilToDouble(),
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}h',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= _data.length) return const SizedBox();
                        // Show every other label for 14 days
                        if (_days > 7 && i % 2 != 0) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _data[i].label,
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
                  horizontalInterval: yMax < 4 ? 1 : (yMax / 3).ceilToDouble(),
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: cs.onSurface.withValues(alpha: 0.06),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_data.length, (i) {
                  final d = _data[i];
                  final isToday = i == _data.length - 1;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: d.hours,
                        width: _days > 7 ? 10 : 16,
                        borderRadius: BorderRadius.circular(4),
                        color: isToday
                            ? cs.primary
                            : cs.primary.withValues(alpha: 0.35),
                      ),
                    ],
                  );
                }),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayData {
  final DateTime date;
  final String label;
  final String weekday;
  final double hours;

  const _DayData({
    required this.date,
    required this.label,
    required this.weekday,
    required this.hours,
  });
}
