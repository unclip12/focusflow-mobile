// =============================================================
// RoutineEditorSheet - Create / edit routines
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:focusflow_mobile/models/routine.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';

class RoutineEditorSheet extends StatefulWidget {
  final Routine? existing;

  const RoutineEditorSheet({super.key, this.existing});

  @override
  State<RoutineEditorSheet> createState() => _RoutineEditorSheetState();
}

class _RoutineEditorSheetState extends State<RoutineEditorSheet> {
  static const _defaultSubtaskEmoji = '\u{1F4CC}';

  final _nameCtrl = TextEditingController();
  final _uuid = const Uuid();
  final Map<String, TextEditingController> _subtaskNameCtrls = {};
  final Map<String, TextEditingController> _subtaskEmojiCtrls = {};

  String _icon = '\u{1F305}';
  int _color = 0xFF6366F1;
  List<RoutineStep> _steps = [];
  List<RoutineSubtask> _subtasks = [];
  String? _reminderTime;
  String _recurrence = 'daily';
  String? _recurrenceEndDate;
  int? _reminderWeekday;
  String _recurrenceType = 'none';
  List<int> _recurrenceDays = [];
  String? _expandedEmojiEditorId;

  static const _icons = [
    '\u{1F305}',
    '\u{1F319}',
    '\u{1F3CB}\u{FE0F}',
    '\u{1F9D8}',
    '\u{1F37D}\u{FE0F}',
    '\u{1F4DA}',
    '\u{1F6C1}',
    '\u{1F3AF}',
    '\u{1F4BC}',
    '\u{1F504}',
  ];
  static const _colors = [
    0xFF6366F1,
    0xFF10B981,
    0xFF8B5CF6,
    0xFFF59E0B,
    0xFFEC4899,
    0xFF14B8A6,
    0xFFF97316,
    0xFF3B82F6,
  ];
  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const _weekdayToggleLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing == null) return;

    _nameCtrl.text = existing.name;
    _icon = existing.icon;
    _color = existing.color;
    _steps = List<RoutineStep>.from(existing.steps);
    _subtasks = List<RoutineSubtask>.from(existing.subtasks);
    _reminderTime = existing.reminderTime;
    _recurrence = existing.recurrence ?? 'daily';
    _recurrenceEndDate = existing.recurrenceEndDate;
    _reminderWeekday = existing.reminderWeekday;
    _recurrenceType = existing.recurrenceType;
    _recurrenceDays = List<int>.from(existing.recurrenceDays);

    for (final subtask in _subtasks) {
      _ensureSubtaskControllers(subtask);
    }

    if (_reminderTime != null &&
        _recurrence == 'weekly' &&
        (_reminderWeekday == null ||
            _reminderWeekday! < 1 ||
            _reminderWeekday! > 7)) {
      _reminderWeekday = DateTime.now().weekday;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final controller in _subtaskNameCtrls.values) {
      controller.dispose();
    }
    for (final controller in _subtaskEmojiCtrls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _ensureSubtaskControllers(RoutineSubtask subtask) {
    _subtaskNameCtrls.putIfAbsent(
      subtask.id,
      () => TextEditingController(text: subtask.name),
    );
    _subtaskEmojiCtrls.putIfAbsent(
      subtask.id,
      () => TextEditingController(text: subtask.emoji),
    );
  }

  void _disposeSubtaskControllers(String id) {
    _subtaskNameCtrls.remove(id)?.dispose();
    _subtaskEmojiCtrls.remove(id)?.dispose();
  }

  void _updateSubtask(
    String id, {
    String? name,
    String? emoji,
    int? durationMinutes,
  }) {
    final index = _subtasks.indexWhere((subtask) => subtask.id == id);
    if (index == -1) return;

    setState(() {
      _subtasks[index] = _subtasks[index].copyWith(
        name: name,
        emoji: emoji,
        durationMinutes: durationMinutes,
      );
    });
  }

  void _addSubtask() {
    final subtask = RoutineSubtask(
      id: _uuid.v4(),
      name: '',
      emoji: _defaultSubtaskEmoji,
      durationMinutes: 0,
    );
    _ensureSubtaskControllers(subtask);

    setState(() {
      _subtasks.add(subtask);
      _expandedEmojiEditorId = subtask.id;
    });
  }

  void _removeSubtask(String id) {
    setState(() {
      _subtasks.removeWhere((subtask) => subtask.id == id);
      if (_expandedEmojiEditorId == id) {
        _expandedEmojiEditorId = null;
      }
    });
    _disposeSubtaskControllers(id);
  }

  void _changeSubtaskDuration(String id, int deltaMinutes) {
    final index = _subtasks.indexWhere((subtask) => subtask.id == id);
    if (index == -1) return;

    final updated =
        (_subtasks[index].durationMinutes + deltaMinutes).clamp(0, 24 * 60);
    _updateSubtask(id, durationMinutes: updated);
  }

  void _toggleRecurrenceDay(int weekday) {
    setState(() {
      if (_recurrenceDays.contains(weekday)) {
        _recurrenceDays.remove(weekday);
      } else {
        _recurrenceDays = [..._recurrenceDays, weekday]..sort();
      }
    });
  }

  int get _totalSubtaskMinutes =>
      _subtasks.fold(0, (sum, subtask) => sum + subtask.durationMinutes);

  TimeOfDay? _parseReminderTime(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatReminderTime(String hhmm) {
    final time = _parseReminderTime(hhmm);
    return time?.format(context) ?? hhmm;
  }

  String _encodeTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime? _parseStoredDate(String? ymd) {
    if (ymd == null || ymd.isEmpty) return null;
    final parsed = DateTime.tryParse(ymd);
    if (parsed == null) return null;
    return _dateOnly(parsed);
  }

  String _encodeDate(DateTime date) {
    final safeDate = _dateOnly(date);
    final month = safeDate.month.toString().padLeft(2, '0');
    final day = safeDate.day.toString().padLeft(2, '0');
    return '${safeDate.year}-$month-$day';
  }

  String _formatReminderEndDate(String ymd) {
    final date = _parseStoredDate(ymd);
    if (date == null) return ymd;
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _formatMinutesLabel(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}min';
    if (hours > 0) return '${hours}h';
    return '${minutes}min';
  }

  void _clearReminder() {
    setState(() {
      _reminderTime = null;
      _recurrence = 'daily';
      _recurrenceEndDate = null;
      _reminderWeekday = null;
    });
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseReminderTime(_reminderTime) ?? TimeOfDay.now(),
    );
    if (picked == null) return;

    setState(() {
      _reminderTime = _encodeTime(picked);
      if (_recurrence == 'weekly') {
        _reminderWeekday ??= DateTime.now().weekday;
      }
      if (_recurrence == 'until_date') {
        _recurrenceEndDate ??= _encodeDate(DateTime.now());
      }
    });
  }

  void _setRecurrence(String recurrence) {
    setState(() {
      _recurrence = recurrence;
      switch (recurrence) {
        case 'weekly':
          _reminderWeekday ??= DateTime.now().weekday;
          _recurrenceEndDate = null;
          break;
        case 'until_date':
          _recurrenceEndDate ??= _encodeDate(DateTime.now());
          _reminderWeekday = null;
          break;
        default:
          _recurrenceEndDate = null;
          _reminderWeekday = null;
      }
    });
  }

  Future<void> _pickRecurrenceEndDate() async {
    final today = _dateOnly(DateTime.now());
    final selected = _parseStoredDate(_recurrenceEndDate);
    final picked = await showDatePicker(
      context: context,
      initialDate:
          selected != null && !selected.isBefore(today) ? selected : today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
    );
    if (picked == null) return;

    setState(() {
      _recurrenceEndDate = _encodeDate(picked);
    });
  }

  void _addStep() {
    final ctrl = TextEditingController();
    final durCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Step'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Step title',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: durCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Estimated minutes (optional)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  _steps.add(
                    RoutineStep(
                      id: _uuid.v4(),
                      title: ctrl.text.trim(),
                      estimatedMinutes: int.tryParse(durCtrl.text),
                      sortOrder: _steps.length,
                    ),
                  );
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;

    final app = context.read<AppProvider>();
    final now = DateTime.now().toIso8601String();
    final reminderTime = _reminderTime;
    final sanitizedSubtasks = _subtasks
        .map((subtask) {
          final emojiText = _subtaskEmojiCtrls[subtask.id]?.text.trim() ?? '';
          return subtask.copyWith(
            name: _subtaskNameCtrls[subtask.id]?.text.trim() ?? subtask.name,
            emoji: emojiText.isNotEmpty ? emojiText : _defaultSubtaskEmoji,
            durationMinutes: subtask.durationMinutes.clamp(0, 24 * 60),
          );
        })
        .where((subtask) => subtask.name.trim().isNotEmpty)
        .toList();
    final recurrenceDays =
        _recurrenceType == 'weekly' ? ([..._recurrenceDays]..sort()) : <int>[];

    String? recurrence;
    String? recurrenceEndDate;
    int? reminderWeekday;

    if (reminderTime != null) {
      switch (_recurrence) {
        case 'weekly':
          recurrence = 'weekly';
          reminderWeekday = _reminderWeekday ?? DateTime.now().weekday;
          break;
        case 'until_date':
          recurrence = 'until_date';
          recurrenceEndDate = _recurrenceEndDate ?? _encodeDate(DateTime.now());
          break;
        default:
          recurrence = 'daily';
      }
    }

    final baseRoutine = widget.existing ??
        Routine(
          id: _uuid.v4(),
          name: '',
          icon: _icon,
          color: _color,
          steps: const [],
          createdAt: now,
        );

    final routine = baseRoutine.copyWith(
      name: _nameCtrl.text.trim(),
      icon: _icon,
      color: _color,
      steps: _steps
          .asMap()
          .entries
          .map((entry) => entry.value.copyWith(sortOrder: entry.key))
          .toList(),
      reminderTime: reminderTime,
      recurrence: recurrence,
      recurrenceEndDate: recurrenceEndDate,
      reminderWeekday: reminderWeekday,
      recurrenceType: _recurrenceType,
      recurrenceDays: recurrenceDays,
      subtasks: sanitizedSubtasks,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    await app.upsertRoutine(routine);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _buildReminderCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _pickReminderTime,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.alarm_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminder',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _reminderTime == null
                              ? 'No reminder'
                              : 'Tap to change time',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _reminderTime == null
                        ? 'No reminder'
                        : _formatReminderTime(_reminderTime!),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _reminderTime == null
                          ? cs.onSurface.withValues(alpha: 0.5)
                          : cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_reminderTime != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearReminder,
                icon: const Icon(Icons.notifications_off_outlined, size: 16),
                label: const Text('Off'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReminderRepeatCard(ColorScheme cs) {
    if (_reminderTime == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repeat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<String>(value: 'daily', label: Text('Daily')),
              ButtonSegment<String>(value: 'weekly', label: Text('Weekly')),
              ButtonSegment<String>(
                value: 'until_date',
                label: Text('Until Date'),
              ),
            ],
            selected: {_recurrence},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              _setRecurrence(selection.first);
            },
          ),
          if (_recurrence == 'weekly') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<Widget>.generate(_weekdayLabels.length, (index) {
                final weekday = index + 1;
                return ChoiceChip(
                  label: Text(_weekdayLabels[index]),
                  selected: _reminderWeekday == weekday,
                  onSelected: (_) {
                    setState(() {
                      _reminderWeekday = weekday;
                    });
                  },
                );
              }),
            ),
          ],
          if (_recurrence == 'until_date') ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickRecurrenceEndDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_rounded, size: 18, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _recurrenceEndDate == null
                            ? 'Select end date'
                            : _formatReminderEndDate(_recurrenceEndDate!),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Steps',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${_steps.length})',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addStep,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Step', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        if (_steps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                'Tap "Add Step" to create routine steps',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _steps.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final step = _steps.removeAt(oldIndex);
                _steps.insert(newIndex, step);
              });
            },
            itemBuilder: (context, index) {
              final step = _steps[index];
              return ListTile(
                key: Key(step.id),
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(_color).withValues(alpha: 0.15),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(_color),
                    ),
                  ),
                ),
                title: Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: step.estimatedMinutes != null
                    ? Text(
                        '~${step.estimatedMinutes} min',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: cs.error.withValues(alpha: 0.6),
                      ),
                      onPressed: () => setState(() => _steps.removeAt(index)),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle_rounded,
                        size: 18,
                        color: cs.onSurface.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
                dense: true,
              );
            },
          ),
      ],
    );
  }

  Widget _buildDurationStepper(ColorScheme cs, RoutineSubtask subtask) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: subtask.durationMinutes <= 0
                ? null
                : () => _changeSubtaskDuration(subtask.id, -5),
            icon: const Icon(Icons.remove_rounded, size: 16),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
          ),
          SizedBox(
            width: 34,
            child: Text(
              '${subtask.durationMinutes}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _changeSubtaskDuration(subtask.id, 5),
            icon: const Icon(Icons.add_rounded, size: 16),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSubtasksSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subtasks',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        if (_subtasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'No subtasks yet.',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _subtasks.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final subtask = _subtasks.removeAt(oldIndex);
                _subtasks.insert(newIndex, subtask);
              });
            },
            itemBuilder: (context, index) {
              final subtask = _subtasks[index];
              _ensureSubtaskControllers(subtask);
              final nameCtrl = _subtaskNameCtrls[subtask.id]!;
              final emojiCtrl = _subtaskEmojiCtrls[subtask.id]!;
              final emojiLabel = subtask.emoji.trim().isEmpty
                  ? _defaultSubtaskEmoji
                  : subtask.emoji;
              final isEmojiEditorOpen = _expandedEmojiEditorId == subtask.id;

              return Container(
                key: Key(subtask.id),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Icon(
                              Icons.drag_handle_rounded,
                              color: cs.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _expandedEmojiEditorId =
                                  isEmojiEditorOpen ? null : subtask.id;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cs.outlineVariant),
                            ),
                            child: Text(
                              emojiLabel,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            onChanged: (value) =>
                                _updateSubtask(subtask.id, name: value),
                            decoration: InputDecoration(
                              hintText: 'Subtask name',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildDurationStepper(cs, subtask),
                        IconButton(
                          onPressed: () => _removeSubtask(subtask.id),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: cs.error.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    if (isEmojiEditorOpen) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: emojiCtrl,
                        onChanged: (value) =>
                            _updateSubtask(subtask.id, emoji: value),
                        decoration: InputDecoration(
                          labelText: 'Emoji',
                          hintText: 'Type emoji',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _addSubtask,
            child: const Text('Add Subtask'),
          ),
        ),
        Text(
          'Total: ${_formatMinutesLabel(_totalSubtaskMinutes)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineRecurrenceSection(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repeat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<String>(value: 'none', label: Text('None')),
              ButtonSegment<String>(value: 'daily', label: Text('Daily')),
              ButtonSegment<String>(value: 'weekly', label: Text('Weekly')),
              ButtonSegment<String>(value: 'monthly', label: Text('Monthly')),
            ],
            selected: {_recurrenceType},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              setState(() {
                _recurrenceType = selection.first;
              });
            },
          ),
          if (_recurrenceType == 'weekly') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<Widget>.generate(
                _weekdayToggleLabels.length,
                (index) {
                  final weekday = index + 1;
                  return FilterChip(
                    label: Text(_weekdayToggleLabels[index]),
                    selected: _recurrenceDays.contains(weekday),
                    onSelected: (_) => _toggleRecurrenceDay(weekday),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              20,
        ),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isEdit ? 'Edit Routine' : 'Create Routine',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Routine name',
              hintText: 'e.g., Morning Routine',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _icons.map((icon) {
                final selected = _icon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _icon = icon),
                  child: Container(
                    width: 40,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _colors.map((colorValue) {
                final selected = _color == colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _color = colorValue),
                  child: Container(
                    width: 32,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Color(colorValue),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: Color(colorValue).withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Center(
                            child: Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _buildReminderCard(cs),
          const SizedBox(height: 12),
          _buildReminderRepeatCard(cs),
          if (_reminderTime != null) const SizedBox(height: 16),
          _buildStepsSection(cs),
          const SizedBox(height: 16),
          _buildSubtasksSection(cs),
          const SizedBox(height: 16),
          _buildRoutineRecurrenceSection(cs),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: Color(_color),
                foregroundColor: Colors.white,
              ),
              child: Text(
                isEdit ? 'Save Changes' : 'Create Routine',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
