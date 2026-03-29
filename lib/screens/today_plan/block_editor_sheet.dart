import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/services/task_suggestions_service.dart';
import 'package:focusflow_mobile/utils/constants.dart';

import 'alert_repeat_sheet.dart';
import 'time_picker_sheet.dart';

class BlockEditorUpdate {
  final String dateKey;
  final String title;
  final String? description;
  final String plannedStartTime;
  final String plannedEndTime;
  final int plannedDurationMinutes;
  final bool isEvent;
  final BlockType type;

  const BlockEditorUpdate({
    required this.dateKey,
    required this.title,
    required this.description,
    required this.plannedStartTime,
    required this.plannedEndTime,
    required this.plannedDurationMinutes,
    required this.isEvent,
    required this.type,
  });
}

class BlockEditorSheet extends StatefulWidget {
  final Block block;
  final Future<void> Function(BlockEditorUpdate update) onSave;
  final VoidCallback onDelete;

  const BlockEditorSheet({
    super.key,
    required this.block,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<BlockEditorSheet> createState() => _BlockEditorSheetState();
}

class _BlockEditorSheetState extends State<BlockEditorSheet> {
  static const _bodyColor = Color(0xFF1C1C1E);
  static const _cardColor = Color(0xFF252528);
  static const _accentColor = Color(0xFFFF8E88);
  static const _defaultHeaderColor = Color(0xFFD77A78);
  static const _emojiOptions = <String>[
    '📚',
    '📝',
    '🎯',
    '✅',
    '🧠',
    '📖',
    '💼',
    '🍽️',
    '🚶',
    '🧹',
    '🛒',
    '⚡',
  ];
  static const _headerChoices = <Color>[
    _defaultHeaderColor,
    Color(0xFF4A90D9),
    Color(0xFF5856D6),
    Color(0xFF30D158),
    Color(0xFFFF9F0A),
    Color(0xFFBF5AF2),
    Color(0xFFFF6B6B),
    Color(0xFF1C1C1E),
    Color(0xFFE8837A),
    Color(0xFF7A89D7),
    Color(0xFF6FB89E),
    Color(0xFFDAA768),
    Color(0xFF8E78D4),
    Color(0xFF6D7A86),
  ];
  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedStartTime;
  late int _durationMinutes;
  late bool _isEvent;
  late BlockType _selectedType;
  late String _selectedEmoji;
  late String _colorHex;
  late int _alertOffsetMinutes;
  late String _alertType;
  late String _recurrenceType;
  late List<int> _recurrenceDays;

  bool _isSaving = false;
  bool _userChangedEmoji = false;
  bool _userChangedColor = false;
  Color _headerColor = _defaultHeaderColor;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.tryParse(widget.block.date) ?? DateTime.now();
    _selectedStartTime = _parseTime(widget.block.plannedStartTime) ??
        const TimeOfDay(hour: 8, minute: 0);
    _durationMinutes = _resolvedDuration(widget.block);
    _isEvent = widget.block.isEvent;
    _selectedType = widget.block.type;
    _selectedEmoji =
        _leadingEmoji(widget.block.title) ?? _defaultEmoji(widget.block);
    _colorHex = _hexFromColor(_headerColor);
    _alertOffsetMinutes = -1;
    _alertType = 'nudge';
    _recurrenceType = 'none';
    _recurrenceDays = <int>[];
    _titleController =
        TextEditingController(text: _stripLeadingEmoji(widget.block.title));
    _notesController =
        TextEditingController(text: widget.block.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _resolvedDuration(Block block) {
    if (block.plannedDurationMinutes > 0) return block.plannedDurationMinutes;
    final start = _minutes(block.plannedStartTime);
    final end = _minutes(block.plannedEndTime);
    return end > start ? end - start : 90;
  }

  int _minutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  TimeOfDay? _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _toHhmm(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  TimeOfDay _addMinutes(TimeOfDay start, int duration) {
    final total = (start.hour * 60 + start.minute + duration) % (24 * 60);
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  String _formatTime(TimeOfDay time) {
    final suffix = time.hour < 12 ? 'AM' : 'PM';
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '$hour12:${time.minute.toString().padLeft(2, '0')} $suffix';
  }

  String _formatRange(TimeOfDay start, int duration) {
    final end = _addMinutes(start, duration);
    final startText = _formatTime(start);
    final endText = _formatTime(end);
    final startSuffix = start.hour < 12 ? 'AM' : 'PM';
    final endSuffix = end.hour < 12 ? 'AM' : 'PM';
    if (startSuffix == endSuffix) {
      return '${startText.replaceAll(' $startSuffix', '')} – $endText';
    }
    return '$startText – $endText';
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours > 0 && remainder > 0) return '$hours hr, $remainder min';
    if (hours > 0) return hours == 1 ? '1 hr' : '$hours hr';
    return '$minutes min';
  }

  String _relativeDateLabel(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(value.year, value.month, value.day);
    if (date == today) return 'Today';
    if (date == tomorrow) return 'Tomorrow';
    return '';
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  String? _leadingEmoji(String title) {
    final token = RegExp(r'^(\S+)\s+').firstMatch(title.trim())?.group(1);
    if (token == null || RegExp(r'^[A-Za-z0-9]+$').hasMatch(token)) return null;
    return token;
  }

  String _stripLeadingEmoji(String title) {
    final emoji = _leadingEmoji(title);
    if (emoji == null) return title.trim();
    return title.trim().replaceFirst('$emoji ', '').trim();
  }

  String _defaultEmoji(Block block) {
    if (block.isEvent) return '📍';
    switch (block.type) {
      case BlockType.revisionFa:
      case BlockType.studySession:
      case BlockType.fmgeRevision:
        return '📚';
      case BlockType.video:
        return '🎬';
      case BlockType.qbank:
        return '📝';
      case BlockType.anki:
        return '🧠';
      case BlockType.breakBlock:
        return '☕';
      case BlockType.mixed:
        return '⚡';
      case BlockType.other:
        return '✅';
    }
  }

  String _composeTitle() {
    final plain = _titleController.text.trim();
    final fallback = _stripLeadingEmoji(widget.block.title);
    return '$_selectedEmoji ${plain.isEmpty ? fallback : plain}'.trim();
  }

  Color _colorFromHex(String colorHex) {
    final sanitized = colorHex.replaceAll('#', '').trim();
    if (sanitized.length != 6) {
      return _defaultHeaderColor;
    }
    final value = int.tryParse('FF$sanitized', radix: 16);
    if (value == null) {
      return _defaultHeaderColor;
    }
    return Color(value);
  }

  String _hexFromColor(Color color) {
    final value = color.toARGB32() & 0x00FFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  String _statusLabel(BlockStatus status) {
    switch (status) {
      case BlockStatus.notStarted:
        return 'Not started';
      case BlockStatus.inProgress:
        return 'In progress';
      case BlockStatus.paused:
        return 'Paused';
      case BlockStatus.done:
        return 'Done';
      case BlockStatus.skipped:
        return 'Skipped';
    }
  }

  String _typeLabel(BlockType type) {
    switch (type) {
      case BlockType.video:
        return 'Video';
      case BlockType.revisionFa:
        return 'Revision FA';
      case BlockType.anki:
        return 'Anki';
      case BlockType.qbank:
        return 'Qbank';
      case BlockType.studySession:
        return 'Study Session';
      case BlockType.breakBlock:
        return 'Break';
      case BlockType.other:
        return 'Other';
      case BlockType.mixed:
        return 'Mixed';
      case BlockType.fmgeRevision:
        return 'FMGE Revision';
    }
  }

  Future<void> _pickEmoji() async {
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardColor,
        title:
            const Text('Choose emoji', style: TextStyle(color: Colors.white)),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final emoji in _emojiOptions)
              InkWell(
                onTap: () => Navigator.of(dialogContext).pop(emoji),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
          ],
        ),
      ),
    );
    if (value != null && mounted) {
      setState(() {
        _userChangedEmoji = true;
        _selectedEmoji = value;
      });
    }
  }

  Future<void> _pickHeaderColor() async {
    final value = await showModalBottomSheet<Color>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.of(sheetContext).padding.bottom + 18,
        ),
        decoration: const BoxDecoration(
          color: _bodyColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sheet accent',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'This affects the editor only. Blocks do not have a persisted color field.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), height: 1.4),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in _headerChoices)
                  InkWell(
                    onTap: () => Navigator.of(sheetContext).pop(color),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.75),
                          width: _colorHex == _hexFromColor(color) ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (value != null && mounted) {
      setState(() {
        _userChangedColor = true;
        _headerColor = value;
        _colorHex = _hexFromColor(value);
      });
    }
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (value != null && mounted) setState(() => _selectedDate = value);
  }

  Future<void> _pickTime() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TimePickerSheet(
        headerColor: _headerColor,
        title: _titleController.text.trim().isEmpty
            ? _stripLeadingEmoji(widget.block.title)
            : _titleController.text.trim(),
        emoji: _selectedEmoji,
        initialStartTime: _toHhmm(_selectedStartTime),
        initialDurationMinutes: _durationMinutes,
      ),
    );
    if (result == null || !mounted) return;
    final startTime = result['startTime'] as String?;
    final duration = result['durationMinutes'] as int?;
    if (startTime == null || duration == null) return;
    setState(() {
      _selectedStartTime = _parseTime(startTime) ?? _selectedStartTime;
      _durationMinutes = duration;
    });
  }

  Future<void> _openAlertRepeatSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AlertRepeatSheet(
        initialAlertOffset: _alertOffsetMinutes,
        initialAlertType: _alertType,
        initialRecurrenceType: _recurrenceType,
        initialRecurrenceDays: _recurrenceDays,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _alertOffsetMinutes =
          result['alertOffsetMinutes'] as int? ?? _alertOffsetMinutes;
      _alertType = result['alertType'] as String? ?? _alertType;
      _recurrenceType = result['recurrenceType'] as String? ?? _recurrenceType;
      _recurrenceDays = List<int>.from(
          result['recurrenceDays'] as List<dynamic>? ?? _recurrenceDays)
        ..sort();
    });
  }

  String _alertOffsetLabel(int value) {
    switch (value) {
      case -1:
        return 'None';
      case 0:
        return 'At time of task';
      case -5:
        return '5 min before';
      case -10:
        return '10 min before';
      case -15:
        return '15 min before';
      case -30:
        return '30 min before';
      case -60:
        return '1 hr before';
      default:
        return '${value.abs()} min before';
    }
  }

  String _alertTypeLabel(String value) {
    switch (value) {
      case 'notification':
        return 'Notification';
      case 'alarm':
        return 'Alarm';
      case 'nudge':
      default:
        return 'Nudge';
    }
  }

  String _recurrenceTypeLabel(String value) {
    switch (value) {
      case 'daily':
        return 'Every day';
      case 'weekly':
        return 'Every week';
      case 'monthly':
        return 'Every month';
      case 'yearly':
        return 'Every year';
      case 'none':
      default:
        return 'None';
    }
  }

  String _alertRowSummary() {
    if (_alertOffsetMinutes == -1) return 'None';
    return '${_alertOffsetLabel(_alertOffsetMinutes)}  •  ${_alertTypeLabel(_alertType)}';
  }

  String _repeatRowSummary() {
    if (_recurrenceType != 'weekly')
      return _recurrenceTypeLabel(_recurrenceType);
    final labels = _recurrenceDays
        .where((day) => day >= 0 && day < _weekdayLabels.length)
        .map((day) => _weekdayLabels[day])
        .toList(growable: false);
    if (labels.isEmpty) return 'Every week';
    return 'Every week  •  ${labels.join(', ')}';
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final end = _addMinutes(_selectedStartTime, _durationMinutes);
      await widget.onSave(
        BlockEditorUpdate(
          dateKey: _dateKey(_selectedDate),
          title: _composeTitle(),
          description: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          plannedStartTime: _toHhmm(_selectedStartTime),
          plannedEndTime: _toHhmm(end),
          plannedDurationMinutes: _durationMinutes,
          isEvent: _isEvent,
          type: _selectedType,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = _formatRange(_selectedStartTime, _durationMinutes);
    final durationLabel = _formatDuration(_durationMinutes);
    final dateLabel = DateFormat('EEE, MMM d, yyyy').format(_selectedDate);
    final relativeLabel = _relativeDateLabel(_selectedDate);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 20;

    return FractionallySizedBox(
      heightFactor: 0.96,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          child: Material(
            color: _bodyColor,
            child: Column(
              children: [
                Container(
                  color: _headerColor,
                  padding: EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    MediaQuery.of(context).padding.top + 18,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _CircleIconButton(
                            icon: Icons.close_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          _StatusRing(status: widget.block.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          InkWell(
                            onTap: _pickEmoji,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                color: const Color(0xFF49494D),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                              alignment: Alignment.center,
                              child: Text(_selectedEmoji,
                                  style: const TextStyle(fontSize: 34)),
                            ),
                          ),
                          Positioned(
                            bottom: -10,
                            child: Material(
                              color: _accentColor,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: _pickHeaderColor,
                                customBorder: const CircleBorder(),
                                child: const SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: Icon(Icons.palette_outlined,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '$timeLabel ($durationLabel)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _titleController,
                        scrollPadding: const EdgeInsets.only(bottom: 24),
                        onChanged: (value) {
                          final suggestion =
                              TaskSuggestionsService.suggest(value);
                          setState(() {
                            if (!_userChangedEmoji) {
                              _selectedEmoji = suggestion.emoji;
                            }
                            if (!_userChangedColor) {
                              _colorHex = suggestion.colorHex;
                              _headerColor = _colorFromHex(suggestion.colorHex);
                            }
                            _selectedType = suggestion.category;
                          });
                        },
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                        cursorColor: Colors.white,
                        decoration: const InputDecoration(
                          hintText: 'Task title',
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54)),
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Card(
                          children: [
                            _ActionRow(
                              icon: Icons.calendar_today_rounded,
                              iconColor: _accentColor,
                              title: dateLabel,
                              trailing: relativeLabel,
                              onTap: _pickDate,
                            ),
                            _ActionRow(
                              icon: Icons.access_time_filled_rounded,
                              iconColor: _accentColor,
                              title: timeLabel,
                              trailing: durationLabel,
                              onTap: _pickTime,
                            ),
                            _ActionRow(
                              icon: Icons.notifications_rounded,
                              iconColor: const Color(0xFFB78A88),
                              title: 'Alert',
                              trailing: _alertRowSummary(),
                              onTap: _openAlertRepeatSheet,
                            ),
                            _ActionRow(
                              icon: Icons.repeat_rounded,
                              iconColor: const Color(0xFFB78A88),
                              title: 'Repeat',
                              trailing: _repeatRowSummary(),
                              onTap: _openAlertRepeatSheet,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _Card(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 12),
                              child: Row(
                                children: [
                                  Icon(Icons.event_rounded,
                                      color:
                                          Colors.white.withValues(alpha: 0.75)),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Fixed Event',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: _isEvent,
                                    onChanged: (value) =>
                                        setState(() => _isEvent = value),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Divider(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              child: Row(
                                children: [
                                  Icon(Icons.category_outlined,
                                      color:
                                          Colors.white.withValues(alpha: 0.75)),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Block Type',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<BlockType>(
                                        value: _selectedType,
                                        dropdownColor: _cardColor,
                                        iconEnabledColor: Colors.white70,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        onChanged: (value) {
                                          if (value != null)
                                            setState(
                                                () => _selectedType = value);
                                        },
                                        items: BlockType.values
                                            .map((type) =>
                                                DropdownMenuItem<BlockType>(
                                                  value: type,
                                                  child: Text(_typeLabel(type)),
                                                ))
                                            .toList(growable: false),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Divider(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 16),
                              child: Row(
                                children: [
                                  Icon(Icons.radio_button_unchecked_rounded,
                                      color:
                                          Colors.white.withValues(alpha: 0.75)),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Status',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _statusLabel(widget.block.status),
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextButton(
                          onPressed: widget.onDelete,
                          child: const Text(
                            'Delete Block',
                            style: TextStyle(
                              color: _accentColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onPressed: _isSaving ? null : _save,
                            child:
                                Text(_isSaving ? 'Saving...' : 'Save Changes'),
                          ),
                        ),
                      ],
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _StatusRing extends StatelessWidget {
  final BlockStatus status;

  const _StatusRing({required this.status});

  @override
  Widget build(BuildContext context) {
    final filled = status == BlockStatus.done;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: filled
          ? Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white),
            )
          : null,
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;

  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252528),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: children),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String trailing;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailing.isNotEmpty)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    trailing,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.56),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.45)),
          ],
        ),
      ),
    );
  }
}
