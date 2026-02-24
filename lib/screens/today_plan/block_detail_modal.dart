// =============================================================
// BlockDetailModal — bottom sheet showing full Block details
// Task checkboxes, segment timeline, start/pause/complete controls
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';

class BlockDetailModal extends StatelessWidget {
  final Block block;
  final DayPlan dayPlan;

  const BlockDetailModal({
    super.key,
    required this.block,
    required this.dayPlan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // Re-read latest block state from provider
    final app = context.watch<AppProvider>();
    final latestPlan = app.getDayPlan(dayPlan.date);
    final latestBlock = latestPlan?.blocks
            ?.firstWhere((b) => b.id == block.id, orElse: () => block) ??
        block;
    final tasks = latestBlock.tasks ?? [];
    final segments = latestBlock.segments ?? [];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            // ── Handle ────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Title ─────────────────────────────────────────────
            Text(latestBlock.title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              '${latestBlock.plannedStartTime} – ${latestBlock.plannedEndTime}  •  ${latestBlock.plannedDurationMinutes}m',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            if (latestBlock.description != null &&
                latestBlock.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(latestBlock.description!,
                  style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 20),

            // ── Action buttons ────────────────────────────────────
            _ActionBar(block: latestBlock, dayPlan: dayPlan),
            const SizedBox(height: 20),

            // ── Tasks ─────────────────────────────────────────────
            if (tasks.isNotEmpty) ...[
              Text('Tasks',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...tasks.asMap().entries.map((entry) {
                final i = entry.key;
                final task = entry.value;
                return _TaskTile(
                  task: task,
                  onToggle: () => _toggleTask(context, latestBlock, i),
                );
              }),
              const SizedBox(height: 16),
            ],

            // ── Segments ──────────────────────────────────────────
            if (segments.isNotEmpty) ...[
              Text('Timeline',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...segments.map((seg) => _SegmentTile(segment: seg)),
              const SizedBox(height: 16),
            ],

            // ── Actual notes ──────────────────────────────────────
            if (latestBlock.actualNotes != null &&
                latestBlock.actualNotes!.isNotEmpty) ...[
              Text('Notes',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(latestBlock.actualNotes!,
                    style: theme.textTheme.bodyMedium),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _toggleTask(BuildContext context, Block latestBlock, int taskIndex) {
    HapticsService.medium();
    final app = context.read<AppProvider>();
    final tasks = List<BlockTask>.from(latestBlock.tasks ?? []);
    if (taskIndex < 0 || taskIndex >= tasks.length) return;

    final task = tasks[taskIndex];
    tasks[taskIndex] = task.copyWith(completed: !task.completed);

    final updatedBlock = latestBlock.copyWith(tasks: tasks);
    _updateBlockInPlan(app, updatedBlock);
  }

  void _updateBlockInPlan(AppProvider app, Block updatedBlock) {
    final plan = app.getDayPlan(dayPlan.date);
    if (plan == null) return;
    final blocks = List<Block>.from(plan.blocks ?? []);
    final idx = blocks.indexWhere((b) => b.id == updatedBlock.id);
    if (idx >= 0) {
      blocks[idx] = updatedBlock;
      app.upsertDayPlan(plan.copyWith(blocks: blocks));
    }
  }
}

// ── Action bar (start / pause / complete) ───────────────────────
class _ActionBar extends StatelessWidget {
  final Block block;
  final DayPlan dayPlan;

  const _ActionBar({required this.block, required this.dayPlan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.read<AppProvider>();

    switch (block.status) {
      case BlockStatus.notStarted:
        return _ActionButton(
          label: 'Start Block',
          icon: Icons.play_arrow_rounded,
          color: cs.primary,
          onTap: () => _startBlock(app),
        );
      case BlockStatus.inProgress:
        return Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Pause',
                icon: Icons.pause_rounded,
                color: const Color(0xFFF59E0B),
                onTap: () => _pauseBlock(app),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Complete',
                icon: Icons.check_rounded,
                color: const Color(0xFF10B981),
                onTap: () {
                  HapticsService.heavy();
                  _completeBlock(app);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      case BlockStatus.paused:
        return Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Resume',
                icon: Icons.play_arrow_rounded,
                color: cs.primary,
                onTap: () => _resumeBlock(app),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Complete',
                icon: Icons.check_rounded,
                color: const Color(0xFF10B981),
                onTap: () {
                  HapticsService.heavy();
                  _completeBlock(app);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      case BlockStatus.done:
        return _ActionButton(
          label: 'Completed ✓',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF10B981).withValues(alpha: 0.5),
          onTap: null,
        );
      case BlockStatus.skipped:
        return _ActionButton(
          label: 'Skipped',
          icon: Icons.skip_next_rounded,
          color: cs.onSurface.withValues(alpha: 0.3),
          onTap: null,
        );
    }
  }

  void _updateBlock(AppProvider app, Block updatedBlock) {
    final plan = app.getDayPlan(dayPlan.date);
    if (plan == null) return;
    final blocks = List<Block>.from(plan.blocks ?? []);
    final idx = blocks.indexWhere((b) => b.id == updatedBlock.id);
    if (idx >= 0) {
      blocks[idx] = updatedBlock;
      app.upsertDayPlan(plan.copyWith(blocks: blocks));
    }
  }

  void _startBlock(AppProvider app) {
    final now = DateTime.now().toIso8601String();
    // Pause any currently active block first
    final plan = app.getDayPlan(dayPlan.date);
    if (plan?.blocks != null) {
      for (int i = 0; i < plan!.blocks!.length; i++) {
        if (plan.blocks![i].status == BlockStatus.inProgress &&
            plan.blocks![i].id != block.id) {
          final paused = plan.blocks![i].copyWith(status: BlockStatus.paused);
          _updateBlock(app, paused);
        }
      }
    }
    _updateBlock(
        app,
        block.copyWith(
          status: BlockStatus.inProgress,
          actualStartTime: block.actualStartTime ?? now,
        ));
  }

  void _pauseBlock(AppProvider app) {
    _updateBlock(app, block.copyWith(status: BlockStatus.paused));
  }

  void _resumeBlock(AppProvider app) {
    // Pause any other active block
    final plan = app.getDayPlan(dayPlan.date);
    if (plan?.blocks != null) {
      for (int i = 0; i < plan!.blocks!.length; i++) {
        if (plan.blocks![i].status == BlockStatus.inProgress &&
            plan.blocks![i].id != block.id) {
          final paused = plan.blocks![i].copyWith(status: BlockStatus.paused);
          _updateBlock(app, paused);
        }
      }
    }
    _updateBlock(app, block.copyWith(status: BlockStatus.inProgress));
  }

  void _completeBlock(AppProvider app) {
    final now = DateTime.now().toIso8601String();
    _updateBlock(
        app,
        block.copyWith(
          status: BlockStatus.done,
          actualEndTime: now,
          completionStatus: 'COMPLETED',
        ));
  }
}

// ── Styled action button ────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: onTap != null ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Task checkbox tile ──────────────────────────────────────────
class _TaskTile extends StatelessWidget {
  final BlockTask task;
  final VoidCallback onToggle;

  const _TaskTile({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              task.completed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: task.completed
                  ? const Color(0xFF10B981)
                  : cs.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                task.detail,
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration:
                      task.completed ? TextDecoration.lineThrough : null,
                  color: task.completed
                      ? cs.onSurface.withValues(alpha: 0.4)
                      : cs.onSurface,
                ),
              ),
            ),
            // Task type badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.type,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: cs.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segment tile ────────────────────────────────────────────────
class _SegmentTile extends StatelessWidget {
  final BlockSegment segment;

  const _SegmentTile({required this.segment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final endStr = segment.end ?? '...';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${segment.start} – $endStr',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
