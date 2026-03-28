// =============================================================
// TimelineView — scrollable timeline widget for day blocks
// Shows blocks with time column, colored-border cards, free gaps,
// drag-reorder for non-event tasks, and split task badges.
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'free_gap_panel.dart';

class TimelineView extends StatefulWidget {
  final List<Block> blocks;
  final String dateKey;

  const TimelineView({
    super.key,
    required this.blocks,
    required this.dateKey,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  bool _isLockedBlock(Block block) =>
      block.isEvent || block.id.startsWith('prayer_');

  // ── Category Colors ─────────────────────────────────────────
  static Color _categoryColor(Block block) {
    if (block.isEvent || block.id.startsWith('prayer_')) {
      return const Color(0xFFEF4444); // red — event
    }
    switch (block.type) {
      case BlockType.studySession:
      case BlockType.revisionFa:
      case BlockType.fmgeRevision:
        return const Color(0xFF3B82F6); // blue — study
      case BlockType.video:
        return const Color(0xFFF59E0B); // orange — revision/video
      case BlockType.breakBlock:
        return const Color(0xFF94A3B8); // grey — break
      case BlockType.other:
        if (block.title.contains('🕌') || block.id.startsWith('prayer_')) {
          return const Color(0xFF0D9488); // teal — prayer
        }
        return const Color(0xFF8B5CF6); // purple — general
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  static String _categoryLabel(Block block) {
    if (block.isEvent || block.id.startsWith('prayer_')) return 'Event';
    switch (block.type) {
      case BlockType.studySession:
      case BlockType.revisionFa:
      case BlockType.fmgeRevision:
        return 'Study';
      case BlockType.video:
        return 'Revision';
      case BlockType.breakBlock:
        return 'Break';
      default:
        if (block.title.contains('🕌')) return 'Prayer';
        return 'General';
    }
  }

  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  TimeOfDay _timeOfDayFromMinutes(int totalMinutes) => TimeOfDay(
        hour: totalMinutes ~/ 60,
        minute: totalMinutes % 60,
      );

  String _formatTimeString12h(String hhmm) {
    final minutes = _toMinutes(hhmm);
    return MaterialLocalizations.of(context).formatTimeOfDay(
      _timeOfDayFromMinutes(minutes),
      alwaysUse24HourFormat: false,
    );
  }

  String _formatDurationLabel(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '${h}h ${m}min' : '${h}h';
    }
    return '$minutes min';
  }

  int _blockDurationMinutes(Block block) {
    if (block.plannedDurationMinutes > 0) return block.plannedDurationMinutes;

    final duration =
        _toMinutes(block.plannedEndTime) - _toMinutes(block.plannedStartTime);
    return duration > 0 ? duration : 0;
  }

  String _lockedCategoryLabel(Block block) =>
      block.id.startsWith('prayer_') ? 'Prayer' : 'Event';

  String _formatMinutesOfDay(int totalMinutes) => _formatTimeOfDay(
        _timeOfDayFromMinutes(totalMinutes),
      );

  int _countMovableBlocksBefore(List<_TimelineItem> items, int endExclusive) {
    var count = 0;

    for (var i = 0; i < endExclusive && i < items.length; i++) {
      final item = items[i];
      if (!item.isGap && !_isLockedBlock(item.block!)) {
        count++;
      }
    }

    return count;
  }

  /// Build timeline items including gaps between blocks.
  List<_TimelineItem> _buildTimelineItems() {
    final items = <_TimelineItem>[];
    final sorted = List<Block>.from(widget.blocks)
      ..sort((a, b) =>
          _toMinutes(a.plannedStartTime).compareTo(_toMinutes(b.plannedStartTime)));

    for (int i = 0; i < sorted.length; i++) {
      final block = sorted[i];

      // Check for gap before this block
      if (i > 0) {
        final prevEnd = _toMinutes(sorted[i - 1].plannedEndTime);
        final curStart = _toMinutes(block.plannedStartTime);
        if (curStart > prevEnd && (curStart - prevEnd) >= 5) {
          items.add(_TimelineItem.gap(
            gapStartMinutes: prevEnd,
            gapEndMinutes: curStart,
          ));
        }
      }

      items.add(_TimelineItem.block(block));
    }

    return items;
  }

  void _onGapTap(_TimelineItem gap) {
    final startH = gap.gapStartMinutes! ~/ 60;
    final startM = gap.gapStartMinutes! % 60;
    final endH = gap.gapEndMinutes! ~/ 60;
    final endM = gap.gapEndMinutes! % 60;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FreeGapPanel(
        gapStart: TimeOfDay(hour: startH, minute: startM),
        gapEnd: TimeOfDay(hour: endH, minute: endM),
        dateKey: widget.dateKey,
      ),
    );
  }

  void _onBlockLongPress(Block block) {
    if (_isLockedBlock(block)) return;
    HapticsService.medium();
    _showEditSheet(block);
  }

  void _onBlockTap(Block block) {
    if (_isLockedBlock(block)) {
      _showLockedDetailSheet(block);
      return;
    }
    _showEditSheet(block);
  }

  void _showLockedDetailSheet(Block block) {
    final cs = Theme.of(context).colorScheme;
    final color = _categoryColor(block);
    final duration =
        _toMinutes(block.plannedEndTime) - _toMinutes(block.plannedStartTime);
    final note = block.id.startsWith('prayer_')
        ? 'Prayer time - auto-inserted'
        : 'Fixed Event - scheduler won\'t move this';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).padding.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              block.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(
                    _lockedCategoryLabel(block),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _LockedDetailRow(
              icon: Icons.access_time_rounded,
              text:
                  '${_formatTimeString12h(block.plannedStartTime)} - ${_formatTimeString12h(block.plannedEndTime)}',
            ),
            const SizedBox(height: 12),
            _LockedDetailRow(
              icon: Icons.timer_outlined,
              text: _formatDurationLabel(
                duration > 0 ? duration : block.plannedDurationMinutes,
              ),
            ),
            const SizedBox(height: 12),
            _LockedDetailRow(
              icon: Icons.push_pin_outlined,
              text: note,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(Block block) {
    final cs = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(text: block.title);
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    bool isEvent = block.isEvent;

    final startParts = block.plannedStartTime.split(':');
    if (startParts.length == 2) {
      startTime = TimeOfDay(
        hour: int.tryParse(startParts[0]) ?? 0,
        minute: int.tryParse(startParts[1]) ?? 0,
      );
    }
    final endParts = block.plannedEndTime.split(':');
    if (endParts.length == 2) {
      endTime = TimeOfDay(
        hour: int.tryParse(endParts[0]) ?? 0,
        minute: int.tryParse(endParts[1]) ?? 0,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).padding.bottom +
                  20,
            ),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Edit Block',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    )),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Block name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: startTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setSheetState(() => startTime = picked);
                          }
                        },
                        icon:
                            const Icon(Icons.access_time_rounded, size: 16),
                        label: Text(startTime?.format(ctx) ?? 'Start'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: endTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setSheetState(() => endTime = picked);
                          }
                        },
                        icon:
                            const Icon(Icons.access_time_rounded, size: 16),
                        label: Text(endTime?.format(ctx) ?? 'End'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Fixed Event',
                      style: TextStyle(fontSize: 14)),
                  subtitle: isEvent
                      ? Text(
                          'Event times are fixed and won\'t be moved by the scheduler',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.error.withValues(alpha: 0.7),
                          ),
                        )
                      : null,
                  value: isEvent,
                  onChanged: (v) => setSheetState(() => isEvent = v),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteBlock(block);
                        },
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 16, color: cs.error),
                        label: Text('Delete',
                            style: TextStyle(color: cs.error)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: cs.error.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _saveBlockEdit(
                            block,
                            nameCtrl.text.trim(),
                            startTime,
                            endTime,
                            isEvent,
                          );
                        },
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _saveBlockEdit(
    Block block,
    String newTitle,
    TimeOfDay? newStart,
    TimeOfDay? newEnd,
    bool newIsEvent,
  ) {
    final app = context.read<AppProvider>();
    final plan = app.getDayPlan(widget.dateKey);
    if (plan == null) return;

    final blocks = List<Block>.from(plan.blocks ?? []);
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx < 0) return;

    final startStr = newStart != null
        ? _formatTimeOfDay(newStart)
        : block.plannedStartTime;
    final endStr =
        newEnd != null ? _formatTimeOfDay(newEnd) : block.plannedEndTime;
    final durMinutes = _toMinutes(endStr) - _toMinutes(startStr);

    blocks[idx] = blocks[idx].copyWith(
      title: newTitle.isNotEmpty ? newTitle : block.title,
      plannedStartTime: startStr,
      plannedEndTime: endStr,
      plannedDurationMinutes: durMinutes > 0 ? durMinutes : block.plannedDurationMinutes,
      remainingDurationMinutes: durMinutes > 0 ? durMinutes : block.remainingDurationMinutes,
      isEvent: newIsEvent,
    );

    app.upsertDayPlan(plan.copyWith(blocks: blocks));
    // After manual time edit, reschedule from edited task's new start
    app.rescheduleFrom(widget.dateKey, DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      newStart?.hour ?? 0,
      newStart?.minute ?? 0,
    ));
  }

  void _deleteBlock(Block block) {
    final app = context.read<AppProvider>();
    app.removeBlockFromDayPlan(block.id, widget.dateKey);
  }

  void _onReorder(int oldIndex, int newIndex, List<_TimelineItem> items) {
    if (oldIndex < 0 || oldIndex >= items.length) return;

    final movedItem = items[oldIndex];
    if (movedItem.isGap || _isLockedBlock(movedItem.block!)) return;

    final app = context.read<AppProvider>();
    final plan = app.getDayPlan(widget.dateKey);
    final planBlocks = plan?.blocks;
    if (plan == null || planBlocks == null) return;

    final movableBlocks = items
        .where((item) => !item.isGap && !_isLockedBlock(item.block!))
        .map((item) => item.block!)
        .toList();
    if (movableBlocks.length < 2) return;

    final oldMovableIndex = _countMovableBlocksBefore(items, oldIndex);
    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final remainingItems = List<_TimelineItem>.from(items)..removeAt(oldIndex);
    final boundedNewIndex = adjustedNewIndex < 0
        ? 0
        : adjustedNewIndex > remainingItems.length
            ? remainingItems.length
            : adjustedNewIndex;
    final newMovableIndex =
        _countMovableBlocksBefore(remainingItems, boundedNewIndex);

    final reorderedMovable = List<Block>.from(movableBlocks);
    final movedBlock = reorderedMovable.removeAt(oldMovableIndex);
    final insertIndex = newMovableIndex < 0
        ? 0
        : newMovableIndex > reorderedMovable.length
            ? reorderedMovable.length
            : newMovableIndex;

    if (oldMovableIndex == insertIndex) return;

    reorderedMovable.insert(insertIndex, movedBlock);

    final earliestStart = movableBlocks
        .map((block) => _toMinutes(block.plannedStartTime))
        .reduce((a, b) => a < b ? a : b);

    final updatedMovableById = <String, Block>{};
    var currentStart = earliestStart;
    for (final block in reorderedMovable) {
      final duration = _blockDurationMinutes(block);
      final nextEnd = currentStart + duration;

      updatedMovableById[block.id] = block.copyWith(
        plannedStartTime: _formatMinutesOfDay(currentStart),
        plannedEndTime: _formatMinutesOfDay(nextEnd),
      );

      currentStart = nextEnd;
    }

    final updatedBlocks = planBlocks
      .map((block) => updatedMovableById[block.id] ?? block)
      .toList()
      ..sort(
        (a, b) =>
            _toMinutes(a.plannedStartTime).compareTo(_toMinutes(b.plannedStartTime)),
      );

    final reindexedBlocks = <Block>[
      for (var i = 0; i < updatedBlocks.length; i++)
        updatedBlocks[i].copyWith(index: i),
    ];

    app.upsertDayPlan(plan.copyWith(blocks: reindexedBlocks));
    HapticsService.light();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _buildTimelineItems();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timeline_rounded,
                size: 48, color: cs.primary.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text(
              'No blocks scheduled',
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add tasks or start your day to build the timeline',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: EdgeInsets.fromLTRB(
        0,
        8,
        0,
        MediaQuery.of(context).padding.bottom + 72 + 24,
      ),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex, items),
      itemBuilder: (context, index) {
        final item = items[index];

        if (item.isGap) {
          return KeyedSubtree(
            key: ValueKey('gap_${item.gapStartMinutes}_${item.gapEndMinutes}'),
            child: _GapSlot(
              startMinutes: item.gapStartMinutes!,
              endMinutes: item.gapEndMinutes!,
              onTap: () => _onGapTap(item),
              isDark: isDark,
            ),
          );
        }

        final block = item.block!;
        final isLocked = _isLockedBlock(block);

        return KeyedSubtree(
          key: ValueKey(block.id),
          child: _BlockCard(
            block: block,
            isDark: isDark,
            leading: isLocked
                ? const SizedBox(width: 22)
                : ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 18,
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
            onTap: () => _onBlockTap(block),
            onLongPress: () => _onBlockLongPress(block),
          ),
        );
      },
    );
  }
}

// ── Timeline Item ─────────────────────────────────────────────────
class _TimelineItem {
  final Block? block;
  final int? gapStartMinutes;
  final int? gapEndMinutes;
  final bool isGap;

  const _TimelineItem._({
    this.block,
    this.gapStartMinutes,
    this.gapEndMinutes,
    required this.isGap,
  });

  factory _TimelineItem.block(Block b) =>
      _TimelineItem._(block: b, isGap: false);

  factory _TimelineItem.gap({
    required int gapStartMinutes,
    required int gapEndMinutes,
  }) =>
      _TimelineItem._(
        gapStartMinutes: gapStartMinutes,
        gapEndMinutes: gapEndMinutes,
        isGap: true,
      );
}

// ── Block Card ────────────────────────────────────────────────────
class _BlockCard extends StatelessWidget {
  final Block block;
  final bool isDark;
  final Widget? leading;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _BlockCard({
    required this.block,
    required this.isDark,
    this.leading,
    this.onTap,
    this.onLongPress,
  });

  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '${h}h ${m}min' : '${h}h';
    }
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _TimelineViewState._categoryColor(block);
    final label = _TimelineViewState._categoryLabel(block);
    final duration = _toMinutes(block.plannedEndTime) - _toMinutes(block.plannedStartTime);
    final isLocked = block.isEvent || block.id.startsWith('prayer_');
    final isDone = block.status == BlockStatus.done;
    final isSkipped = block.status == BlockStatus.skipped;
    final isSplit = block.splitTotalParts != null && block.splitTotalParts! > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: 22,
                child: leading,
              ),
            ),
            const SizedBox(width: 6),
          ],
          // ── Time Column ──
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 10),
                Text(
                  block.plannedStartTime,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── Dot + Line ──
          Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF10B981)
                      : isSkipped
                          ? cs.onSurface.withValues(alpha: 0.2)
                          : color,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 50,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // ── Card ──
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border(
                    left: BorderSide(color: color, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isLocked)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.lock_rounded,
                                size: 13, color: color),
                          ),
                        Expanded(
                          child: Text(
                            block.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDone
                                  ? cs.onSurface.withValues(alpha: 0.4)
                                  : cs.onSurface,
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${block.plannedStartTime} – ${block.plannedEndTime}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(duration > 0 ? duration : block.plannedDurationMinutes),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    if (isSplit) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Part ${block.splitPartIndex} of ${block.splitTotalParts}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                    if (isDone)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 14, color: const Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isSkipped)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.skip_next_rounded,
                                size: 14,
                                color: cs.onSurface.withValues(alpha: 0.4)),
                            const SizedBox(width: 4),
                            Text(
                              'Skipped',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gap Slot ──────────────────────────────────────────────────────
class _LockedDetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _LockedDetailRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 18,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _GapSlot extends StatelessWidget {
  final int startMinutes;
  final int endMinutes;
  final VoidCallback onTap;
  final bool isDark;

  const _GapSlot({
    required this.startMinutes,
    required this.endMinutes,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final duration = endMinutes - startMinutes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column placeholder
          const SizedBox(width: 52),
          const SizedBox(width: 8),
          // Dot column placeholder
          const SizedBox(width: 10),
          const SizedBox(width: 10),
          // Gap card
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : const Color(0xFFF0F0FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE0E0F0),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'FREE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: cs.primary.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$duration min available',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 18,
                      color: cs.primary.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
