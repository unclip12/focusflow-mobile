// =============================================================
// TimelineView — scrollable timeline with:
//   • 12-hour AM/PM time labels
//   • Proportional block heights (1 min = 2 px)
//   • Hourly ticks in free gaps
//   • TAP any block ? edit sheet (or detail sheet for locked blocks)
//   • LONG-PRESS non-locked block ? drag to reorder ? start times cascade
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'block_editor_sheet.dart';
import 'free_gap_panel.dart';
import 'study_session_screen.dart';

// -- Helpers --------------------------------------------------
String _to12h(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return hhmm;
  final h24 = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  final suffix = h24 < 12 ? 'AM' : 'PM';
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $suffix';
}

String _minutesToHHMM(int minutes) {
  final h = (minutes ~/ 60).clamp(0, 23);
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

String _to12hShort(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return hhmm;
  final h24 = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  return '$h12:${m.toString().padLeft(2, '0')}';
}

String _formatGapDurationCompact(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h > 0 && m > 0) return '${h}h ${m}m';
  if (h > 0) return '${h}h';
  return '${m}m';
}

const double _kTimelineHandleWidth = 22;
const double _kTimelineHandleGap = 6;
const double _kTimelineLeadingWidth =
    _kTimelineHandleWidth + _kTimelineHandleGap;
const double _kTimelineTimeWidth = 44;
const double _kTimelineTimeToPillGap = 10;
const double _kTimelinePillWidth = 56;
const double _kTimelineContentGap = 14;
const double _kTimelineStatusSize = 20;
const Color _kTimelineCardBackground = Color(0xFF1C1C1E);
const Color _kTimelineAccent = Color(0xFFE8837A);
const Color _kTimelineMuted = Color(0xFF8E8E93);
const Color _kTimelineDivider = Color(0xFF3A3A3C);
const Color _kTimelineCompletedPill = Color(0xFF3A3A3C);
const Color _kTimelineComplete = Color(0xFF10B981);
const Color _kTimelineGapAccent = _kTimelineAccent;

Color _colorFromHex(String? value, {Color fallback = _kTimelineAccent}) {
  if (value == null || value.trim().isEmpty) return fallback;
  final cleaned = value.trim().replaceFirst('#', '');
  final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  final parsed = int.tryParse(normalized, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

Color _baseBlockColor(Block block) => _colorFromHex(block.colorHex);

String _categoryLabel(Block block) {
  if (block.id.startsWith('prayer_')) return 'Prayer';
  if (block.isEvent) return 'Event';
  switch (block.type) {
    case BlockType.studySession:
    case BlockType.revisionFa:
    case BlockType.fmgeRevision:
      return 'Study';
    case BlockType.video:
      return 'Video';
    case BlockType.qbank:
      return 'Qbank';
    case BlockType.anki:
      return 'Anki';
    case BlockType.breakBlock:
      return 'Break';
    default:
      if (block.title.contains('??')) return 'Prayer';
      return 'General';
  }
}

// -- Widget ----------------------------------------------------
class TimelineView extends StatefulWidget {
  final List<Block> blocks;
  final String dateKey;
  final VoidCallback? onAddTask;

  const TimelineView({
    super.key,
    required this.blocks,
    required this.dateKey,
    this.onAddTask,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  bool _isLockedBlock(Block block) =>
      block.isEvent || block.id.startsWith('prayer_');

  bool _opensStudySession(Block block) {
    final title = block.title.toLowerCase();
    return title.contains('study') ||
        title.contains('revision') ||
        title.contains('anki') ||
        title.contains('qbank') ||
        title.contains('lecture');
  }

  // -- Category Colors -----------------------------------------
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
        if (block.title.contains('??') || block.id.startsWith('prayer_')) {
          return const Color(0xFF0D9488); // teal — prayer
        }
        return const Color(0xFF8B5CF6); // purple — general
      default:
        return const Color(0xFF8B5CF6);
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

  String _formatMinutesOfDay(int totalMinutes) => _minutesToHHMM(totalMinutes);

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

  // Build list of timeline items (blocks + gaps)
  List<_TimelineItem> _buildTimelineItems() {
    final sortedBlocks = List<Block>.from(widget.blocks)
      ..sort(
        (a, b) => _toMinutes(a.plannedStartTime)
            .compareTo(_toMinutes(b.plannedStartTime)),
      );
    final items = <_TimelineItem>[];
    for (int i = 0; i < sortedBlocks.length; i++) {
      final block = sortedBlocks[i];
      if (i > 0) {
        final prevEnd = _toMinutes(sortedBlocks[i - 1].plannedEndTime);
        final curStart = _toMinutes(block.plannedStartTime);
        if (curStart > prevEnd && (curStart - prevEnd) >= 5) {
          items.add(_TimelineItem.gap(
              gapStartMinutes: prevEnd, gapEndMinutes: curStart));
        }
      }
      items.add(_TimelineItem.block(block));
    }
    return items;
  }

  // -- Gap tap ----------------------------------------------
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
    if (_opensStudySession(block)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudySessionScreen(block: block),
        ),
      );
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlockEditorSheet(
        block: block,
        onSave: (update) => _saveBlockEdit(block, update),
        onDelete: () {
          Navigator.of(context).pop();
          _deleteBlock(block);
        },
      ),
    );
  }

  List<Block> _reindexBlocks(List<Block> blocks) {
    return <Block>[
      for (var i = 0; i < blocks.length; i++) blocks[i].copyWith(index: i),
    ];
  }

  DayPlan _emptyPlanForDate(String dateKey, List<Block> blocks) {
    return DayPlan(
      date: dateKey,
      faPages: const [],
      faPagesCount: 0,
      videos: const [],
      notesFromUser: '',
      notesFromAI: '',
      attachments: const [],
      breaks: const [],
      blocks: blocks,
      totalStudyMinutesPlanned: 0,
      totalBreakMinutes: 0,
    );
  }

  DateTime _anchorForStartTime(String hhmm) {
    final minutes = _toMinutes(hhmm);
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      minutes ~/ 60,
      minutes % 60,
    );
  }

  Future<void> _saveBlockEdit(Block block, BlockEditorUpdate update) async {
    final app = context.read<AppProvider>();
    final sourcePlan = app.getDayPlan(widget.dateKey);
    if (sourcePlan == null) return;
    final sourceBlocks = List<Block>.from(sourcePlan.blocks ?? []);
    final sourceIndex = sourceBlocks.indexWhere((b) => b.id == block.id);
    if (sourceIndex < 0) return;

    final updatedBlock = sourceBlocks[sourceIndex].copyWith(
      date: update.dateKey,
      title: update.title.isNotEmpty ? update.title : block.title,
      description: update.description,
      plannedStartTime: update.plannedStartTime,
      plannedEndTime: update.plannedEndTime,
      plannedDurationMinutes: update.plannedDurationMinutes,
      remainingDurationMinutes: update.plannedDurationMinutes > 0
          ? update.plannedDurationMinutes
          : block.remainingDurationMinutes,
      isEvent: update.isEvent,
      type: update.type,
    );

    if (update.dateKey == widget.dateKey) {
      sourceBlocks[sourceIndex] = updatedBlock;
      await app.upsertDayPlan(
        sourcePlan.copyWith(blocks: _reindexBlocks(sourceBlocks)),
      );
      await app.rescheduleFrom(
        widget.dateKey,
        _anchorForStartTime(update.plannedStartTime),
      );
      return;
    }

    sourceBlocks.removeAt(sourceIndex);
    final updatedSourceBlocks = _reindexBlocks(sourceBlocks);
    await app.upsertDayPlan(sourcePlan.copyWith(blocks: updatedSourceBlocks));
    await app.syncFlowActivitiesFromDayPlan(widget.dateKey);

    final targetPlan = app.getDayPlan(update.dateKey);
    final targetBlocks =
        List<Block>.from(targetPlan?.blocks ?? const <Block>[]);
    targetBlocks.add(updatedBlock.copyWith(
        index: targetBlocks.length, date: update.dateKey));
    final updatedTargetBlocks = _reindexBlocks(targetBlocks);
    await app.upsertDayPlan(
      targetPlan?.copyWith(blocks: updatedTargetBlocks) ??
          _emptyPlanForDate(update.dateKey, updatedTargetBlocks),
    );
    await app.rescheduleFrom(
      update.dateKey,
      _anchorForStartTime(update.plannedStartTime),
    );
  }

  void _deleteBlock(Block block) {
    context
        .read<AppProvider>()
        .removeBlockFromDayPlan(block.id, widget.dateKey);
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
        (a, b) => _toMinutes(a.plannedStartTime)
            .compareTo(_toMinutes(b.plannedStartTime)),
      );

    final reindexedBlocks = <Block>[
      for (var i = 0; i < updatedBlocks.length; i++)
        updatedBlocks[i].copyWith(index: i),
    ];

    app.upsertDayPlan(plan.copyWith(blocks: reindexedBlocks));
    HapticsService.light();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _buildTimelineItems();
    final bottomPadding = MediaQuery.of(context).padding.bottom + 96;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: _kTimelineCardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: _kTimelineDivider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timeline_rounded,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.24),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No blocks scheduled',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add tasks or start your day to build the timeline',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: EdgeInsets.fromLTRB(0, 8, 0, bottomPadding),
                    itemCount: items.length,
                    onReorder: (oldIndex, newIndex) =>
                        _onReorder(oldIndex, newIndex, items),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (item.isGap) {
                        return KeyedSubtree(
                          key: ValueKey(
                            'gap_${item.gapStartMinutes}_${item.gapEndMinutes}',
                          ),
                          child: _GapSlot(
                            startMinutes: item.gapStartMinutes!,
                            endMinutes: item.gapEndMinutes!,
                            onTap: () => _onGapTap(item),
                            onAddTask: widget.onAddTask,
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
                              : const SizedBox(width: 22),
                          onTap: () => _onBlockTap(block),
                          onLongPress: () => _onBlockLongPress(block),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// -- Timeline Item --------------------------------------------------
class _TimelineItem {
  final Block? block;
  final int? gapStartMinutes;
  final int? gapEndMinutes;
  final bool isGap;

  const _TimelineItem._(
      {this.block,
      this.gapStartMinutes,
      this.gapEndMinutes,
      required this.isGap});
  factory _TimelineItem.block(Block b) =>
      _TimelineItem._(block: b, isGap: false);
  factory _TimelineItem.gap(
          {required int gapStartMinutes, required int gapEndMinutes}) =>
      _TimelineItem._(
          gapStartMinutes: gapStartMinutes,
          gapEndMinutes: gapEndMinutes,
          isGap: true);
}

// -- Block Card ----------------------------------------------------
/*
class _BlockCard extends StatelessWidget {
  final Block block;
  final bool isDark;
  final Widget? leading;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

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

  Color _statusRingColor(ColorScheme cs, Color accent) {
    switch (block.status) {
      case BlockStatus.done:
        return const Color(0xFF10B981);
      case BlockStatus.skipped:
        return cs.onSurface.withValues(alpha: 0.28);
      case BlockStatus.paused:
        return const Color(0xFFF59E0B);
      case BlockStatus.inProgress:
      case BlockStatus.notStarted:
        return accent;
    }
  }

  IconData _iconForBlock() {
    final lowerTitle = block.title.toLowerCase();

    if (lowerTitle.contains('wake') ||
        lowerTitle.contains('rise') ||
        lowerTitle.contains('morning')) {
      return Icons.alarm_rounded;
    }
    if (lowerTitle.contains('wind down') ||
        lowerTitle.contains('sleep') ||
        lowerTitle.contains('night')) {
      return Icons.dark_mode_rounded;
    }
    if (block.id.startsWith('prayer_')) return Icons.mosque_rounded;

    switch (block.type) {
      case BlockType.video:
        return Icons.play_circle_fill_rounded;
      case BlockType.revisionFa:
      case BlockType.studySession:
        return Icons.menu_book_rounded;
      case BlockType.anki:
        return Icons.style_rounded;
      case BlockType.qbank:
        return Icons.quiz_rounded;
      case BlockType.fmgeRevision:
        return Icons.school_rounded;
      case BlockType.breakBlock:
        return Icons.coffee_rounded;
      case BlockType.mixed:
        return Icons.dashboard_rounded;
      case BlockType.other:
        return block.isEvent ? Icons.event_rounded : Icons.task_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = _categoryColor(block);
    final startMin = _toMinutes(block.plannedStartTime);
    final endMin = _toMinutes(block.plannedEndTime);
    final duration =
        endMin > startMin ? endMin - startMin : block.plannedDurationMinutes;
    final double cardHeight =
        (duration * 2.0).clamp(64.0, double.infinity).toDouble();

    final isDone = block.status == BlockStatus.done;
    final isSplit = block.splitTotalParts != null && block.splitTotalParts! > 1;
    final ringColor = _statusRingColor(cs, accent);

    final startLabel = _to12hShort(block.plannedStartTime);
    final rangeLabel =
        '${_to12h(block.plannedStartTime)} - ${_to12h(block.plannedEndTime)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          if (leading != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: _kTimelineHandleWidth,
                child: leading,
              ),
            ),
            const SizedBox(width: _kTimelineHandleGap),
          ],
          // -- Time Column --
          SizedBox(
            width: _kTimelineTimeWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(startLabel, textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.45),
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ),
          ),
              const SizedBox(width: _kTimelineTimeToPillGap),
              Container(
                width: _kTimelinePillWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  color: _kTimelinePillColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.18),
                  ),
                ),
                child: Center(
                  child: Tooltip(
                    message: _categoryLabel(block),
                    child: Icon(
                      _iconForBlock(),
                      size: 24,
                      color: accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _kTimelineContentGap),
          // Card
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Container(
                height: cardHeight,
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: color, width: 3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                      blurRadius: 4, offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      block.title,
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        color: isDone
                            ? cs.onSurface.withValues(alpha: 0.5)
                            : cs.onSurface,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(children: [
                      Icon(Icons.access_time_rounded, size: 11,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Text('$startLabel – $endLabel',
                          style: TextStyle(fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.55))),
                      const SizedBox(width: 6),
                      Text('•', style: TextStyle(
                          fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
                      const SizedBox(width: 6),
                      Text(_formatDuration(duration),
                          style: TextStyle(fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.55))),
                    ]),
                    if (isSplit) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Part ${block.splitPartIndex} of ${block.splitTotalParts}',
                            style: const TextStyle(fontSize: 10,
                                fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
                      ),
                    ],
                    if (isDone)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 13, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          const Text('Completed', style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981))),
                        ]),
                      ),
                    if (isSkipped)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(children: [
                          Icon(Icons.skip_next_rounded, size: 13,
                              color: cs.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 4),
                          Text('Skipped', style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.4))),
                        ]),
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

// -- Gap Slot ------------------------------------------------------
*/

class _BlockCard extends StatelessWidget {
  final Block block;
  final bool isDark;
  final Widget? leading;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

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

  IconData _iconForBlock() {
    final lowerTitle = block.title.toLowerCase();

    if (lowerTitle.contains('wake') ||
        lowerTitle.contains('rise') ||
        lowerTitle.contains('morning')) {
      return Icons.alarm_rounded;
    }
    if (lowerTitle.contains('wind down') ||
        lowerTitle.contains('sleep') ||
        lowerTitle.contains('night')) {
      return Icons.dark_mode_rounded;
    }
    if (block.id.startsWith('prayer_')) return Icons.mosque_rounded;

    switch (block.type) {
      case BlockType.video:
        return Icons.play_circle_fill_rounded;
      case BlockType.revisionFa:
      case BlockType.studySession:
        return Icons.menu_book_rounded;
      case BlockType.anki:
        return Icons.style_rounded;
      case BlockType.qbank:
        return Icons.quiz_rounded;
      case BlockType.fmgeRevision:
        return Icons.school_rounded;
      case BlockType.breakBlock:
        return Icons.coffee_rounded;
      case BlockType.mixed:
        return Icons.dashboard_rounded;
      case BlockType.other:
        return block.isEvent ? Icons.event_rounded : Icons.task_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _baseBlockColor(block);
    final startMin = _toMinutes(block.plannedStartTime);
    final endMin = _toMinutes(block.plannedEndTime);
    final duration =
        endMin > startMin ? endMin - startMin : block.plannedDurationMinutes;
    final cardHeight = (duration * 2.0).clamp(64.0, double.infinity).toDouble();
    final isDone = block.status == BlockStatus.done;
    final isSplit = block.splitTotalParts != null && block.splitTotalParts! > 1;
    final pillColor = isDone ? _kTimelineCompletedPill : accent;
    final startLabel = _to12hShort(block.plannedStartTime);
    final rangeLabel =
        '${_to12h(block.plannedStartTime)} - ${_to12h(block.plannedEndTime)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: _kTimelineHandleWidth,
                    child: leading,
                  ),
                ),
                const SizedBox(width: _kTimelineHandleGap),
              ],
              SizedBox(
                width: _kTimelineTimeWidth,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    startLabel,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kTimelineMuted,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _kTimelineTimeToPillGap),
              Container(
                width: _kTimelinePillWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Tooltip(
                    message: _categoryLabel(block),
                    child: Icon(
                      _iconForBlock(),
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _kTimelineContentGap),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.title,
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                          color: isDone
                              ? Colors.white.withValues(alpha: 0.72)
                              : Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rangeLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kTimelineMuted,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (isSplit) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Part ${block.splitPartIndex} of ${block.splitTotalParts}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kTimelineMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: _kTimelineStatusSize,
                  height: _kTimelineStatusSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? _kTimelineComplete : Colors.transparent,
                    border:
                        isDone ? null : Border.all(color: pillColor, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

/*
class _GapSlot extends StatelessWidget {
  final int startMinutes;
  final int endMinutes;
  final VoidCallback onTap;
  final bool isDark;

  const _GapSlot({required this.startMinutes, required this.endMinutes,
      required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gapMinutes = endMinutes - startMinutes;
    final double gapHeight =
        (gapMinutes * 2.0).clamp(48.0, double.infinity).toDouble();

    final List<int> hourTicks = [];
    final firstHourInGap = (startMinutes ~/ 60) * 60 + 60;
    for (int tick = firstHourInGap; tick < endMinutes; tick += 60) hourTicks.add(tick);

    final startLabel = _to12h(_minutesToHHMM(startMinutes));
    final endLabel = _to12h(_minutesToHHMM(endMinutes));
    final durationLabel = _formatDuration(gapMinutes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 60, height: gapHeight,
            child: Stack(
              children: [
                Positioned(top: 0, right: 4,
                  child: Text(startLabel, style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.4),
                      fontFeatures: const [FontFeature.tabularFigures()]))),
                ...hourTicks.map((tick) {
                  final fraction = (tick - startMinutes) / gapMinutes;
                  final topPos = fraction * gapHeight;
                  return Positioned(top: topPos - 7, right: 4,
                      child: Text(_to12h(_minutesToHHMM(tick)), style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w500,
                          color: cs.onSurface.withValues(alpha: 0.28),
                          fontFeatures: const [FontFeature.tabularFigures()])));
                }),
              ],
            ),
          ),
          // Dashed line
          SizedBox(
            width: 20, height: gapHeight,
            child: Stack(
              children: [
                Positioned(left: 9, top: 0, bottom: 0,
                  child: CustomPaint(
                    size: const Size(2, double.infinity),
                    painter: _DashedLinePainter(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08)),
                  ),
                ),
                ...hourTicks.map((tick) {
                  final fraction = (tick - startMinutes) / gapMinutes;
                  final topPos = fraction * gapHeight;
                  return Positioned(top: topPos - 3, left: 5,
                      child: Container(width: 10, height: 2,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.black.withValues(alpha: 0.15)));
                }),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Gap action card
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: gapHeight,
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.025)
                      : const Color(0xFFF5F5FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFE0E0F5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('FREE', style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800,
                            color: cs.primary.withValues(alpha: 0.6), letterSpacing: 0.5)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text('$startLabel – $endLabel',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.5)))),
                      Icon(Icons.add_circle_outline_rounded, size: 16,
                          color: cs.primary.withValues(alpha: 0.5)),
                    ]),
                    const SizedBox(height: 4),
                    Text(durationLabel, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.4))),
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

// -- Dashed Line Painter -----------------------------------------------
*/

class _GapSlot extends StatelessWidget {
  final int startMinutes;
  final int endMinutes;
  final VoidCallback onTap;
  final VoidCallback? onAddTask;
  final bool isDark;

  const _GapSlot({
    required this.startMinutes,
    required this.endMinutes,
    required this.onTap,
    required this.isDark,
    this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final gapMinutes = endMinutes - startMinutes;
    final gapHeight =
        (gapMinutes * 2.0).clamp(78.0, double.infinity).toDouble();

    final hourTicks = <int>[];
    final firstHourInGap = (startMinutes ~/ 60) * 60 + 60;
    for (int tick = firstHourInGap; tick < endMinutes; tick += 60) {
      hourTicks.add(tick);
    }

    final startLabel = _to12hShort(_minutesToHHMM(startMinutes));
    final durationLabel = _formatGapDurationCompact(gapMinutes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: gapHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: _kTimelineLeadingWidth),
              SizedBox(
                width: _kTimelineTimeWidth,
                height: gapHeight,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Text(
                        startLabel,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kTimelineMuted,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    ...hourTicks.map((tick) {
                      final fraction = (tick - startMinutes) / gapMinutes;
                      final topPos = fraction * gapHeight;
                      return Positioned(
                        top: topPos - 6,
                        right: 0,
                        child: Text(
                          _to12hShort(_minutesToHHMM(tick)),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _kTimelineMuted,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: _kTimelineTimeToPillGap),
              SizedBox(
                width: _kTimelinePillWidth,
                height: gapHeight,
                child: Center(
                  child: CustomPaint(
                    size: Size(2, gapHeight),
                    painter: const _DashedLinePainter(color: _kTimelineDivider),
                  ),
                ),
              ),
              const SizedBox(width: _kTimelineContentGap),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.access_time_outlined,
                            size: 15,
                            color: _kTimelineMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _kTimelineMuted,
                                  height: 1.35,
                                ),
                                children: [
                                  const TextSpan(text: 'Use '),
                                  TextSpan(
                                    text: durationLabel,
                                    style: const TextStyle(
                                      color: _kTimelineGapAccent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const TextSpan(text: ' wisely. Create away!'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: onAddTask ?? onTap,
                        icon: const Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: _kTimelineGapAccent,
                        ),
                        label: const Text(
                          'Add Task',
                          style: TextStyle(
                            color: _kTimelineGapAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 0,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: _kTimelineCardBackground,
                          side: const BorderSide(color: _kTimelineGapAccent),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: _kTimelineStatusSize + 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dashHeight = 4.0;
    const gapHeight = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashHeight), paint);
      y += dashHeight + gapHeight;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}
