// =============================================================
// BlockCard — card widget for a single Block in Today's Plan
// Shows title, time range, progress bar, status chip.
// Tap → BlockDetailModal, long press → context menu.
// Animations: scale bounce on tap, animated checkbox container,
//             TweenAnimationBuilder for strike-through.
// =============================================================

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'block_detail_modal.dart';

class BlockCard extends StatefulWidget {
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

  @override
  State<BlockCard> createState() => _BlockCardState();
}

class _BlockCardState extends State<BlockCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.96), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _scaleController.forward(from: 0);
  }

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
    final block = widget.block;
    final tasks = block.tasks ?? [];
    final tasksDone = tasks.where((t) => t.completed).length;
    final tasksTotal = tasks.length;
    final progress = tasksTotal > 0 ? tasksDone / tasksTotal : 0.0;
    final statusColor = _statusColor(block.status, cs);
    final isDone = block.status == BlockStatus.done;
    final isSkipped = block.status == BlockStatus.skipped;

    return GestureDetector(
      onTap: () => _openDetail(context),
      onTapDown: _onTapDown,
      onLongPress: () {
        HapticsService.heavy();
        _showContextMenu(context);
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedOpacity(
          opacity: isSkipped ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDone
                  ? cs.primary.withValues(alpha: 0.04)
                  : cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: block.status == BlockStatus.inProgress
                    ? statusColor.withValues(alpha: 0.5)
                    : isDone
                        ? statusColor.withValues(alpha: 0.2)
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
                    // ── Animated checkbox icon ────────────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDone
                            ? statusColor.withValues(alpha: 0.2)
                            : statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isDone
                            ? Icon(Icons.check_circle_rounded,
                                key: const ValueKey('done'),
                                size: 18, color: statusColor)
                            : Icon(_typeIcon(block.type),
                                key: const ValueKey('type'),
                                size: 18, color: statusColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Animated strike-through title ──────────
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: isDone ? 1.0 : 0.0,
                            ),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Text(
                                block.title,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: value > 0.5
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: cs.onSurface.withValues(
                                      alpha: 1.0 - (value * 0.4)),
                                ),
                              );
                            },
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
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
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            builder: (context, val, _) {
                              return LinearProgressIndicator(
                                value: val,
                                minHeight: 4,
                                backgroundColor:
                                    cs.onSurface.withValues(alpha: 0.06),
                                valueColor:
                                    AlwaysStoppedAnimation(statusColor),
                              );
                            },
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
      builder: (_) =>
          BlockDetailModal(block: widget.block, dayPlan: widget.dayPlan),
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
            if (widget.block.status == BlockStatus.notStarted) ...[
              ListTile(
                leading: Icon(Icons.play_arrow_rounded, color: cs.primary),
                title: const Text('Start block'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onStart?.call();
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.skip_next_rounded,
                  color: cs.onSurface.withValues(alpha: 0.6)),
              title: const Text('Skip block'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onSkip?.call();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
