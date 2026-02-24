// =============================================================
// DayActivitiesSheet — draggable bottom sheet for a selected date.
// Shows blocks from DayPlan, TimeLogEntry entries, StudyPlanItem
// deadlines as a timeline list with type chips.
// Android rules: enableDrag: false, useSafeArea: true.
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/time_log_entry.dart';
import 'package:focusflow_mobile/models/study_plan_item.dart';

// ── Unified activity item for display ─────────────────────────
enum _ActivityKind { block, timeLog, deadline }

class _ActivityItem {
  final _ActivityKind kind;
  final String title;
  final String? timeLabel;
  final String? subtitle;

  const _ActivityItem({
    required this.kind,
    required this.title,
    this.timeLabel,
    this.subtitle,
  });
}

// ── Public API ─────────────────────────────────────────────────
class DayActivitiesSheet extends StatelessWidget {
  final DateTime date;
  final List<Block> blocks;
  final List<TimeLogEntry> timeLogs;
  final List<StudyPlanItem> studyItems;

  const DayActivitiesSheet({
    super.key,
    required this.date,
    required this.blocks,
    required this.timeLogs,
    required this.studyItems,
  });

  // ── Build unified sorted activity list ─────────────────────
  List<_ActivityItem> _buildActivities() {
    final items = <_ActivityItem>[];

    for (final b in blocks) {
      items.add(_ActivityItem(
        kind: _ActivityKind.block,
        title: b.title,
        timeLabel: '${b.plannedStartTime} – ${b.plannedEndTime}',
        subtitle: b.type.value,
      ));
    }

    for (final t in timeLogs) {
      String start = t.startTime;
      String end = t.endTime;
      // Try to parse ISO and format as HH:mm
      try {
        final s = DateTime.parse(t.startTime);
        final e = DateTime.parse(t.endTime);
        start = DateFormat('HH:mm').format(s);
        end = DateFormat('HH:mm').format(e);
      } catch (_) {}
      items.add(_ActivityItem(
        kind: _ActivityKind.timeLog,
        title: t.activity,
        timeLabel: '$start – $end',
        subtitle: t.category.value,
      ));
    }

    for (final s in studyItems) {
      items.add(_ActivityItem(
        kind: _ActivityKind.deadline,
        title: s.topic,
        timeLabel: s.isCompleted ? 'Completed' : 'Due today',
        subtitle: 'Study Plan',
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final activities = _buildActivities();
    final dateLabel = DateFormat('EEE, d MMMM yyyy').format(date);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ───────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Activity count badge
                if (activities.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${activities.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Content ──────────────────────────────────────────
          Flexible(
            child: activities.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: activities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _ActivityCard(item: activities[index]);
                    },
                  ),
          ),

          // Bottom safe-area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ── Activity card ─────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final _ActivityItem item;
  const _ActivityCard({required this.item});

  Color _kindColor(ColorScheme cs) {
    switch (item.kind) {
      case _ActivityKind.block:
        return Colors.blue.shade400;
      case _ActivityKind.timeLog:
        return Colors.green.shade400;
      case _ActivityKind.deadline:
        return Colors.amber.shade600;
    }
  }

  String _chipLabel() {
    switch (item.kind) {
      case _ActivityKind.block:
        return 'Block';
      case _ActivityKind.timeLog:
        return 'Time Log';
      case _ActivityKind.deadline:
        return 'Study Plan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _kindColor(cs);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Color bar + timeline dot ───────────────────────
          Column(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 40,
                color: color.withValues(alpha: 0.25),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // ── Text content ───────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time label
                if (item.timeLabel != null)
                  Text(
                    item.timeLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 2),
                // Title
                Text(
                  item.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Type chip ─────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _chipLabel(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Text(
            'No activities',
            style: theme.textTheme.titleSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.3),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nothing planned or logged for this day.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
