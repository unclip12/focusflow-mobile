// =============================================================
// StudyPlanItemCard — compact card for study plan list items
// Shows: topic, subject (pageNumber), target date, completion
//        progress bar (completed subTasks / total), status chip.
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focusflow_mobile/models/study_plan_item.dart';
import 'package:focusflow_mobile/core/theme/app_colors.dart';

class StudyPlanItemCard extends StatelessWidget {
  final StudyPlanItem item;
  final VoidCallback? onTap;

  const StudyPlanItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // ── Progress computation ─────────────────────────────────────
    final tasks = item.subTasks ?? [];
    final totalTasks = tasks.length;
    final doneTasks = tasks.where((t) => t.done).length;
    final double progress =
        totalTasks > 0 ? doneTasks / totalTasks : (item.isCompleted ? 1.0 : 0.0);

    // ── Status chip ──────────────────────────────────────────────
    final bool isOverdue =
        !item.isCompleted && _isDatePast(item.date);

    String statusLabel;
    Color statusColor;
    if (item.isCompleted) {
      statusLabel = 'Done';
      statusColor = AppColors.success;
    } else if (isOverdue) {
      statusLabel = 'Overdue';
      statusColor = AppColors.error;
    } else {
      statusLabel = 'Pending';
      statusColor = AppColors.warning;
    }

    // ── Type icon ────────────────────────────────────────────────
    IconData typeIcon;
    switch (item.type) {
      case 'VIDEO':
        typeIcon = Icons.play_circle_outline_rounded;
        break;
      case 'HYBRID':
        typeIcon = Icons.layers_rounded;
        break;
      default:
        typeIcon = Icons.menu_book_rounded;
    }

    // ── Date formatting ──────────────────────────────────────────
    final dateDt = DateTime.tryParse(item.date);
    final dateStr = dateDt != null
        ? DateFormat('d MMM').format(dateDt)
        : item.date;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: type icon + topic + status chip ─────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeIcon, size: 16, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.topic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Meta row: page number + date + est. time ─────────
            Row(
              children: [
                if (item.pageNumber.isNotEmpty) ...[
                  Icon(Icons.description_outlined,
                      size: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 3),
                  Text(
                    'P ${item.pageNumber}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(Icons.calendar_today_rounded,
                    size: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 3),
                Text(
                  dateStr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isOverdue
                        ? AppColors.error
                        : cs.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.timer_outlined,
                    size: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 3),
                Text(
                  '${item.estimatedMinutes}m',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Progress bar ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(
                        item.isCompleted ? AppColors.success : cs.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  totalTasks > 0
                      ? '$doneTasks / $totalTasks'
                      : (item.isCompleted ? 'Complete' : 'No tasks'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isDatePast(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return false;
    final today = DateTime.now();
    return DateTime(dt.year, dt.month, dt.day)
        .isBefore(DateTime(today.year, today.month, today.day));
  }
}
