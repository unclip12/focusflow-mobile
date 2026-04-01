// =============================================================
// RoutineEditorSheet - Create / edit routines
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:focusflow_mobile/models/routine.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/services/offline_suggestion_catalog.dart';

class RoutineEditorSheet extends StatefulWidget {
  final Routine? existing;

  const RoutineEditorSheet({super.key, this.existing});

  @override
  State<RoutineEditorSheet> createState() => _RoutineEditorSheetState();
}

class _RoutineEditorSheetState extends State<RoutineEditorSheet> {
  static const _defaultStepEmoji = '✨';

  final _nameCtrl = TextEditingController();
  final _uuid = const Uuid();
  final Map<String, TextEditingController> _stepTitleCtrls = {};
  final Map<String, TextEditingController> _stepEmojiCtrls = {};
  final Map<String, TextEditingController> _stepMinutesCtrls = {};
  final Map<String, TextEditingController> _stepChecklistInputCtrls = {};
  final Set<String> _stepEmojiOverrides = <String>{};
  final Set<String> _stepDurationOverrides = <String>{};

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
  bool _routineIconOverridden = false;

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
    if (existing != null) {
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
      _routineIconOverridden = true;

      for (final step in _steps) {
        _ensureStepControllers(step);
      }

      if (_reminderTime != null &&
          _recurrence == 'weekly' &&
          (_reminderWeekday == null ||
              _reminderWeekday! < 1 ||
              _reminderWeekday! > 7)) {
        _reminderWeekday = DateTime.now().weekday;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final controller in _stepTitleCtrls.values) {
      controller.dispose();
    }
    for (final controller in _stepEmojiCtrls.values) {
      controller.dispose();
    }
    for (final controller in _stepMinutesCtrls.values) {
      controller.dispose();
    }
    for (final controller in _stepChecklistInputCtrls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _ensureStepControllers(RoutineStep step) {
    _stepTitleCtrls.putIfAbsent(
      step.id,
      () => TextEditingController(text: step.title),
    );
    _stepEmojiCtrls.putIfAbsent(
      step.id,
      () => TextEditingController(text: step.emoji),
    );
    _stepMinutesCtrls.putIfAbsent(
      step.id,
      () => TextEditingController(
        text: step.estimatedMinutes?.toString() ?? '',
      ),
    );
    _stepChecklistInputCtrls.putIfAbsent(
      step.id,
      () => TextEditingController(),
    );
  }

  void _disposeStepControllers(String id) {
    _stepTitleCtrls.remove(id)?.dispose();
    _stepEmojiCtrls.remove(id)?.dispose();
    _stepMinutesCtrls.remove(id)?.dispose();
    _stepChecklistInputCtrls.remove(id)?.dispose();
    _stepEmojiOverrides.remove(id);
    _stepDurationOverrides.remove(id);
  }

  void _updateStep(
    String id, {
    String? title,
    String? emoji,
    int? estimatedMinutes,
    List<RoutineChecklistItem>? checklistItems,
  }) {
    final index = _steps.indexWhere((step) => step.id == id);
    if (index == -1) return;

    setState(() {
      _steps[index] = _steps[index].copyWith(
        title: title,
        emoji: emoji,
        estimatedMinutes: estimatedMinutes,
        checklistItems: checklistItems,
      );
    });
  }

  void _applyRoutineSuggestion(String title) {
    if (_routineIconOverridden) return;
    final suggestion = OfflineSuggestionCatalog.suggest(title);
    setState(() {
      _icon = suggestion.emoji;
    });
  }

  void _applyStepSuggestion(String stepId, String title) {
    final suggestion = OfflineSuggestionCatalog.suggest(title);
    final emojiCtrl = _stepEmojiCtrls[stepId];
    final minutesCtrl = _stepMinutesCtrls[stepId];
    final index = _steps.indexWhere((step) => step.id == stepId);
    if (index == -1) return;

    final step = _steps[index];
    final nextEmoji = _stepEmojiOverrides.contains(stepId)
        ? step.emoji
        : suggestion.emoji;
    final nextMinutes = _stepDurationOverrides.contains(stepId)
        ? step.estimatedMinutes
        : suggestion.defaultMinutes;

    if (!_stepEmojiOverrides.contains(stepId) && emojiCtrl != null) {
      emojiCtrl.text = nextEmoji;
    }
    if (!_stepDurationOverrides.contains(stepId) && minutesCtrl != null) {
      minutesCtrl.text = nextMinutes?.toString() ?? '';
    }

    _updateStep(
      stepId,
      title: title,
      emoji: nextEmoji,
      estimatedMinutes: nextMinutes,
    );
  }

  void _addChecklistItem(String stepId, String title) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;

    final index = _steps.indexWhere((step) => step.id == stepId);
    if (index == -1) return;
    final existingTitles = _steps[index].checklistItems
        .map((item) => item.title.toLowerCase())
        .toSet();
    if (existingTitles.contains(trimmedTitle.toLowerCase())) {
      _stepChecklistInputCtrls[stepId]?.clear();
      return;
    }

    final updatedItems = [
      ..._steps[index].checklistItems,
      RoutineChecklistItem(id: _uuid.v4(), title: trimmedTitle),
    ];
    _stepChecklistInputCtrls[stepId]?.clear();
    _updateStep(stepId, checklistItems: updatedItems);
  }

  void _removeChecklistItem(String stepId, String itemId) {
    final index = _steps.indexWhere((step) => step.id == stepId);
    if (index == -1) return;
    final updatedItems = _steps[index]
        .checklistItems
        .where((item) => item.id != itemId)
        .toList();
    _updateStep(stepId, checklistItems: updatedItems);
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
    final step = RoutineStep(
      id: _uuid.v4(),
      title: '',
      emoji: _defaultStepEmoji,
      estimatedMinutes: null,
      checklistItems: const [],
      sortOrder: _steps.length,
    );
    _ensureStepControllers(step);
    setState(() {
      _steps.add(step);
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;

    final app = context.read<AppProvider>();
    final now = DateTime.now().toIso8601String();
    final reminderTime = _reminderTime;
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
          .map((entry) {
            final step = entry.value;
            final emojiText = _stepEmojiCtrls[step.id]?.text.trim() ?? '';
            final minutesText = _stepMinutesCtrls[step.id]?.text.trim() ?? '';
            final titleText = _stepTitleCtrls[step.id]?.text.trim() ?? '';
            return step.copyWith(
              title: titleText,
              emoji: emojiText.isNotEmpty ? emojiText : _defaultStepEmoji,
              estimatedMinutes: int.tryParse(minutesText),
              sortOrder: entry.key,
            );
          })
          .where((step) => step.title.trim().isNotEmpty)
          .toList(),
      reminderTime: reminderTime,
      recurrence: recurrence,
      recurrenceEndDate: recurrenceEndDate,
      reminderWeekday: reminderWeekday,
      recurrenceType: _recurrenceType,
      recurrenceDays: recurrenceDays,
      subtasks: _subtasks,
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
              _ensureStepControllers(step);
              final titleCtrl = _stepTitleCtrls[step.id]!;
              final emojiCtrl = _stepEmojiCtrls[step.id]!;
              final minutesCtrl = _stepMinutesCtrls[step.id]!;
              final checklistInputCtrl = _stepChecklistInputCtrls[step.id]!;
              final suggestedChecklistItems = OfflineSuggestionCatalog
                  .checklistSuggestionsFor(step.title)
                  .where(
                    (suggestion) => !step.checklistItems.any(
                      (item) =>
                          item.title.toLowerCase() == suggestion.toLowerCase(),
                    ),
                  )
                  .toList();

              return Container(
                key: Key(step.id),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: titleCtrl,
                            onChanged: (value) => _applyStepSuggestion(
                              step.id,
                              value.trim(),
                            ),
                            style: TextStyle(color: cs.onSurface),
                            cursorColor: const Color(0xFFE8837A),
                            decoration: InputDecoration(
                              labelText: 'Step title',
                              hintText: 'e.g., Taking bath',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: cs.error.withValues(alpha: 0.7),
                          ),
                          onPressed: () {
                            setState(() => _steps.removeAt(index));
                            _disposeStepControllers(step.id);
                          },
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: TextField(
                            controller: emojiCtrl,
                            onChanged: (value) {
                              _stepEmojiOverrides.add(step.id);
                              _updateStep(
                                step.id,
                                emoji: value.trim().isEmpty
                                    ? _defaultStepEmoji
                                    : value.trim(),
                              );
                            },
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              color: cs.onSurface,
                            ),
                            cursorColor: const Color(0xFFE8837A),
                            decoration: InputDecoration(
                              labelText: 'Emoji',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: minutesCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _stepDurationOverrides.add(step.id);
                              _updateStep(
                                step.id,
                                estimatedMinutes: int.tryParse(value),
                              );
                            },
                            style: TextStyle(color: cs.onSurface),
                            cursorColor: const Color(0xFFE8837A),
                            decoration: InputDecoration(
                              labelText: 'Estimated minutes',
                              hintText: 'Auto-suggested',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Checklist',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (step.checklistItems.isEmpty)
                      Text(
                        'No checklist items yet. Add your own or tap suggestions below.',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (final item in step.checklistItems)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.checklist_rounded,
                                    size: 16,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        _removeChecklistItem(step.id, item.id),
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: cs.error.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    if (suggestedChecklistItems.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: suggestedChecklistItems.map((suggestion) {
                          return ActionChip(
                            avatar: const Icon(Icons.add_rounded, size: 16),
                            label: Text(suggestion),
                            onPressed: () => _addChecklistItem(
                              step.id,
                              suggestion,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: checklistInputCtrl,
                            style: TextStyle(color: cs.onSurface),
                            cursorColor: const Color(0xFFE8837A),
                            decoration: InputDecoration(
                              labelText: 'Add checklist item',
                              hintText: 'e.g., Take towel',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onSubmitted: (value) =>
                                _addChecklistItem(step.id, value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => _addChecklistItem(
                            step.id,
                            checklistInputCtrl.text,
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
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
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final isEdit = widget.existing != null;

    return Material(
      color: scaffoldBackgroundColor,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scroll) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Material(
            color: scaffoldBackgroundColor,
            child: SingleChildScrollView(
              controller: scroll,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
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
                  ColoredBox(
                    color: scaffoldBackgroundColor,
                    child: TextField(
                      controller: _nameCtrl,
                      onChanged: (value) => _applyRoutineSuggestion(value.trim()),
                      style: TextStyle(color: cs.onSurface),
                      cursorColor: const Color(0xFFE8837A),
                      decoration: InputDecoration(
                        labelText: 'Routine name',
                        hintText: 'e.g., Morning Routine',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
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
                          onTap: () => setState(() {
                            _routineIconOverridden = true;
                            _icon = icon;
                          }),
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
                              child: Text(icon,
                                  style: const TextStyle(fontSize: 20)),
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
                                color: selected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: Color(colorValue)
                                            .withValues(alpha: 0.5),
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
            ),
          ),
        ),
      ),
    );
  }
}
