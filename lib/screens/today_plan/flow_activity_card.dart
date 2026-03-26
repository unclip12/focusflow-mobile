// =============================================================
// FlowActivityCard — visual card for each activity in the flow
// Premium Redesign with glassmorphic background and accent border
// =============================================================


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        durationStr = '${dur.inHours}h ${dur.inMinutes.remainder(60)}m';
      } else if (dur.inMinutes > 0) {
        durationStr = '${dur.inMinutes}m ${dur.inSeconds.remainder(60)}s';
      } else {
        durationStr = '${dur.inSeconds}s';
      }
    }

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: activity.isActive
                    ? [
                        const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.12 : 0.08),
                        const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.06 : 0.03),
                      ]
                    : activity.isDone
                        ? [
                            const Color(0xFF10B981).withValues(alpha: isDark ? 0.10 : 0.06),
                            const Color(0xFF10B981).withValues(alpha: isDark ? 0.04 : 0.02),
                          ]
                        : isDark
                            ? [
                                Colors.white.withValues(alpha: 0.05),
                                Colors.white.withValues(alpha: 0.02),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.50),
                                Colors.white.withValues(alpha: 0.30),
                              ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: activity.isActive
                  ? Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                      width: 1.5,
                    )
                  : Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Left accent border
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                  ),
                  // Card content
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
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
                                            color: cs.onSurface
                                                .withValues(alpha: 0.4),
                                          ),
                                        )
                                      : Icon(statusIcon,
                                          size: 20, color: statusColor),
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
                                                  ? cs.onSurface
                                                      .withValues(alpha: 0.5)
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
                                        child: Row(
                                          children: [
                                            Icon(Icons.link_rounded,
                                                size: 11,
                                                color: cs.primary
                                                    .withValues(alpha: 0.5)),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${activity.linkedTaskIds.length} task${activity.linkedTaskIds.length == 1 ? '' : 's'} linked',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: cs.primary
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (durationStr != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Row(
                                          children: [
                                            Icon(Icons.timer_outlined,
                                                size: 12,
                                                color: const Color(0xFF10B981)
                                                    .withValues(alpha: 0.7)),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                '${_timeRange(activity)}$durationStr',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      const Color(0xFF10B981)
                                                          .withValues(
                                                              alpha: 0.8),
                                                ),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    // Notes
                                    if (activity.notes != null &&
                                        activity.notes!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Row(
                                          children: [
                                            Icon(Icons.sticky_note_2_outlined,
                                                size: 12,
                                                color: cs.onSurface
                                                    .withValues(alpha: 0.3)),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                activity.notes!,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: cs.onSurface
                                                      .withValues(alpha: 0.5),
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (statusLabel.isNotEmpty &&
                                        !activity.isNotStarted)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                statusColor
                                                    .withValues(alpha: 0.15),
                                                statusColor
                                                    .withValues(alpha: 0.08),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(6),
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
                                  icon: const Icon(Icons.undo_rounded,
                                      size: 18),
                                  color:
                                      cs.onSurface.withValues(alpha: 0.4),
                                  tooltip: 'Undo',
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                ),
                              if ((activity.isActive || activity.isPaused) &&
                                  onComplete != null)
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    onPressed: onComplete,
                                    icon: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 22),
                                    color: const Color(0xFF10B981),
                                    tooltip: 'Complete',
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Format "2:30 PM – 3:45 PM • " from startedAt/completedAt
  static String _timeRange(FlowActivity a) {
    if (a.startedAt == null) return '';
    try {
      final start = DateTime.parse(a.startedAt!);
      final fmt = DateFormat('h:mm a');
      final startStr = fmt.format(start);
      if (a.completedAt != null) {
        final end = DateTime.parse(a.completedAt!);
        return '$startStr – ${fmt.format(end)} • ';
      }
      return '$startStr – ? • ';
    } catch (_) {
      return '';
    }
  }
}
