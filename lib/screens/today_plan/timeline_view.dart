// =============================================================
// TimelineView — scrollable timeline widget for day blocks
// Time column left, cards right, 12-hour AM/PM, hourly ticks
// in free gaps, proportional block heights.
// =============================================================

import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'free_gap_panel.dart';

// ── Helpers ───────────────────────────────────────────────────────
String _to12h(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return hhmm;
  final h24 = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  final suffix = h24 < 12 ? 'AM' : 'PM';
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $suffix';
}

String _formatDuration(int minutes) {
  if (minutes >= 60) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}min' : '${h}h';
  }
  return '$minutes min';
}

int _toMinutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return 0;
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}

String _minutesToHHMM(int minutes) {
  final h = (minutes ~/ 60).clamp(0, 23);
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

// ── Category helpers ──────────────────────────────────────────────
Color _categoryColor(Block block) {
  if (block.isEvent || block.id.startsWith('prayer_')) {
    return const Color(0xFFEF4444);
  }
  switch (block.type) {
    case BlockType.studySession:
    case BlockType.revisionFa:
    case BlockType.fmgeRevision:
      return const Color(0xFF3B82F6);
    case BlockType.video:
      return const Color(0xFFF59E0B);
    case BlockType.breakBlock:
      return const Color(0xFF94A3B8);
    case BlockType.other:
      if (block.title.contains('🕌') || block.id.startsWith('prayer_')) {
        return const Color(0xFF0D9488);
      }
      return const Color(0xFF8B5CF6);
    default:
      return const Color(0xFF8B5CF6);
  }
}

String _categoryLabel(Block block) {
  if (block.id.startsWith('prayer_')) return 'Prayer';
  if (block.isEvent) return 'Event';
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

// ── Widget ────────────────────────────────────────────────────────
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
  List<_TimelineItem> _buildTimelineItems() {
    final items = <_TimelineItem>[];
    final sorted = List<Block>.from(widget.blocks)
      ..sort((a, b) =>
          _toMinutes(a.plannedStartTime).compareTo(_toMinutes(b.plannedStartTime)));

    for (int i = 0; i < sorted.length; i++) {
      final block = sorted[i];

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
    if (block.isEvent || block.id.startsWith('prayer_')) return;
    HapticsService.medium();
    _showEditSheet(block);
  }

  void _onBlockTap(Block block) {
    _showEditSheet(block);
  }

  void _showEditSheet(Block block) {
    final cs = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(text: block.title);
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    bool isEvent = block.isEvent;

    final sp = block.plannedStartTime.split(':');
    if (sp.length == 2) {
      startTime = TimeOfDay(
        hour: int.tryParse(sp[0]) ?? 0,
        minute: int.tryParse(sp[1]) ?? 0,
      );
    }
    final ep = block.plannedEndTime.split(':');
    if (ep.length == 2) {
      endTime = TimeOfDay(
        hour: int.tryParse(ep[0]) ?? 0,
        minute: int.tryParse(ep[1]) ?? 0,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          String _fmt(TimeOfDay? t) {
            if (t == null) return '--';
            final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
            final suffix = t.hour < 12 ? 'AM' : 'PM';
            return '$h12:${t.minute.toString().padLeft(2, '0')} $suffix';
          }

          return Container(
            padding: EdgeInsets.fromLTRB(
              20, 20, 20,
              MediaQuery.of(ctx).viewInsets.bottom +
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
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Edit Block',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Block name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            builder: (c, child) => MediaQuery(
                              data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: false),
                              child: child!,
                            ),
                          );
                          if (picked != null) setS(() => startTime = picked);
                        },
                        icon: const Icon(Icons.access_time_rounded, size: 16),
                        label: Text(_fmt(startTime)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: endTime ?? TimeOfDay.now(),
                            builder: (c, child) => MediaQuery(
                              data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: false),
                              child: child!,
                            ),
                          );
                          if (picked != null) setS(() => endTime = picked);
                        },
                        icon: const Icon(Icons.access_time_rounded, size: 16),
                        label: Text(_fmt(endTime)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Fixed Event', style: TextStyle(fontSize: 14)),
                  subtitle: isEvent
                      ? Text(
                          'Event times are fixed and won\'t be moved by the scheduler',
                          style: TextStyle(fontSize: 11, color: cs.error.withValues(alpha: 0.7)),
                        )
                      : null,
                  value: isEvent,
                  onChanged: (v) => setS(() => isEvent = v),
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
                        icon: Icon(Icons.delete_outline_rounded, size: 16, color: cs.error),
                        label: Text('Delete', style: TextStyle(color: cs.error)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: cs.error.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _saveBlockEdit(block, nameCtrl.text.trim(), startTime, endTime, isEvent);
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

  String _fmtTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _saveBlockEdit(
    Block block, String newTitle,
    TimeOfDay? newStart, TimeOfDay? newEnd, bool newIsEvent,
  ) {
    final app = context.read<AppProvider>();
    final plan = app.getDayPlan(widget.dateKey);
    if (plan == null) return;

    final blocks = List<Block>.from(plan.blocks ?? []);
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx < 0) return;

    final startStr = newStart != null ? _fmtTimeOfDay(newStart) : block.plannedStartTime;
    final endStr = newEnd != null ? _fmtTimeOfDay(newEnd) : block.plannedEndTime;
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
    app.rescheduleFrom(
      widget.dateKey,
      DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day,
        newStart?.hour ?? 0, newStart?.minute ?? 0,
      ),
    );
  }

  void _deleteBlock(Block block) {
    context.read<AppProvider>().removeBlockFromDayPlan(block.id, widget.dateKey);
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
            Icon(Icons.timeline_rounded, size: 48, color: cs.primary.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text('No blocks scheduled',
                style: TextStyle(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 4),
            Text('Add tasks or start your day to build the timeline',
                style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.35))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        0, 8, 0,
        MediaQuery.of(context).padding.bottom + 72 + 24,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isGap) {
          return _GapSlot(
            startMinutes: item.gapStartMinutes!,
            endMinutes: item.gapEndMinutes!,
            onTap: () => _onGapTap(item),
            isDark: isDark,
          );
        }
        final block = item.block!;
        return _BlockCard(
          block: block,
          isDark: isDark,
          onLongPress: () => _onBlockLongPress(block),
          onTap: () => _onBlockTap(block),
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
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const _BlockCard({
    required this.block,
    required this.isDark,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _categoryColor(block);
    final label = _categoryLabel(block);
    final startMin = _toMinutes(block.plannedStartTime);
    final endMin = _toMinutes(block.plannedEndTime);
    final duration = endMin > startMin
        ? endMin - startMin
        : block.plannedDurationMinutes;
    // Proportional height: 1 min = 2px, min 56px
    final cardHeight = (duration * 2.0).clamp(56.0, double.infinity);

    final isLocked = block.isEvent || block.id.startsWith('prayer_');
    final isDone = block.status == BlockStatus.done;
    final isSkipped = block.status == BlockStatus.skipped;
    final isSplit = block.splitTotalParts != null && block.splitTotalParts! > 1;

    final startLabel = _to12h(block.plannedStartTime);
    final endLabel = _to12h(block.plannedEndTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Time Column ──────────────────────
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 10, right: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    startLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.65),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Dot + Line ───────────────────────
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
                height: cardHeight - 10,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // ── Card ─────────────────────────────
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
                  border: Border(
                    left: BorderSide(color: color, width: 3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title row
                    Row(
                      children: [
                        if (isLocked)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.lock_rounded, size: 13, color: color),
                          ),
                        Expanded(
                          child: Text(
                            block.displayEmoji != null
                                ? '${block.displayEmoji} ${block.title}'
                                : block.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDone
                                  ? cs.onSurface.withValues(alpha: 0.4)
                                  : cs.onSurface,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                    const SizedBox(height: 5),
                    // Time + duration row
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 4),
                        Text(
                          '$startLabel – $endLabel',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('•',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.3))),
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                    // Status / split badges
                    if (isSplit) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                            const Icon(Icons.check_circle_rounded,
                                size: 13, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            const Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
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
                                size: 13,
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

// ── Gap Slot with Hourly Ticks ────────────────────────────────────
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
    final gapMinutes = endMinutes - startMinutes;
    final gapHeight = (gapMinutes * 2.0).clamp(48.0, double.infinity);

    // Collect hourly tick positions inside the gap
    final List<int> hourTicks = [];
    final firstHourInGap =
        (startMinutes ~/ 60) * 60 + 60; // next whole hour after start
    for (int tick = firstHourInGap; tick < endMinutes; tick += 60) {
      hourTicks.add(tick);
    }

    final startLabel = _to12h(_minutesToHHMM(startMinutes));
    final endLabel = _to12h(_minutesToHHMM(endMinutes));
    final durationLabel = _formatDuration(gapMinutes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Time column with hourly ticks ────
          SizedBox(
            width: 60,
            height: gapHeight,
            child: Stack(
              children: [
                // Start label at top
                Positioned(
                  top: 0,
                  right: 4,
                  child: Text(
                    startLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.4),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                // Intermediate hourly ticks
                ...hourTicks.map((tick) {
                  final fraction = (tick - startMinutes) / gapMinutes;
                  final topPos = fraction * gapHeight;
                  return Positioned(
                    top: topPos - 7,
                    right: 4,
                    child: Text(
                      _to12h(_minutesToHHMM(tick)),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.28),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // ── Dashed line column ────────────────
          SizedBox(
            width: 20,
            height: gapHeight,
            child: Stack(
              children: [
                // Vertical dashed line
                Positioned(
                  left: 9,
                  top: 0,
                  bottom: 0,
                  child: CustomPaint(
                    size: const Size(2, double.infinity),
                    painter: _DashedLinePainter(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                // Hourly tick marks on the line
                ...hourTicks.map((tick) {
                  final fraction = (tick - startMinutes) / gapMinutes;
                  final topPos = fraction * gapHeight;
                  return Positioned(
                    top: topPos - 3,
                    left: 5,
                    child: Container(
                      width: 10,
                      height: 2,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.black.withValues(alpha: 0.15),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // ── Gap action card ───────────────────
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
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: FREE badge + duration
                    Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$startLabel – $endLabel',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 16,
                          color: cs.primary.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      durationLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.4),
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

// ── Dashed Line Painter ───────────────────────────────────────────
class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
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
