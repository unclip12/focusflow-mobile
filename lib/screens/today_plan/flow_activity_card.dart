// =============================================================
// FlowActivityCard — visual card for each activity in the flow
// Shows icon, label, status, linked tasks, time tracking
// =============================================================

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/daily_flow.dart';

class FlowActivityCard extends StatelessWidget {
  final FlowActivity activity;
  final int index;
  final VoidCallback? onComplete;
  final VoidCallback? onUndo;
  final VoidCallback? onTap;

  const FlowActivityCard({
    super.key,
    required this.activity,
    required this.index,
    this.onComplete,
    this.onUndo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (activity.status) {
      case 'DONE':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Done';
      case 'IN_PROGRESS':
        statusColor = const Color(0xFF3B82F6);
        statusIcon = Icons.play_circle_filled_rounded;
        statusLabel = 'Active';
      case 'PAUSED':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.pause_circle_filled_rounded;
        statusLabel = 'Paused';
      case 'SKIPPED':
        statusColor = cs.onSurface.withValues(alpha: 0.3);
        statusIcon = Icons.skip_next_rounded;
        statusLabel = 'Skipped';
      default:
        statusColor = cs.onSurface.withValues(alpha: 0.25);
        statusIcon = Icons.circle_outlined;
        statusLabel = '';
    }

    // Duration display
    String? durationStr;
    if (activity.isDone && activity.durationSeconds != null) {
      final dur = Duration(seconds: activity.durationSeconds!);
      if (dur.inHours > 0) {
        durationStr =
            '${dur.inHours}h ${dur.inMinutes.remainder(60)}m';
      } else if (dur.inMinutes > 0) {
        durationStr =
            '${dur.inMinutes}m ${dur.inSeconds.remainder(60)}s';
      } else {
        durationStr = '${dur.inSeconds}s';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: activity.isActive
            ? BorderSide(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), width: 1.5)
            : BorderSide.none,
      ),
      color: activity.isDone
          ? const Color(0xFF10B981).withValues(alpha: 0.06)
          : activity.isActive
              ? const Color(0xFF3B82F6).withValues(alpha: 0.06)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Status icon / index
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: activity.isNotStarted
                      ? Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        )
                      : Icon(statusIcon, size: 20, color: statusColor),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          activity.icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            activity.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: activity.isDone
                                  ? cs.onSurface.withValues(alpha: 0.5)
                                  : cs.onSurface,
                              decoration: activity.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (activity.linkedTaskIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          '${activity.linkedTaskIds.length} task${activity.linkedTaskIds.length == 1 ? '' : 's'} linked',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.primary.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    if (durationStr != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 12,
                                color: const Color(0xFF10B981).withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              durationStr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981).withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (statusLabel.isNotEmpty && !activity.isNotStarted)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Actions
              if (activity.isDone && onUndo != null)
                IconButton(
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  color: cs.onSurface.withValues(alpha: 0.4),
                  tooltip: 'Undo',
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              if ((activity.isActive || activity.isPaused) &&
                  onComplete != null)
                IconButton(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      size: 22),
                  color: const Color(0xFF10B981),
                  tooltip: 'Complete',
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
