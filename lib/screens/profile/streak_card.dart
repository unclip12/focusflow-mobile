// =============================================================
// StreakCard â€” fire emoji + current streak, longest streak,
// 7-day mini activity grid derived from AppProvider.timeLogs
// and AppProvider.dayPlans.
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';

class StreakCard extends StatelessWidget {
  final AppProvider ap;

  const StreakCard({super.key, required this.ap});

  // â”€â”€ Compute streak + 7-day activity from timeLogs/dayPlans â”€â”€
  _StreakData _compute() {
    final today = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');

    // Build a set of days that had any study activity
    final activeDays = <String>{};
    for (final log in ap.timeLogs) {
      activeDays.add(log.date);
    }
    for (final plan in ap.dayPlans) {
      final blocks = plan.blocks ?? [];
      final hasDone = blocks.any((b) => b.status.value == 'DONE');
      if (hasDone) activeDays.add(plan.date);
    }

    // Current streak: count backwards from yesterday (today may be in progress)
    int current = 0;
    var cursor = today;
    while (true) {
      final key = fmt.format(cursor);
      if (activeDays.contains(key)) {
        current++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // Longest streak: scan all sorted active days
    final sorted = activeDays.toList()..sort();
    int longest = 0;
    int run = 0;
    DateTime? prev;
    for (final ds in sorted) {
      final d = DateTime.parse(ds);
      if (prev == null) {
        run = 1;
      } else {
        final diff = d.difference(prev).inDays;
        run = diff == 1 ? run + 1 : 1;
      }
      if (run > longest) longest = run;
      prev = d;
    }

    // 7-day grid: last 7 days including today
    final grid = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return _DayActivity(
        date: day,
        active: activeDays.contains(fmt.format(day)),
        isToday: i == 6,
      );
    });

    return _StreakData(current: current, longest: longest, grid: grid);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final data = _compute();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // â”€â”€ Streak numbers row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Row(
            children: [
              // Current streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('ðŸ”¥', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 6),
                        Text(
                          '${data.current}',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'day streak',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                width: 1,
                height: 44,
                color: cs.onSurface.withValues(alpha: 0.08),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),

              // Longest streak
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${data.longest}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    'longest',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.35),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // â”€â”€ 7-day activity grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Row(
            children: data.grid.map((day) {
              return Expanded(
                child: _DaySquare(day: day, cs: cs, theme: theme),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Data model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _StreakData {
  final int current;
  final int longest;
  final List<_DayActivity> grid;
  const _StreakData(
      {required this.current, required this.longest, required this.grid});
}

class _DayActivity {
  final DateTime date;
  final bool active;
  final bool isToday;
  const _DayActivity(
      {required this.date, required this.active, required this.isToday});
}

// â”€â”€ Mini day square widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DaySquare extends StatelessWidget {
  final _DayActivity day;
  final ColorScheme cs;
  final ThemeData theme;

  const _DaySquare(
      {required this.day, required this.cs, required this.theme});

  @override
  Widget build(BuildContext context) {
    final Color fill = day.active
        ? cs.primary
        : cs.onSurface.withValues(alpha: 0.07);
    final Color border = day.isToday
        ? cs.primary.withValues(alpha: 0.5)
        : Colors.transparent;
    final label = DateFormat('E').format(day.date)[0]; // M T W T F S S

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 28,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border, width: 1.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            color: cs.onSurface.withValues(alpha: 0.35),
            fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
