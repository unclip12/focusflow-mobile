// =============================================================
// BlockCard — card widget for a single Block in Today's Plan
// Shows title, time range, progress bar, status chip.
// Tap → BlockDetailModal, long press → context menu.
// =============================================================

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'block_detail_modal.dart';

class BlockCard extends StatelessWidget {
  final Block block;
  final DayPlan dayPlan;
  final VoidCallback? onSkip;
  final VoidCallback? onStart;

  const BlockCard({
    super.key,
    required this.block,
    required this.dayPlan,
    this.onSkip,
    this.onStart,
  });

  Color _statusColor(BlockStatus status, ColorScheme cs) {
    switch (status) {
      case BlockStatus.notStarted: return cs.onSurface.withValues(alpha: 0.4);
      case BlockStatus.inProgress: return const Color(0xFF3B82F6);
      case BlockStatus.paused:     return const Color(0xFFF59E0B);
      case BlockStatus.done:       return const Color(0xFF10B981);
      case BlockStatus.skipped:    return cs.onSurface.withValues(alpha: 0.25);
    }
  }

  String _statusLabel(BlockStatus status) {
    switch (status) {
      case BlockStatus.notStarted: return 'Pending';
      case BlockStatus.inProgress: return 'Active';
      case BlockStatus.paused:     return 'Paused';
      case BlockStatus.done:       return 'Done';
      case BlockStatus.skipped:    return 'Skipped';
    }
  }

  IconData _typeIcon(BlockType type) {
    switch (type) {
      case BlockType.video:        return Icons.play_circle_rounded;
      case BlockType.revisionFa:   return Icons.menu_book_rounded;
      case BlockType.anki:         return Icons.style_rounded;
      case BlockType.qbank:        return Icons.quiz_rounded;
      case BlockType.breakBlock:   return Icons.coffee_rounded;
      case BlockType.fmgeRevision: return Icons.medical_services_rounded;
      case BlockType.mixed:        return Icons.dashboard_rounded;
      case BlockType.other:        return Icons.task_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tasks = block.tasks ?? [];
    final tasksDone = tasks.where((t) => t.completed).length;
    final tasksTotal = tasks.length;
    final progress = tasksTotal > 0 ? tasksDone / tasksTotal : 0.0;
    final statusColor = _statusColor(block.status, cs);
    final isDone = block.status == BlockStatus.done;
    final isSkipped = block.status == BlockStatus.skipped;

    return GestureDetector(
      onTap: () => _openDetail(context),
      onLongPress: () {
        HapticsService.heavy();
        _showContextMenu(context);
      },
      child: AnimatedOpacity(
        opacity: isSkipped ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: block.status == BlockStatus.inProgress
                  ? statusColor.withValues(alpha: 0.5)
                  : cs.onSurface.withValues(alpha: 0.06),
              width: block.status == BlockStatus.inProgress ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_typeIcon(block.type),
                        size: 18, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          block.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${block.plannedStartTime} – ${block.plannedEndTime}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.45),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(block.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Progress bar ────────────────────────────────────
              if (tasksTotal > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor:
                              cs.onSurface.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation(statusColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$tasksDone/$tasksTotal',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => BlockDetailModal(block: block, dayPlan: dayPlan),
    );
  }

  void _showContextMenu(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (block.status == BlockStatus.notStarted) ...[
              ListTile(
                leading: Icon(Icons.play_arrow_rounded, color: cs.primary),
                title: const Text('Start block'),
                onTap: () {
                  Navigator.pop(ctx);
                  onStart?.call();
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.skip_next_rounded,
                  color: cs.onSurface.withValues(alpha: 0.6)),
              title: const Text('Skip block'),
              onTap: () {
                Navigator.pop(ctx);
                onSkip?.call();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
