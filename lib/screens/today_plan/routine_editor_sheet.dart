// =============================================================
// RoutineEditorSheet — Create / edit routines with reorderable steps
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
  final _nameCtrl = TextEditingController();
  final _uuid = const Uuid();

  String _icon = '🌅';
  int _color = 0xFF6366F1;
  List<RoutineStep> _steps = [];
  String? _reminderTime;
  String _recurrence = 'daily';
  String? _recurrenceEndDate;
  int? _reminderWeekday;

  static const _icons = [
    '🌅',
    '🌙',
    '🏋️',
    '🧘',
    '🍽️',
    '📚',
    '🛁',
    '🎯',
    '💼',
    '🔄',
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
  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing == null) return;

    _nameCtrl.text = existing.name;
    _icon = existing.icon;
    _color = existing.color;
    _steps = List.from(existing.steps);
    _reminderTime = existing.reminderTime;
    _recurrence = existing.recurrence ?? 'daily';
    _recurrenceEndDate = existing.recurrenceEndDate;
    _reminderWeekday = existing.reminderWeekday;

    if (_reminderTime != null &&
        _recurrence == 'weekly' &&
        (_reminderWeekday == null || _reminderWeekday! < 1 || _reminderWeekday! > 7)) {
      _reminderWeekday = DateTime.now().weekday;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
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

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

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
      initialDate: selected != null && !selected.isBefore(today) ? selected : today,
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: durCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Estimated minutes (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

    final routine = Routine(
      id: widget.existing?.id ?? _uuid.v4(),
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
                  Icon(
                    Icons.alarm_rounded,
                    size: 18,
                    color: cs.primary,
                  ),
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
                          _reminderTime == null ? 'No reminder' : 'Tap to change time',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _reminderTime == null ? 'No reminder' : _formatReminderTime(_reminderTime!),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _reminderTime == null ? cs.onSurface.withValues(alpha: 0.5) : cs.primary,
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

  Widget _buildRepeatCard(ColorScheme cs) {
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
              ButtonSegment<String>(
                value: 'daily',
                label: Text('Daily'),
              ),
              ButtonSegment<String>(
                value: 'weekly',
                label: Text('Weekly'),
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scroll) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit Routine' : 'Create Routine',
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        color: selected ? cs.primary.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.1),
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
                              child: Icon(Icons.check_rounded, size: 16, color: Colors.white),
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
            _buildRepeatCard(cs),
            if (_reminderTime != null) const SizedBox(height: 16),

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

            Expanded(
              child: _steps.isEmpty
                  ? Center(
                      child: Text(
                        'Tap "Add Step" to create routine steps',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      scrollController: scroll,
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
                              Icon(
                                Icons.drag_handle_rounded,
                                size: 18,
                                color: cs.onSurface.withValues(alpha: 0.2),
                              ),
                            ],
                          ),
                          dense: true,
                        );
                      },
                    ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: Color(_color),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isEdit ? 'Save Changes' : 'Create Routine',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
