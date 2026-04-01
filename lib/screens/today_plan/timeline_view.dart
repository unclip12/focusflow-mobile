// ignore_for_file: unused_element_parameter

// =============================================================
// TimelineView — scrollable timeline with:
//   • 12-hour AM/PM time labels
//   • Proportional block heights (1 min = 2 px)
//   • Hourly ticks in free gaps
//   • TAP any block ? edit sheet (or detail sheet for locked blocks)
//   • LONG-PRESS non-locked block ? drag to reorder ? start times cascade
// =============================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/active_study_session.dart';
import 'package:focusflow_mobile/models/reminder.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/utils/date_utils.dart';
import 'package:intl/intl.dart';
import 'block_detail_modal.dart';
import 'block_editor_sheet.dart';
import 'free_gap_panel.dart';
import 'routine_runner_screen.dart';
import 'study_flow_screen.dart';
import 'study_session_picker.dart';

// -- Helpers --------------------------------------------------
typedef TimelineAddTaskCallback = Future<void> Function(
    {int? startMinutes, bool isEvent});

String _to12h(String hhmm) {
  final normalized = _normalizeTimeValue(hhmm);
  if (normalized == null) return hhmm;

  final parts = normalized.split(':');
  if (parts.length != 2) return hhmm;
  final h24 = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  final suffix = h24 < 12 ? 'AM' : 'PM';
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $suffix';
}

String _minutesToHHMM(int minutes) {
  final safeMinutes =
      minutes >= 24 * 60 ? (24 * 60) - 1 : minutes.clamp(0, 23 * 60 + 59);
  final h = safeMinutes ~/ 60;
  final m = safeMinutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

String? _normalizeTimeValue(String? raw) {
  if (raw == null) return null;

  final value = raw.trim();
  if (value.isEmpty) return null;

  final parsedDateTime = DateTime.tryParse(value);
  if (parsedDateTime != null) {
    return _minutesToHHMM(parsedDateTime.hour * 60 + parsedDateTime.minute);
  }

  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
  if (match == null) return null;

  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

int? _minutesFromTimeValue(String? raw) {
  final normalized = _normalizeTimeValue(raw);
  if (normalized == null) return null;

  final parts = normalized.split(':');
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}

int _durationFromTimeRange(
  String start,
  String end, {
  required int fallbackMinutes,
}) {
  final startMinutes = _minutesFromTimeValue(start);
  final endMinutes = _minutesFromTimeValue(end);
  if (startMinutes == null ||
      endMinutes == null ||
      endMinutes <= startMinutes) {
    return fallbackMinutes;
  }

  return endMinutes - startMinutes;
}

String _to12hShort(String hhmm) {
  final normalized = _normalizeTimeValue(hhmm);
  if (normalized == null) return hhmm;

  final parts = normalized.split(':');
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

String _formatDurationMetaLabel(int minutes) {
  if (minutes >= 60) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}min' : '${h}h';
  }
  return '$minutes min';
}

double _scaledTimelineHeight(int minutes) {
  final safeMinutes = minutes < 0 ? 0 : minutes;
  return safeMinutes * 1.2;
}

double _timelinePillHeight(int minutes) {
  final scaledHeight = _scaledTimelineHeight(minutes);
  return scaledHeight < 56.0 ? 56.0 : scaledHeight;
}

const double _kTimelineHandleWidth = 14;
const double _kTimelineHandleGap = 4;
const double _kTimelineLeadingWidth =
    _kTimelineHandleWidth + _kTimelineHandleGap;
const double _kTimelineTimeWidth = 36;
const double _kTimelineTimeToPillGap = 4;
const double _kTimelinePillWidth = 46;
const double _kTimelineContentGap = 8;
const double _kTimelineStatusSize = 20;
const Color _kTimelineAccent = Color(0xFFE8837A);
const Color _kTimelineGapAccent = _kTimelineAccent;
const double _kNowOverlayHeight = 24;
const double _kNowLineThickness = 1.5;
const double _kNowDotSize = 10;
const double _kGapRowMinHeight = 80;
const double _kGapRowHorizontalPadding = 8;
const double _kGapRowVerticalPadding = 8;
const double _kGapButtonHeight = 36;
const double _kGapButtonHorizontalPadding = 16;
const double _kGapPromptToButtonSpacing = 6;
const double _kGapButtonToDividerSpacing = 8;
const double _kGapDividerToFutureSpacing = 8;
const double _kGapFutureToButtonSpacing = 6;
const double _kGapSectionBottomSpacing = 12;
const double _kCompactFutureTimelineHeight = 220;

double _gapSlotHeight(
  int minutes, {
  required bool hasPastSection,
  required bool hasFutureSection,
}) {
  final scaledHeight = _scaledTimelineHeight(minutes);
  final contentMinHeight = hasPastSection && hasFutureSection
      ? 168.0
      : (hasPastSection || hasFutureSection ? 108.0 : _kGapRowMinHeight);
  return math.max(
    _kGapRowMinHeight,
    math.max(scaledHeight, contentMinHeight),
  );
}

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

enum _TimelineBlockRelation { sameDay, carryOut, carryIn }

class _TimelineBlockSlice {
  final Block block;
  final int visibleStartMinutes;
  final int visibleEndMinutes;
  final _TimelineBlockRelation relation;
  final DateTime displayDate;

  const _TimelineBlockSlice({
    required this.block,
    required this.visibleStartMinutes,
    required this.visibleEndMinutes,
    required this.relation,
    required this.displayDate,
  });

  int get visibleDurationMinutes =>
      math.max(0, visibleEndMinutes - visibleStartMinutes);

  String get startLabel => _to12hShort(_minutesToHHMM(visibleStartMinutes));

  String get rangeLabel {
    final fullStart = _to12h(block.plannedStartTime);
    final fullEnd = _to12h(_fullEndTime);
    switch (relation) {
      case _TimelineBlockRelation.sameDay:
        return '$fullStart - $fullEnd';
      case _TimelineBlockRelation.carryOut:
        return '$fullStart - $fullEnd (next day)';
      case _TimelineBlockRelation.carryIn:
        return '$fullStart - $fullEnd (previous day)';
    }
  }

  String? get adjacentActionLabel {
    switch (relation) {
      case _TimelineBlockRelation.sameDay:
        return null;
      case _TimelineBlockRelation.carryOut:
        return 'Next day';
      case _TimelineBlockRelation.carryIn:
        return 'Previous day';
    }
  }

  DateTime? get adjacentDate {
    switch (relation) {
      case _TimelineBlockRelation.sameDay:
        return null;
      case _TimelineBlockRelation.carryOut:
        return displayDate.add(const Duration(days: 1));
      case _TimelineBlockRelation.carryIn:
        return displayDate.subtract(const Duration(days: 1));
    }
  }

  String get _fullEndTime {
    final startMinutes = _minutesFromTimeValue(block.plannedStartTime) ?? 0;
    final totalMinutes = startMinutes + _resolvedBlockDurationMinutes(block);
    return _minutesToHHMM(totalMinutes % (24 * 60));
  }
}

int _resolvedBlockDurationMinutes(Block block) {
  if (block.plannedDurationMinutes > 0) return block.plannedDurationMinutes;

  final startMinutes = _minutesFromTimeValue(block.plannedStartTime) ?? 0;
  final endMinutes = _minutesFromTimeValue(block.plannedEndTime) ?? 0;
  final rawDuration = endMinutes - startMinutes;
  return rawDuration > 0 ? rawDuration : 0;
}

// -- Widget ----------------------------------------------------
class TimelineView extends StatefulWidget {
  final List<Block> blocks;
  final List<ReminderOccurrence> reminders;
  final String dateKey;
  final TimelineAddTaskCallback? onAddTask;
  final ValueChanged<DateTime>? onOpenDate;
  final Future<void> Function(ReminderOccurrence occurrence)? onReminderTap;
  final Future<void> Function(ReminderOccurrence occurrence, bool completed)?
      onReminderToggle;

  const TimelineView({
    super.key,
    required this.blocks,
    required this.reminders,
    required this.dateKey,
    this.onAddTask,
    this.onOpenDate,
    this.onReminderTap,
    this.onReminderToggle,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  late DateTime _currentTime;
  Timer? _nowTimer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _nowTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _nowTimer?.cancel();
    super.dispose();
  }

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
  // ignore: unused_element
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
    return _resolvedBlockDurationMinutes(block);
  }

  String _lockedCategoryLabel(Block block) =>
      block.id.startsWith('prayer_') ? 'Prayer' : 'Event';

  String _formatMinutesOfDay(int totalMinutes) => _minutesToHHMM(totalMinutes);

  int _countMovableBlocksBefore(List<_TimelineItem> items, int endExclusive) {
    var count = 0;

    for (var i = 0; i < endExclusive && i < items.length; i++) {
      final item = items[i];
      if (item.isGap || item.isWarning || item.block == null) continue;
      if (item.slice?.relation == _TimelineBlockRelation.carryIn) continue;
      if (_isLockedBlock(item.block!)) continue;
      count++;
    }

    return count;
  }

  bool get _isViewingToday {
    final selectedDate = _selectedDate;
    if (selectedDate == null) return false;
    return selectedDate.year == _currentTime.year &&
        selectedDate.month == _currentTime.month &&
        selectedDate.day == _currentTime.day;
  }

  DateTime? get _selectedDate => AppDateUtils.parseDate(widget.dateKey);

  DateTime? get _previousDate =>
      _selectedDate?.subtract(const Duration(days: 1));

  String _dateKeyForDate(DateTime date) => AppDateUtils.formatDate(date);

  // ignore: unused_element
  bool get _isViewingFuture {
    final selectedDate = _selectedDate;
    if (selectedDate == null) return false;

    final currentDay = DateTime(
      _currentTime.year,
      _currentTime.month,
      _currentTime.day,
    );
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    return selectedDay.isAfter(currentDay);
  }

  int get _currentMinutesOfDay => _currentTime.hour * 60 + _currentTime.minute;

  _TimelineBlockSlice? _buildCurrentDaySlice(
    Block block,
    DateTime displayDate,
  ) {
    final startMinutes = _toMinutes(block.plannedStartTime).clamp(0, 1439);
    final durationMinutes = _blockDurationMinutes(block);
    final visibleEndMinutes = math.min(24 * 60, startMinutes + durationMinutes);
    if (visibleEndMinutes <= startMinutes) return null;

    final relation = startMinutes + durationMinutes > 24 * 60
        ? _TimelineBlockRelation.carryOut
        : _TimelineBlockRelation.sameDay;

    return _TimelineBlockSlice(
      block: block,
      visibleStartMinutes: startMinutes,
      visibleEndMinutes: visibleEndMinutes,
      relation: relation,
      displayDate: displayDate,
    );
  }

  _TimelineBlockSlice? _buildCarryInSlice(
    Block block,
    DateTime displayDate,
  ) {
    final startMinutes = _toMinutes(block.plannedStartTime);
    final durationMinutes = _blockDurationMinutes(block);
    final overflowMinutes = (startMinutes + durationMinutes) - (24 * 60);
    final visibleEndMinutes = overflowMinutes.clamp(0, 24 * 60);
    if (visibleEndMinutes <= 0) return null;

    return _TimelineBlockSlice(
      block: block,
      visibleStartMinutes: 0,
      visibleEndMinutes: visibleEndMinutes,
      relation: _TimelineBlockRelation.carryIn,
      displayDate: displayDate,
    );
  }

  List<_TimelineBlockSlice> _displaySlicesForSelectedDate() {
    final selectedDate = _selectedDate;
    if (selectedDate == null) {
      return widget.blocks
          .map((block) => _buildCurrentDaySlice(block, DateTime.now()))
          .whereType<_TimelineBlockSlice>()
          .toList();
    }

    final app = context.read<AppProvider>();
    final slices = <_TimelineBlockSlice>[];

    for (final block in widget.blocks) {
      final slice = _buildCurrentDaySlice(block, selectedDate);
      if (slice != null) {
        slices.add(slice);
      }
    }

    final previousDate = _previousDate;
    if (previousDate != null) {
      final previousDateKey = _dateKeyForDate(previousDate);
      final previousBlocks =
          List<Block>.from(app.getDayPlan(previousDateKey)?.blocks ?? const []);
      for (final block in previousBlocks) {
        final slice = _buildCarryInSlice(block, selectedDate);
        if (slice != null) {
          slices.add(slice);
        }
      }
    }

    slices.sort((left, right) {
      final startCompare =
          left.visibleStartMinutes.compareTo(right.visibleStartMinutes);
      if (startCompare != 0) return startCompare;

      final endCompare =
          left.visibleEndMinutes.compareTo(right.visibleEndMinutes);
      if (endCompare != 0) return endCompare;

      if (left.relation != right.relation) {
        if (left.relation == _TimelineBlockRelation.carryIn) return -1;
        if (right.relation == _TimelineBlockRelation.carryIn) return 1;
      }

      final indexCompare = left.block.index.compareTo(right.block.index);
      if (indexCompare != 0) return indexCompare;
      return left.block.id.compareTo(right.block.id);
    });

    return slices;
  }

  int _roundUpToNextFiveMinutes(int minutes) => ((minutes + 4) ~/ 5) * 5;

  String _formatCurrentTimeLabel() {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: _currentTime.hour, minute: _currentTime.minute),
      alwaysUse24HourFormat: false,
    );
  }

  int _sumMinutesByType(List<Block> blocks, bool Function(Block block) test) {
    return blocks
        .where(test)
        .fold<int>(0, (sum, block) => sum + block.plannedDurationMinutes);
  }

  _TimelineBounds _resolveTimelineBounds() {
    return const _TimelineBounds(
      startMinutes: 0,
      endMinutes: 24 * 60,
    );
  }

  double? _lineOffsetForRange({
    required int startMinutes,
    required int endMinutes,
    required double height,
  }) {
    final duration = endMinutes - startMinutes;
    if (!_isViewingToday || duration <= 0) return null;
    if (_currentMinutesOfDay < startMinutes ||
        _currentMinutesOfDay >= endMinutes) {
      return null;
    }

    final fraction = (_currentMinutesOfDay - startMinutes) / duration;
    return (fraction * height).clamp(0.0, height);
  }

  double _pastFractionForBlock({
    required int startMinutes,
    required int endMinutes,
  }) {
    if (!_isViewingToday || endMinutes <= startMinutes) return 0;
    if (_currentMinutesOfDay <= startMinutes) return 0;
    if (_currentMinutesOfDay >= endMinutes) return 1;
    return ((_currentMinutesOfDay - startMinutes) / (endMinutes - startMinutes))
        .clamp(0.0, 1.0);
  }

  Block _buildDraftBlock({
    required int startMinutes,
    required int endMinutes,
    required String title,
    String? description,
    bool isEvent = false,
    BlockType type = BlockType.other,
  }) {
    final safeStart = startMinutes.clamp(0, (24 * 60) - 2);
    var safeEnd = endMinutes.clamp(safeStart + 1, 24 * 60);
    if (safeEnd <= safeStart) {
      safeEnd = math.min(24 * 60, safeStart + 60);
    }

    return Block(
      id: 'draft_${DateTime.now().microsecondsSinceEpoch}',
      index: 0,
      date: widget.dateKey,
      plannedStartTime: _formatMinutesOfDay(safeStart),
      plannedEndTime: _formatMinutesOfDay(safeEnd % (24 * 60)),
      type: type,
      title: title,
      description: description,
      plannedDurationMinutes: safeEnd - safeStart,
      isEvent: isEvent,
      status: BlockStatus.notStarted,
    );
  }

  Future<void> _saveNewBlock(BlockEditorUpdate update, String blockId) async {
    final app = context.read<AppProvider>();
    final existingPlan = app.getDayPlan(update.dateKey);
    final existingBlocks = List<Block>.from(existingPlan?.blocks ?? const []);
    final newBlock = Block(
      id: blockId,
      index: existingBlocks.length,
      date: update.dateKey,
      plannedStartTime: update.plannedStartTime,
      plannedEndTime: update.plannedEndTime,
      type: update.type,
      title: update.title,
      description: update.description,
      plannedDurationMinutes: update.plannedDurationMinutes,
      alertOffsetMinutes: update.alertOffsetMinutes,
      alertType: update.alertType,
      recurrenceType: update.recurrenceType,
      recurrenceDays: update.recurrenceDays,
      isEvent: update.isEvent,
      status: BlockStatus.notStarted,
    );

    final allBlocks = [...existingBlocks, newBlock]..sort(
        (a, b) => _toMinutes(a.plannedStartTime)
            .compareTo(_toMinutes(b.plannedStartTime)),
      );
    final reindexedBlocks = <Block>[
      for (var i = 0; i < allBlocks.length; i++)
        allBlocks[i].copyWith(index: i),
    ];

    final updatedPlan = existingPlan?.copyWith(
          blocks: reindexedBlocks,
          totalStudyMinutesPlanned: _sumMinutesByType(
            reindexedBlocks,
            (block) => block.type != BlockType.breakBlock,
          ),
          totalBreakMinutes: _sumMinutesByType(
            reindexedBlocks,
            (block) => block.type == BlockType.breakBlock,
          ),
        ) ??
        DayPlan(
          date: update.dateKey,
          faPages: const [],
          faPagesCount: 0,
          videos: const [],
          notesFromUser: '',
          notesFromAI: '',
          attachments: const [],
          breaks: const [],
          blocks: reindexedBlocks,
          totalStudyMinutesPlanned: _sumMinutesByType(
            reindexedBlocks,
            (block) => block.type != BlockType.breakBlock,
          ),
          totalBreakMinutes: _sumMinutesByType(
            reindexedBlocks,
            (block) => block.type == BlockType.breakBlock,
          ),
        );

    await app.upsertDayPlan(updatedPlan);
    await app.syncFlowActivitiesFromDayPlan(update.dateKey);
    await app.ensureRecurringBlocksForDate(update.dateKey);
  }

  Future<void> _showNewBlockEditor(Block draftBlock) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlockEditorSheet(
        block: draftBlock,
        onSave: (update) => _saveNewBlock(update, draftBlock.id),
        onDelete: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _openAddLogEditor({
    required int gapStartMinutes,
    required int gapEndMinutes,
    required int dayStartMinutes,
  }) {
    final logStartMinutes = math.max(gapStartMinutes, dayStartMinutes);
    final logEndMinutes = math.min(gapEndMinutes, _currentMinutesOfDay);
    if (logEndMinutes <= logStartMinutes) return Future.value();

    final retroDraft = _buildDraftBlock(
      startMinutes: logStartMinutes,
      endMinutes: logEndMinutes,
      title: 'Retroactive Log',
      description: 'Retroactive log entry',
    );

    return _showNewBlockEditor(retroDraft);
  }

  _GapActionState _buildGapActionState({
    required int gapStartMinutes,
    required int gapEndMinutes,
    required int dayStartMinutes,
  }) {
    final logStartMinutes = math.max(gapStartMinutes, dayStartMinutes);
    final logEndMinutes = math.min(gapEndMinutes, _currentMinutesOfDay);
    final futureStartMinutes = math.max(
        gapStartMinutes, _roundUpToNextFiveMinutes(_currentMinutesOfDay));

    return _GapActionState(
      canAddLog: _isViewingToday && logEndMinutes > logStartMinutes,
      canAddTask: widget.onAddTask != null &&
          (!_isViewingToday || futureStartMinutes < gapEndMinutes),
      taskStartMinutes: _isViewingToday ? futureStartMinutes : gapStartMinutes,
      logStartMinutes: logStartMinutes,
      logEndMinutes: logEndMinutes,
      futureMinutes: math.max(
          0,
          gapEndMinutes -
              (_isViewingToday ? futureStartMinutes : gapStartMinutes)),
    );
  }

  // Build list of timeline items (blocks + gaps)
  List<_TimelineItem> _buildTimelineItems(_TimelineBounds bounds) {
    final sortedSlices = _displaySlicesForSelectedDate();
    final sortedReminders = widget.reminders
        .where((occurrence) => occurrence.isTimed)
        .toList()
      ..sort((left, right) {
        final leftMinutes = _minutesFromTimeValue(left.time) ?? 0;
        final rightMinutes = _minutesFromTimeValue(right.time) ?? 0;
        final timeCompare = leftMinutes.compareTo(rightMinutes);
        if (timeCompare != 0) return timeCompare;
        final completionCompare =
            left.completed == right.completed ? 0 : (left.completed ? 1 : -1);
        if (completionCompare != 0) return completionCompare;
        return left.title.toLowerCase().compareTo(right.title.toLowerCase());
      });
    final items = <_TimelineItem>[];
    var cursor = bounds.startMinutes;
    var sliceIndex = 0;
    var reminderIndex = 0;

    while (sliceIndex < sortedSlices.length ||
        reminderIndex < sortedReminders.length) {
      final nextSlice =
          sliceIndex < sortedSlices.length ? sortedSlices[sliceIndex] : null;
      final nextReminder = reminderIndex < sortedReminders.length
          ? sortedReminders[reminderIndex]
          : null;
      final nextBlockStart =
          nextSlice?.visibleStartMinutes ?? bounds.endMinutes + 1;
      final nextReminderStart =
          _minutesFromTimeValue(nextReminder?.time) ?? bounds.endMinutes + 1;
      final shouldTakeReminder = nextReminder != null &&
          (nextSlice == null || nextReminderStart <= nextBlockStart);

      if (shouldTakeReminder) {
        if (nextReminderStart > cursor && (nextReminderStart - cursor) >= 5) {
          items.add(
            _TimelineItem.gap(
              gapStartMinutes: cursor,
              gapEndMinutes: nextReminderStart,
            ),
          );
        }

        items.add(
          _TimelineItem.reminder(
            nextReminder,
            reminderMinutes: nextReminderStart,
          ),
        );
        if (nextReminderStart > cursor) {
          cursor = nextReminderStart;
        }
        reminderIndex++;
        continue;
      }

      if (nextSlice == null) {
        break;
      }

      final slice = nextSlice;
      final blockStart = slice.visibleStartMinutes;
      final blockEnd = slice.visibleEndMinutes;
      if (blockStart > cursor && (blockStart - cursor) >= 5) {
        items.add(
          _TimelineItem.gap(
            gapStartMinutes: cursor,
            gapEndMinutes: blockStart,
          ),
        );
      } else if (blockStart < cursor && items.isNotEmpty) {
        items.add(
          const _TimelineItem.warning('Tasks are overlapping'),
        );
      }
      items.add(_TimelineItem.block(slice));
      cursor = math.max(cursor, blockEnd);
      sliceIndex++;
    }
    if (bounds.endMinutes > cursor && (bounds.endMinutes - cursor) >= 5) {
      items.add(
        _TimelineItem.gap(
          gapStartMinutes: cursor,
          gapEndMinutes: bounds.endMinutes,
        ),
      );
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

  Future<void> _onBlockTap(Block block) async {
    if (_isLockedBlock(block)) {
      _showLockedDetailSheet(block);
      return;
    }
    if (_isRoutineBlock(block)) {
      await _openRoutineBlock(block);
      return;
    }
    if (_opensStudySession(block)) {
      await _openStudyBlock(block);
      return;
    }
    _showEditSheet(block);
  }

  bool _isRoutineBlock(Block block) {
    return context.read<AppProvider>().isRoutineBlock(block);
  }

  int _earlyRoutineStartMinutes(Block block) {
    if (!_isViewingToday) return 0;
    final plannedStartMinutes = _minutesFromTimeValue(block.plannedStartTime);
    if (plannedStartMinutes == null) return 0;
    final diff = plannedStartMinutes - _currentMinutesOfDay;
    return diff > 0 ? diff : 0;
  }

  Future<bool> _confirmEarlyRoutineStart(int earlyMinutes) async {
    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Routine Early?'),
        content: Text(
          'You are $earlyMinutes minutes early. Do you want to start the routine now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start now'),
          ),
        ],
      ),
    );

    return shouldStart ?? false;
  }

  Future<void> _openRoutineBlock(Block block) async {
    final app = context.read<AppProvider>();
    final sourceDateKey = block.date.isNotEmpty ? block.date : widget.dateKey;
    final routine = app.getRoutineForBlock(block);
    if (routine == null) {
      _showEditSheet(block);
      return;
    }

    if (app.getActiveRoutineRun() != null) {
      await RoutineRunnerScreen.open(
        context,
        routine: routine,
        dateKey: sourceDateKey,
        sourceBlockId: block.id,
      );
      return;
    }

    final latestLog =
        app.getLatestCompletedRoutineLog(routine.id, sourceDateKey);
    if (latestLog != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoutineLogSummaryScreen(
            routine: routine,
            log: latestLog,
            sourceBlockId: block.id,
            showRerun: true,
            onDone: () => Navigator.pop(context),
          ),
        ),
      );
      return;
    }

    final earlyMinutes = _earlyRoutineStartMinutes(block);
    if (earlyMinutes > 0) {
      final shouldStart = await _confirmEarlyRoutineStart(earlyMinutes);
      if (!shouldStart || !mounted) return;
    }

    await RoutineRunnerScreen.open(
      context,
      routine: routine,
      dateKey: sourceDateKey,
      sourceBlockId: block.id,
    );
  }

  Future<void> _openStudyBlock(Block block) async {
    final sourceDateKey = block.date.isNotEmpty ? block.date : widget.dateKey;
    if (block.status == BlockStatus.done) {
      await _showBlockDetailSheet(block, sourceDateKey: sourceDateKey);
      return;
    }

    final app = context.read<AppProvider>();
    final activeSession = app.getActiveStudySession();
    if (activeSession != null &&
        activeSession.kind == ActiveStudySessionKind.studyFlow &&
        activeSession.dateKey == sourceDateKey &&
        activeSession.blockId == block.id) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudyFlowScreen(
            dateKey: sourceDateKey,
            blockId: block.id,
            sessionTitle: block.title,
            autoAdvanceFlow: true,
          ),
        ),
      );
      return;
    }

    final plannedSession = PlannedStudySessionPayload.fromBlock(block);
    if (plannedSession != null && plannedSession.tasks.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudyFlowScreen(
            dateKey: sourceDateKey,
            queuedTasks: plannedSession.tasks,
            blockId: block.id,
            sessionTitle: block.title,
            autoAdvanceFlow: true,
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StudySessionPicker(
        dateKey: sourceDateKey,
        targetBlockId: block.id,
        boundPlannedStartTime: block.plannedStartTime,
        boundPlannedEndTime: block.plannedEndTime,
      ),
    );
  }

  Future<void> _showBlockDetailSheet(
    Block block, {
    required String sourceDateKey,
  }) async {
    final plan = context.read<AppProvider>().getDayPlan(sourceDateKey);
    if (plan == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => BlockDetailModal(block: block, dayPlan: plan),
    );
  }

  Future<void> _markBlockDone(Block block) async {
    if (_isLockedBlock(block) || block.status == BlockStatus.done) return;

    final app = context.read<AppProvider>();
    final sourceDateKey = block.date.isNotEmpty ? block.date : widget.dateKey;
    final plan = app.getDayPlan(sourceDateKey);
    final planBlocks = plan?.blocks;
    if (plan == null || planBlocks == null) return;

    final blockIndex =
        planBlocks.indexWhere((candidate) => candidate.id == block.id);
    if (blockIndex < 0) return;

    final now = DateTime.now();
    final nowTime = _minutesToHHMM(now.hour * 60 + now.minute);
    final updatedBlocks = List<Block>.from(planBlocks);
    final existingBlock = updatedBlocks[blockIndex];

    updatedBlocks[blockIndex] = existingBlock.copyWith(
      status: BlockStatus.done,
      actualStartTime:
          existingBlock.actualStartTime ?? existingBlock.plannedStartTime,
      actualEndTime: nowTime,
    );

    await app.upsertDayPlan(plan.copyWith(blocks: updatedBlocks));
    if (!mounted) return;

    setState(() => _currentTime = now);
    HapticsService.light();
  }

  void _showLockedDetailSheet(Block block) {
    final cs = Theme.of(context).colorScheme;
    final color = _baseBlockColor(block);
    final duration = _blockDurationMinutes(block);
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
    final sourceDateKey = block.date.isNotEmpty ? block.date : widget.dateKey;
    final sourcePlan = app.getDayPlan(sourceDateKey);
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
      alertOffsetMinutes: update.alertOffsetMinutes,
      alertType: update.alertType,
      recurrenceType: update.recurrenceType,
      recurrenceDays: update.recurrenceDays,
      remainingDurationMinutes: update.plannedDurationMinutes > 0
          ? update.plannedDurationMinutes
          : block.remainingDurationMinutes,
      isEvent: update.isEvent,
      type: update.type,
    );

    if (update.dateKey == sourceDateKey) {
      sourceBlocks[sourceIndex] = updatedBlock;
      await app.upsertDayPlan(
        sourcePlan.copyWith(blocks: _reindexBlocks(sourceBlocks)),
      );
      await app.ensureRecurringBlocksForDate(sourceDateKey);
      await app.rescheduleFrom(
        sourceDateKey,
        _anchorForStartTime(update.plannedStartTime),
      );
      return;
    }

    sourceBlocks.removeAt(sourceIndex);
    final updatedSourceBlocks = _reindexBlocks(sourceBlocks);
    await app.upsertDayPlan(sourcePlan.copyWith(blocks: updatedSourceBlocks));
    await app.syncFlowActivitiesFromDayPlan(sourceDateKey);

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
    await app.ensureRecurringBlocksForDate(sourceDateKey);
    if (update.dateKey != sourceDateKey) {
      await app.ensureRecurringBlocksForDate(update.dateKey);
    }
    await app.rescheduleFrom(
      update.dateKey,
      _anchorForStartTime(update.plannedStartTime),
    );
  }

  void _deleteBlock(Block block) {
    context.read<AppProvider>().removeBlockFromDayPlan(
          block.id,
          block.date.isNotEmpty ? block.date : widget.dateKey,
        );
  }

  void _onReorder(int oldIndex, int newIndex, List<_TimelineItem> items) {
    if (oldIndex < 0 || oldIndex >= items.length) return;

    final movedItem = items[oldIndex];
    if (movedItem.isGap ||
        movedItem.isWarning ||
        movedItem.block == null ||
        movedItem.slice?.relation == _TimelineBlockRelation.carryIn ||
        _isLockedBlock(movedItem.block!)) {
      return;
    }

    final app = context.read<AppProvider>();
    final plan = app.getDayPlan(widget.dateKey);
    final planBlocks = plan?.blocks;
    if (plan == null || planBlocks == null) return;

    final movableBlocks = items
        .where(
          (item) =>
              !item.isGap &&
              !item.isWarning &&
              item.block != null &&
              item.slice?.relation != _TimelineBlockRelation.carryIn &&
              !_isLockedBlock(item.block!),
        )
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final surfaceColor = theme.colorScheme.surface;
    final bounds = _resolveTimelineBounds();
    final items = _buildTimelineItems(bounds);
    final bottomPadding = MediaQuery.of(context).padding.bottom + 96;
    final nowLabel = _formatCurrentTimeLabel();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline_rounded,
              size: 48,
              color: onSurface.withValues(alpha: 0.24),
            ),
            const SizedBox(height: 12),
            Text(
              'No blocks scheduled',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add tasks or start your day to build the timeline',
              style: TextStyle(
                fontSize: 13,
                color: onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: EdgeInsets.fromLTRB(0, 8, 0, bottomPadding),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex, items),
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isGap) {
          final gapState = _buildGapActionState(
            gapStartMinutes: item.gapStartMinutes!,
            gapEndMinutes: item.gapEndMinutes!,
            dayStartMinutes: bounds.startMinutes,
          );
          final gapHeight = _gapSlotHeight(
            item.gapEndMinutes! - item.gapStartMinutes!,
            hasPastSection: gapState.canAddLog,
            hasFutureSection: gapState.canAddTask,
          );
          return KeyedSubtree(
            key: ValueKey(
              'gap_${item.gapStartMinutes}_${item.gapEndMinutes}',
            ),
            child: _GapSlot(
              startMinutes: item.gapStartMinutes!,
              endMinutes: item.gapEndMinutes!,
              onTap: () => _onGapTap(item),
              onAddTask: !gapState.canAddTask
                  ? null
                  : () => widget.onAddTask!(
                        startMinutes: gapState.taskStartMinutes,
                      ),
              onAddLog: !gapState.canAddLog
                  ? null
                  : () => _openAddLogEditor(
                        gapStartMinutes: gapState.logStartMinutes,
                        gapEndMinutes: gapState.logEndMinutes,
                        dayStartMinutes: bounds.startMinutes,
                      ),
              futureDurationMinutes: gapState.futureMinutes,
              showPastPrompt: gapState.canAddLog,
              nowLineOffset: _lineOffsetForRange(
                startMinutes: item.gapStartMinutes!,
                endMinutes: item.gapEndMinutes!,
                height: gapHeight,
              ),
              nowLabel: nowLabel,
            ),
          );
        }
        if (item.isWarning) {
          return KeyedSubtree(
            key: ValueKey('warning_${item.warningText}_$index'),
            child: _OverlapWarningRow(
              message: item.warningText ?? 'Tasks are overlapping',
            ),
          );
        }
        if (item.isReminder) {
          final occurrence = item.reminderOccurrence!;
          return KeyedSubtree(
            key: ValueKey(
              'reminder_${occurrence.reminderId}_${occurrence.occurrenceKey}',
            ),
            child: _ReminderTimelineRow(
              occurrence: occurrence,
              reminderMinutes: item.reminderMinutes ?? 0,
              onTap: widget.onReminderTap == null
                  ? null
                  : () => widget.onReminderTap!(occurrence),
              onToggle: widget.onReminderToggle == null
                  ? null
                  : (completed) =>
                      widget.onReminderToggle!(occurrence, completed),
            ),
          );
        }
        final block = item.block!;
        final slice = item.slice!;

        return KeyedSubtree(
          key: ValueKey('block_${block.id}_${slice.relation.name}'),
          child: _BlockCard(
            slice: slice,
            leading: const SizedBox(width: 22),
            onTap: () => _onBlockTap(block),
            onLongPress: () => _onBlockLongPress(block),
            onStatusTap: _isLockedBlock(block) ||
                    block.status == BlockStatus.done ||
                    slice.relation == _TimelineBlockRelation.carryIn ||
                    (slice.relation == _TimelineBlockRelation.sameDay &&
                        !block.isEvent &&
                        !block.id.startsWith('prayer_') &&
                        block.type != BlockType.breakBlock &&
                        block.isAdHocTrack != true)
                ? null
                : () => _markBlockDone(block),
            onAdjacentDateTap:
                slice.adjacentDate == null || widget.onOpenDate == null
                    ? null
                    : () => widget.onOpenDate!(slice.adjacentDate!),
            pastFraction: _pastFractionForBlock(
              startMinutes: slice.visibleStartMinutes,
              endMinutes: slice.visibleEndMinutes,
            ),
            nowLineOffset: _lineOffsetForRange(
              startMinutes: slice.visibleStartMinutes,
              endMinutes: slice.visibleEndMinutes,
              height: _timelinePillHeight(
                slice.visibleDurationMinutes,
              ),
            ),
            nowLabel: nowLabel,
            nowLineBackgroundColor: surfaceColor.withValues(alpha: 0.96),
          ),
        );
      },
    );
  }
}

class _ReminderTimelineRow extends StatelessWidget {
  final ReminderOccurrence occurrence;
  final int reminderMinutes;
  final Future<void> Function()? onTap;
  final Future<void> Function(bool completed)? onToggle;

  const _ReminderTimelineRow({
    required this.occurrence,
    required this.reminderMinutes,
    this.onTap,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final accent = occurrence.isOverdue
        ? const Color(0xFFD97706)
        : const Color(0xFF6366F1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 72,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(width: _kTimelineLeadingWidth),
            SizedBox(
              width: _kTimelineTimeWidth,
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _to12hShort(_minutesToHHMM(reminderMinutes)),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: _kTimelineTimeToPillGap),
            SizedBox(
              width: _kTimelinePillWidth,
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.24),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: _kTimelineContentGap),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onTap == null ? null : () => unawaited(onTap!()),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: occurrence.completed
                          ? accent.withValues(alpha: 0.08)
                          : theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accent.withValues(
                          alpha: occurrence.completed ? 0.16 : 0.28,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                occurrence.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: onSurface.withValues(
                                    alpha: occurrence.completed ? 0.45 : 1,
                                  ),
                                  decoration: occurrence.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      occurrence.isOverdue
                                          ? 'Reminder carried from ${DateFormat('d MMM').format(DateTime.parse(occurrence.occurrenceKey))}'
                                          : 'Reminder',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            onSurface.withValues(alpha: 0.56),
                                      ),
                                    ),
                                  ),
                                  if (occurrence.isOverdue) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'Overdue',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Checkbox(
                          value: occurrence.completed,
                          activeColor: accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: onToggle == null
                              ? null
                              : (value) => unawaited(
                                    onToggle!(value ?? !occurrence.completed),
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
    );
  }
}

// -- Timeline Item --------------------------------------------------
class _TimelineItem {
  final Block? block;
  final _TimelineBlockSlice? slice;
  final ReminderOccurrence? reminderOccurrence;
  final int? reminderMinutes;
  final int? gapStartMinutes;
  final int? gapEndMinutes;
  final bool isGap;
  final bool isWarning;
  final String? warningText;

  const _TimelineItem._(
      {this.block,
      this.slice,
      this.reminderOccurrence,
      this.reminderMinutes,
      this.gapStartMinutes,
      this.gapEndMinutes,
      this.warningText,
      this.isWarning = false,
      required this.isGap});
  factory _TimelineItem.block(_TimelineBlockSlice slice) =>
      _TimelineItem._(block: slice.block, slice: slice, isGap: false);
  factory _TimelineItem.gap(
          {required int gapStartMinutes, required int gapEndMinutes}) =>
      _TimelineItem._(
          gapStartMinutes: gapStartMinutes,
          gapEndMinutes: gapEndMinutes,
          isGap: true);
  factory _TimelineItem.reminder(
    ReminderOccurrence occurrence, {
    required int reminderMinutes,
  }) =>
      _TimelineItem._(
        reminderOccurrence: occurrence,
        reminderMinutes: reminderMinutes,
        isGap: false,
      );
  const _TimelineItem.warning(String message)
      : this._(
          isGap: false,
          isWarning: true,
          warningText: message,
        );

  bool get isReminder => reminderOccurrence != null;
}

class _TimelineBounds {
  final int startMinutes;
  final int endMinutes;

  const _TimelineBounds({
    required this.startMinutes,
    required this.endMinutes,
  });
}

// ignore: unused_element
class _CompactFutureEmptyTimeline extends StatelessWidget {
  final VoidCallback? onAddTask;

  const _CompactFutureEmptyTimeline({
    this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final markers = <_CompactTimelineMarker>[
      const _CompactTimelineMarker(0, '12:00 AM'),
      const _CompactTimelineMarker(6 * 60, '6:00 AM'),
      const _CompactTimelineMarker(12 * 60, '12:00 PM'),
      const _CompactTimelineMarker(18 * 60, '6:00 PM'),
      const _CompactTimelineMarker((24 * 60) - 1, '11:59 PM'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 18, 16, 18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: SizedBox(
          height: _kCompactFutureTimelineHeight,
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(width: _kTimelineLeadingWidth),
                  SizedBox(
                    width: _kTimelineTimeWidth,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final marker in markers)
                          Positioned(
                            top: (_kCompactFutureTimelineHeight - 24) *
                                (marker.minutes / ((24 * 60) - 1)),
                            right: 0,
                            child: Text(
                              marker.label,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: onSurface.withValues(alpha: 0.56),
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: _kTimelineTimeToPillGap),
                  SizedBox(
                    width: _kTimelinePillWidth,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: CustomPaint(
                            size: const Size(2, _kCompactFutureTimelineHeight),
                            painter: _DashedLinePainter(
                              color: theme.dividerColor,
                            ),
                          ),
                        ),
                        for (final marker in markers)
                          Positioned(
                            left: (_kTimelinePillWidth / 2) - 4,
                            top: (_kCompactFutureTimelineHeight - 10) *
                                (marker.minutes / ((24 * 60) - 1)),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: marker.minutes == 0
                                    ? _kTimelineAccent
                                    : theme.colorScheme.surface,
                                border: Border.all(
                                  color: marker.minutes == 0
                                      ? _kTimelineAccent
                                      : onSurface.withValues(alpha: 0.16),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: _kTimelineContentGap),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Full day open',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: _kTimelineAccent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nothing is planned yet.',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This upcoming day still spans 12:00 AM to 11:59 PM. Add a task and it will land on the full-day timeline.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: onSurface.withValues(alpha: 0.62),
                              height: 1.4,
                            ),
                          ),
                          const Spacer(),
                          if (onAddTask != null)
                            _GapActionButton(
                              onPressed: onAddTask,
                              icon: const Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: _kTimelineGapAccent,
                              ),
                              label: 'Add Task',
                              labelStyle: const TextStyle(
                                color: _kTimelineGapAccent,
                                fontWeight: FontWeight.w700,
                              ),
                              side: BorderSide(
                                color: onSurface.withValues(alpha: 0.1),
                              ),
                              backgroundColor: theme.colorScheme.surface
                                  .withValues(alpha: 0.6),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: _kTimelineStatusSize + 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactTimelineMarker {
  final int minutes;
  final String label;

  const _CompactTimelineMarker(this.minutes, this.label);
}

class _GapActionState {
  final bool canAddTask;
  final bool canAddLog;
  final int taskStartMinutes;
  final int logStartMinutes;
  final int logEndMinutes;
  final int futureMinutes;

  const _GapActionState({
    required this.canAddTask,
    required this.canAddLog,
    required this.taskStartMinutes,
    required this.logStartMinutes,
    required this.logEndMinutes,
    required this.futureMinutes,
  });
}

// -- Block Card ----------------------------------------------------
/*
class _BlockCard extends StatelessWidget {
  final Block block;
  final Widget? leading;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onStatusTap;
  final double pastFraction;
  final double? nowLineOffset;
  final String nowLabel;
  final Color nowLineBackgroundColor;
  final Color nowLineBackgroundColor;

  const _BlockCard({
    required this.block,
    this.leading,
    this.onTap,
    this.onLongPress,
    this.onStatusTap,
    this.pastFraction = 0,
    this.nowLineOffset,
    required this.nowLabel,
    required this.nowLineBackgroundColor,
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
  final _TimelineBlockSlice slice;
  final Widget? leading;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onStatusTap;
  final VoidCallback? onAdjacentDateTap;
  final double pastFraction;
  final double? nowLineOffset;
  final String nowLabel;
  final Color nowLineBackgroundColor;

  const _BlockCard({
    required this.slice,
    this.leading,
    this.onTap,
    this.onLongPress,
    this.onStatusTap,
    this.onAdjacentDateTap,
    this.pastFraction = 0,
    this.nowLineOffset,
    required this.nowLabel,
    required this.nowLineBackgroundColor,
  });

  Block get block => slice.block;

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

  Widget _buildSinglePill({
    required double height,
    required Color backgroundColor,
    required Color borderColor,
    required Color accentColor,
    required Color iconColor,
  }) {
    return Container(
      width: _kTimelinePillWidth,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 6,
            top: 8,
            bottom: 8,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Center(
            child: Tooltip(
              message: _categoryLabel(block),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.14),
                ),
                child: Icon(
                  _iconForBlock(),
                  size: 18,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualTrackPills({
    required double cardHeight,
    required Color plannedColor,
    required Color actualColor,
    required Color labelColor,
    required Color actualLabelColor,
    required Color checkIconColor,
    required String plannedLabel,
    required String actualLabel,
    required double plannedHeight,
    required double actualHeight,
    required Color accentColor,
  }) {
    return SizedBox(
      width: 60,
      height: cardHeight,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  plannedLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  actualLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: actualLabelColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 28,
                      height: plannedHeight,
                      decoration: BoxDecoration(
                        color: plannedColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 28,
                      height: actualHeight,
                      decoration: BoxDecoration(
                        color: actualColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: checkIconColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator({
    required bool isDone,
    required Color ringColor,
    required Color doneColor,
    required Color checkColor,
  }) {
    final indicator = Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        width: _kTimelineStatusSize,
        height: _kTimelineStatusSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? doneColor : Colors.transparent,
          border: Border.all(
            color: isDone ? doneColor : ringColor,
            width: isDone ? 1.5 : 1.8,
          ),
        ),
        child: isDone
            ? Icon(
                Icons.check_rounded,
                size: 12,
                color: checkColor,
              )
            : null,
      ),
    );

    if (onStatusTap == null) return indicator;

    return GestureDetector(
      onTap: onStatusTap,
      behavior: HitTestBehavior.opaque,
      child: indicator,
    );
  }

  bool get _canManageExecution {
    if (slice.relation != _TimelineBlockRelation.sameDay) return false;
    if (block.isEvent || block.id.startsWith('prayer_')) return false;
    if (block.type == BlockType.breakBlock) return false;
    if (block.isAdHocTrack == true) return false;
    return true;
  }

  Widget? _buildExecutionControls(BuildContext context, Color accent) {
    if (!_canManageExecution) return null;

    final app = context.read<AppProvider>();
    final dateKey = block.date;
    if (dateKey.isEmpty) return null;

    Future<void> startAction() => app.startPlannedBlock(dateKey, block.id);
    Future<void> pauseAction() => app.pausePlannedBlock(dateKey, block.id);
    Future<void> stopAction() => app.stopPlannedBlock(dateKey, block.id);

    Widget actionChip({
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
      bool filled = false,
    }) {
      final backgroundColor = filled
          ? accent.withValues(alpha: 0.14)
          : Theme.of(context).colorScheme.surface.withValues(alpha: 0.85);
      return InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: accent.withValues(alpha: filled ? 0.25 : 0.14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      );
    }

    switch (block.status) {
      case BlockStatus.notStarted:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            actionChip(
              icon: Icons.play_arrow_rounded,
              label: 'Play',
              onPressed: () => startAction(),
              filled: true,
            ),
          ],
        );
      case BlockStatus.inProgress:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            actionChip(
              icon: Icons.pause_rounded,
              label: 'Pause',
              onPressed: () => pauseAction(),
            ),
            actionChip(
              icon: Icons.stop_rounded,
              label: 'Stop',
              onPressed: () => stopAction(),
              filled: true,
            ),
          ],
        );
      case BlockStatus.paused:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            actionChip(
              icon: Icons.play_arrow_rounded,
              label: 'Play',
              onPressed: () => startAction(),
            ),
            actionChip(
              icon: Icons.stop_rounded,
              label: 'Stop',
              onPressed: () => stopAction(),
              filled: true,
            ),
          ],
        );
      case BlockStatus.done:
      case BlockStatus.skipped:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final timeLabelColor =
        theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurfaceVariant;
    final accent = _baseBlockColor(block);
    final plannedDuration = slice.visibleDurationMinutes;
    final isDone = block.status == BlockStatus.done;
    final isSplit = block.splitTotalParts != null && block.splitTotalParts! > 1;
    final neutralPillColor = theme.colorScheme.surface.withValues(alpha: 0.78);
    final pillBorderColor = onSurface.withValues(alpha: isDone ? 0.1 : 0.08);
    final completedPillColor = accent.withValues(alpha: 0.16);
    final statusRingColor = isDone
        ? accent.withValues(alpha: 0.3)
        : onSurface.withValues(alpha: 0.2);
    final startLabel = slice.startLabel;
    final rangeLabel = slice.rangeLabel;
    final actualStartTime =
        _normalizeTimeValue(block.actualStartTime) ?? block.plannedStartTime;
    final actualEndTime = _normalizeTimeValue(block.actualEndTime);
    final hasDifferentActualRange = actualEndTime != null &&
        (actualStartTime != block.plannedStartTime ||
            actualEndTime != block.plannedEndTime);
    final showDualTrack = isDone && hasDifferentActualRange;
    final isCompactCard = plannedDuration <= 90 && !showDualTrack;
    final actualDuration = actualEndTime == null ||
            slice.relation != _TimelineBlockRelation.sameDay
        ? plannedDuration
        : _durationFromTimeRange(
            actualStartTime,
            actualEndTime,
            fallbackMinutes: plannedDuration,
          );
    final plannedTrackHeight =
        math.max(18.0, _scaledTimelineHeight(plannedDuration));
    final actualTrackHeight =
        math.max(18.0, _scaledTimelineHeight(actualDuration));
    final dualTrackHeight =
        math.max(plannedTrackHeight, actualTrackHeight) + 22;
    final baseCardMinHeight = showDualTrack ? 0.0 : 84.0;
    final cardHeight = showDualTrack
        ? math.max(_timelinePillHeight(plannedDuration), dualTrackHeight)
        : math.max(_timelinePillHeight(plannedDuration), baseCardMinHeight);
    final double? nowIndicatorTop = nowLineOffset == null
        ? null
        : (nowLineOffset! - (_kNowOverlayHeight / 2))
            .clamp(0.0, math.max(0.0, cardHeight - _kNowOverlayHeight))
            .toDouble();
    final plannedMetaLabel =
        'Planned: $rangeLabel • ${_formatDurationMetaLabel(plannedDuration)}';
    final actualDurationLabelMinutes =
        block.actualDurationMinutes ?? actualDuration;
    final actualMetaLabel = actualEndTime == null
        ? null
        : 'Actual: ${_to12h(actualStartTime)} - ${_to12h(actualEndTime)} • ${_formatDurationMetaLabel(actualDurationLabelMinutes)}';
    final executionControls = _buildExecutionControls(context, accent);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: cardHeight,
          child: Stack(
            children: [
              Row(
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: timeLabelColor,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: _kTimelineTimeToPillGap),
                  showDualTrack
                      ? _buildDualTrackPills(
                          cardHeight: cardHeight,
                          plannedColor:
                              theme.colorScheme.surface.withValues(alpha: 0.66),
                          actualColor: completedPillColor,
                          labelColor: onSurface.withValues(alpha: 0.52),
                          actualLabelColor: onSurfaceVariant,
                          checkIconColor: onSurface,
                          plannedLabel: _to12hShort(_minutesToHHMM(
                              slice.visibleEndMinutes % (24 * 60))),
                          actualLabel: _to12hShort(actualEndTime),
                          plannedHeight: plannedTrackHeight,
                          actualHeight: actualTrackHeight,
                          accentColor: accent,
                        )
                      : _buildSinglePill(
                          height: cardHeight,
                          backgroundColor: neutralPillColor,
                          borderColor: pillBorderColor,
                          accentColor: accent,
                          iconColor: accent,
                        ),
                  const SizedBox(width: _kTimelineContentGap),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: isCompactCard ? 0 : 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            block.title,
                            style: TextStyle(
                              fontSize: isCompactCard ? 14 : 16,
                              height: isCompactCard ? 1.0 : 1.12,
                              fontWeight: FontWeight.w700,
                              color: isDone
                                  ? onSurface.withValues(alpha: 0.68)
                                  : onSurface,
                            ),
                            maxLines: isCompactCard ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (block.isAdHocTrack == true) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Tracked',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: isCompactCard ? 1 : 4),
                          if (showDualTrack) ...[
                            Text(
                              plannedMetaLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: onSurface.withValues(alpha: 0.58),
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    actualMetaLabel!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: accent,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: accent,
                                ),
                              ],
                            ),
                          ] else
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$rangeLabel • ${_formatDurationMetaLabel(plannedDuration)}',
                                    style: TextStyle(
                                      fontSize: isCompactCard ? 11 : 13,
                                      fontWeight: FontWeight.w600,
                                      color: timeLabelColor,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ),
                                if (slice.adjacentActionLabel != null &&
                                    onAdjacentDateTap != null) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: onAdjacentDateTap,
                                    borderRadius: BorderRadius.circular(999),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: accent.withValues(alpha: 0.18),
                                        ),
                                      ),
                                      child: Text(
                                        slice.adjacentActionLabel!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          if (isSplit) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Part ${block.splitPartIndex} of ${block.splitTotalParts}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                          if (showDualTrack &&
                              slice.adjacentActionLabel != null &&
                              onAdjacentDateTap != null) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: onAdjacentDateTap,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Text(
                                  slice.adjacentActionLabel!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (executionControls != null) ...[
                            const SizedBox(height: 10),
                            executionControls,
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildStatusIndicator(
                    isDone: isDone,
                    ringColor: statusRingColor,
                    doneColor: completedPillColor,
                    checkColor: accent,
                  ),
                ],
              ),
              if (pastFraction > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: cardHeight * pastFraction,
                      color: onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              if (nowIndicatorTop != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: nowIndicatorTop,
                  child: _NowLineOverlay(
                    label: nowLabel,
                    backgroundColor: nowLineBackgroundColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NowLineOverlay extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const _NowLineOverlay({
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: _kNowOverlayHeight,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: (_kNowOverlayHeight / 2) - (_kNowLineThickness / 2),
              child: Container(
                height: _kNowLineThickness,
                color: _kTimelineAccent,
              ),
            ),
            Positioned(
              left: 0,
              top: (_kNowOverlayHeight - _kNowDotSize) / 2,
              child: SizedBox(
                width: _kNowDotSize,
                height: _kNowDotSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _kTimelineAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kTimelineAccent.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _kTimelineAccent.withValues(alpha: 0.14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: _kTimelineAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlapWarningRow extends StatelessWidget {
  final String message;

  const _OverlapWarningRow({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          const SizedBox(
            width: _kTimelineLeadingWidth +
                _kTimelineTimeWidth +
                _kTimelineTimeToPillGap +
                _kTimelinePillWidth +
                _kTimelineContentGap,
          ),
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: _kTimelineAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: _kTimelineAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: _kTimelineStatusSize + 10),
        ],
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
  final VoidCallback? onAddLog;
  final int futureDurationMinutes;
  final bool showPastPrompt;
  final double? nowLineOffset;
  final String nowLabel;

  const _GapSlot({
    required this.startMinutes,
    required this.endMinutes,
    required this.onTap,
    this.onAddTask,
    this.onAddLog,
    this.futureDurationMinutes = 0,
    this.showPastPrompt = false,
    this.nowLineOffset,
    required this.nowLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final timeLabelColor =
        theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurfaceVariant;
    final sectionSurface = theme.colorScheme.surface.withValues(alpha: 0.3);
    final gapMinutes = endMinutes - startMinutes;
    final hasPastSection = showPastPrompt;
    final hasFutureSection = onAddTask != null;
    final gapHeight = _gapSlotHeight(
      gapMinutes,
      hasPastSection: hasPastSection,
      hasFutureSection: hasFutureSection,
    );

    final hourTicks = <int>[];
    final firstHourInGap = (startMinutes ~/ 60) * 60 + 60;
    for (int tick = firstHourInGap; tick < endMinutes; tick += 60) {
      hourTicks.add(tick);
    }

    final startLabel = _to12hShort(_minutesToHHMM(startMinutes));
    final durationLabel = _formatGapDurationCompact(gapMinutes);
    final gapRangeLabel =
        '${_to12h(_minutesToHHMM(startMinutes))} - ${_to12h(_minutesToHHMM(endMinutes))} • $durationLabel';
    final futureLabel = _formatGapDurationCompact(
      futureDurationMinutes > 0 ? futureDurationMinutes : gapMinutes,
    );
    final double? nowIndicatorTop = nowLineOffset == null
        ? null
        : (nowLineOffset! - (_kNowOverlayHeight / 2))
            .clamp(0.0, math.max(0.0, gapHeight - _kNowOverlayHeight))
            .toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: gapHeight),
          child: SizedBox(
            height: gapHeight,
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(width: _kTimelineLeadingWidth),
                    SizedBox(
                      width: _kTimelineTimeWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: _kGapRowVerticalPadding,
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Text(
                                startLabel,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: timeLabelColor,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            ...hourTicks.map((tick) {
                              final fraction =
                                  (tick - startMinutes) / gapMinutes;
                              final topPos = fraction *
                                  (gapHeight - (_kGapRowVerticalPadding * 2));
                              return Positioned(
                                top: topPos - 6,
                                right: 0,
                                child: Text(
                                  _to12hShort(_minutesToHHMM(tick)),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: timeLabelColor,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: _kTimelineTimeToPillGap),
                    SizedBox(
                      width: _kTimelinePillWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: _kGapRowVerticalPadding,
                        ),
                        child: Center(
                          child: CustomPaint(
                            size: Size(
                              2,
                              gapHeight - (_kGapRowVerticalPadding * 2),
                            ),
                            painter: _DashedLinePainter(
                              color: theme.dividerColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: _kTimelineContentGap),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _kGapRowHorizontalPadding,
                          vertical: _kGapRowVerticalPadding,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: sectionSurface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasPastSection) ...[
                                  _GapHintRow(
                                    icon: Icons.edit_note_rounded,
                                    iconColor:
                                        onSurface.withValues(alpha: 0.42),
                                    child: Text(
                                      'What did you do here?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            onSurface.withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    gapRangeLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: onSurface.withValues(alpha: 0.55),
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  if (onAddLog != null) ...[
                                    const SizedBox(
                                      height: _kGapPromptToButtonSpacing,
                                    ),
                                    _GapActionButton(
                                      onPressed: onAddLog,
                                      icon: Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                        color:
                                            onSurface.withValues(alpha: 0.56),
                                      ),
                                      label: 'Add Log',
                                      labelStyle: TextStyle(
                                        color:
                                            onSurface.withValues(alpha: 0.72),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      side: BorderSide(
                                        color:
                                            onSurface.withValues(alpha: 0.14),
                                      ),
                                      backgroundColor: theme.colorScheme.surface
                                          .withValues(alpha: 0.54),
                                    ),
                                  ],
                                  if (hasFutureSection) ...[
                                    const SizedBox(
                                      height: _kGapButtonToDividerSpacing,
                                    ),
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: onSurface.withValues(alpha: 0.08),
                                    ),
                                    const SizedBox(
                                      height: _kGapDividerToFutureSpacing,
                                    ),
                                  ] else
                                    const SizedBox(
                                      height: _kGapSectionBottomSpacing,
                                    ),
                                ],
                                if (hasFutureSection) ...[
                                  _GapHintRow(
                                    icon: Icons.access_time_outlined,
                                    iconColor: _kTimelineAccent.withValues(
                                        alpha: 0.88),
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              onSurface.withValues(alpha: 0.72),
                                          height: 1.35,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Use '),
                                          TextSpan(
                                            text: futureLabel,
                                            style: const TextStyle(
                                              color: _kTimelineGapAccent,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          TextSpan(
                                            text: hasPastSection
                                                ? ' from here onward'
                                                : ' wisely...',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: _kGapFutureToButtonSpacing,
                                  ),
                                  _GapActionButton(
                                    onPressed: onAddTask,
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 16,
                                      color: _kTimelineGapAccent,
                                    ),
                                    label: 'Add Task',
                                    labelStyle: const TextStyle(
                                      color: _kTimelineGapAccent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    side: BorderSide(
                                      color: onSurface.withValues(alpha: 0.14),
                                    ),
                                    backgroundColor: theme.colorScheme.surface
                                        .withValues(alpha: 0.54),
                                  ),
                                  const SizedBox(
                                    height: _kGapSectionBottomSpacing,
                                  ),
                                ],
                                if (!hasPastSection && !hasFutureSection)
                                  Text(
                                    durationLabel,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: onSurface.withValues(alpha: 0.45),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: _kTimelineStatusSize + 10),
                  ],
                ),
                if (nowIndicatorTop != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: nowIndicatorTop,
                    child: IgnorePointer(
                      child: _NowLineOverlay(
                        label: nowLabel,
                        backgroundColor:
                            theme.colorScheme.surface.withValues(alpha: 0.96),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GapHintRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _GapHintRow({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

class _GapActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final TextStyle labelStyle;
  final BorderSide side;
  final Color backgroundColor;

  const _GapActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.labelStyle,
    required this.side,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kGapButtonHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label, style: labelStyle),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, _kGapButtonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: _kGapButtonHorizontalPadding,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          backgroundColor: backgroundColor,
          side: side,
          shape: const StadiumBorder(),
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
