// =============================================================
// StudyPlanScreen — shows StudyPlanItem list grouped by week
// Uses AppScaffold. FAB to add new item via bottom sheet.
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/study_plan_item.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/screens/study_plan/study_plan_item_card.dart';
import 'package:focusflow_mobile/screens/study_plan/add_study_plan_sheet.dart';

class StudyPlanScreen extends StatelessWidget {
  const StudyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final items = app.studyPlan.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // ── Group by ISO week ────────────────────────────────────────
    final grouped = <String, List<StudyPlanItem>>{};
    for (final item in items) {
      final key = _weekKey(item.date);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    final weekKeys = grouped.keys.toList();

    return AppScaffold(
      screenName: 'Study Plan',
      floatingActionButton: FloatingActionButton(
        heroTag: 'study_plan_add',
        backgroundColor: cs.primary,
        onPressed: () => AddStudyPlanSheet.show(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_note_rounded,
                      size: 48,
                      color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text(
                    'No study plan items yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to add your first item',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: weekKeys.length,
              itemBuilder: (context, i) {
                final key = weekKeys[i];
                final weekItems = grouped[key]!;
                return _WeekSection(
                  weekLabel: _weekLabel(key),
                  items: weekItems,
                );
              },
            ),
    );
  }

  /// Returns a sortable key like '2026-W08' from a YYYY-MM-DD string.
  String _weekKey(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return 'Unknown';
    final weekNum = _isoWeekNumber(dt);
    return '${dt.year}-W${weekNum.toString().padLeft(2, '0')}';
  }

  /// Human-readable label from a week key. Shows the Monday date range.
  String _weekLabel(String key) {
    // Parse '2026-W08' back
    final parts = key.split('-W');
    if (parts.length != 2) return key;
    final year = int.tryParse(parts[0]);
    final week = int.tryParse(parts[1]);
    if (year == null || week == null) return key;
    final jan4 = DateTime(year, 1, 4);
    final monday =
        jan4.subtract(Duration(days: jan4.weekday - 1)).add(Duration(days: (week - 1) * 7));
    final sunday = monday.add(const Duration(days: 6));
    final fmt = DateFormat('d MMM');
    return '${fmt.format(monday)} – ${fmt.format(sunday)}';
  }

  int _isoWeekNumber(DateTime dt) {
    final dayOfYear = int.parse(DateFormat('D').format(dt));
    return ((dayOfYear - dt.weekday + 10) / 7).floor();
  }
}

// ── Week section widget ─────────────────────────────────────────
class _WeekSection extends StatelessWidget {
  final String weekLabel;
  final List<StudyPlanItem> items;

  const _WeekSection({required this.weekLabel, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final done = items.where((i) => i.isCompleted).length;
    final total = items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // ── Week header ──────────────────────────────────────────
        Row(
          children: [
            Text(
              weekLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$done/$total',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // ── Items ────────────────────────────────────────────────
        ...items.map((item) => StudyPlanItemCard(item: item)),
        const SizedBox(height: 4),
      ],
    );
  }
}
