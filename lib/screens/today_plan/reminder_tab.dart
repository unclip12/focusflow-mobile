import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focusflow_mobile/models/reminder.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

Future<void> showReminderEditorSheet(
  BuildContext context, {
  required String dateKey,
  Reminder? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ReminderEditorSheet(
      dateKey: dateKey,
      existing: existing,
    ),
  );
}

class ReminderTab extends StatelessWidget {
  final String dateKey;
  final String? highlightedReminderId;

  const ReminderTab({
    super.key,
    required this.dateKey,
    this.highlightedReminderId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final reminders = app.getReminderOccurrencesForDate(dateKey);
    final completedCount = reminders.where((item) => item.completed).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text(
                '$completedCount of ${reminders.length} done',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => showReminderEditorSheet(
                  context,
                  dateKey: dateKey,
                ),
                icon: const Icon(Icons.add_alert_rounded, size: 18),
                label: const Text('Add', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        Expanded(
          child: reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 48,
                        color: cs.primary.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No reminders yet',
                        style: TextStyle(
                          fontSize: 15,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + to add a reminder',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.of(context).padding.bottom + 72 + 24,
                  ),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final occurrence = reminders[index];
                    return Dismissible(
                      key: Key(
                        'reminder_${occurrence.reminderId}_${occurrence.occurrenceKey}',
                      ),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: cs.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.delete_rounded, color: cs.error),
                      ),
                      onDismissed: (_) =>
                          context.read<AppProvider>().deleteReminder(
                                occurrence.reminderId,
                              ),
                      child: _ReminderOccurrenceTile(
                        occurrence: occurrence,
                        highlighted:
                            highlightedReminderId == occurrence.reminderId,
                        onTap: () => showReminderEditorSheet(
                          context,
                          dateKey: dateKey,
                          existing: occurrence.reminder,
                        ),
                        onToggle: () => context
                            .read<AppProvider>()
                            .setReminderOccurrenceCompleted(
                              reminderId: occurrence.reminderId,
                              occurrenceKey: occurrence.occurrenceKey,
                              completed: !occurrence.completed,
                            ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ReminderOccurrenceTile extends StatelessWidget {
  final ReminderOccurrence occurrence;
  final bool highlighted;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _ReminderOccurrenceTile({
    required this.occurrence,
    required this.highlighted,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = occurrence.isOverdue
        ? const Color(0xFFD97706)
        : const Color(0xFF6366F1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: occurrence.completed
            ? accent.withValues(alpha: 0.06)
            : cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? accent.withValues(alpha: 0.65)
              : cs.onSurface.withValues(alpha: 0.06),
          width: highlighted ? 1.4 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Checkbox(
          value: occurrence.completed,
          onChanged: (_) => onToggle(),
          activeColor: accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(
          occurrence.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            decoration:
                occurrence.completed ? TextDecoration.lineThrough : null,
            color: occurrence.completed
                ? cs.onSurface.withValues(alpha: 0.4)
                : cs.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_buildMetaLine().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _buildMetaLine(),
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            if (occurrence.notes?.trim().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  occurrence.notes!.trim(),
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (occurrence.time != null && occurrence.time!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _formatTime(occurrence.time!),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              )
            else
              Text(
                'All day',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            if (occurrence.isOverdue)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Overdue',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildMetaLine() {
    final parts = <String>[];
    parts.add(_recurrenceLabel(occurrence.reminder.recurrenceType));
    if (occurrence.isOverdue) {
      parts.add(
          'Originally ${DateFormat('d MMM').format(DateTime.parse(occurrence.occurrenceKey))}');
    }
    return parts.join(' • ');
  }
}

class _ReminderEditorSheet extends StatefulWidget {
  final String dateKey;
  final Reminder? existing;

  const _ReminderEditorSheet({
    required this.dateKey,
    this.existing,
  });

  @override
  State<_ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<_ReminderEditorSheet> {
  static const List<int> _presetAlertOffsets = <int>[0, 5, 10, 15, 30, 45, 60];

  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _customAlertCtrl = TextEditingController();
  final _uuid = const Uuid();

  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isAllDay = false;
  late String _recurrenceType;
  late bool _useDefaultAlerts;
  late Set<int> _customAlertOffsets;
  late Set<int> _customWeekdays;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleCtrl.text = existing?.title ?? '';
    _notesCtrl.text = existing?.notes ?? '';
    _selectedDate = DateTime.tryParse(existing?.baseDate ?? widget.dateKey) ??
        DateTime.now();
    _isAllDay = existing?.isAllDay ?? false;
    _selectedTime = _parseTime(existing?.time);
    _recurrenceType =
        existing?.recurrenceType ?? ReminderRecurrenceType.oneTime;
    _useDefaultAlerts = existing?.useDefaultAlerts ?? true;
    _customAlertOffsets = {...?existing?.customAlertOffsets};
    _customWeekdays = {...?existing?.recurrenceWeekdays};
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _customAlertCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reminderDefaults = context
        .read<SettingsProvider>()
        .reminderNotifications
        .defaultAlertOffsets;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existing == null ? 'Add Reminder' : 'Edit Reminder',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Reminder title',
                hintText: 'Check the website',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional details',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('All day'),
              subtitle: const Text('Timed reminders appear in the timeline'),
              value: _isAllDay,
              onChanged: (value) => setState(() => _isAllDay = value),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text(DateFormat('d MMM yyyy').format(_selectedDate)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAllDay ? null : _pickTime,
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(
                      _isAllDay
                          ? 'No time'
                          : (_selectedTime == null
                              ? 'Pick time'
                              : _formatTime(_timeString(_selectedTime!))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _recurrenceType,
              decoration: const InputDecoration(labelText: 'Repeat'),
              items: const [
                DropdownMenuItem(
                  value: ReminderRecurrenceType.oneTime,
                  child: Text('Does not repeat'),
                ),
                DropdownMenuItem(
                  value: ReminderRecurrenceType.daily,
                  child: Text('Daily'),
                ),
                DropdownMenuItem(
                  value: ReminderRecurrenceType.weekly,
                  child: Text('Weekly'),
                ),
                DropdownMenuItem(
                  value: ReminderRecurrenceType.customWeekdays,
                  child: Text('Custom weekdays'),
                ),
                DropdownMenuItem(
                  value: ReminderRecurrenceType.monthly,
                  child: Text('Monthly'),
                ),
                DropdownMenuItem(
                  value: ReminderRecurrenceType.yearly,
                  child: Text('Yearly'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _recurrenceType = value);
              },
            ),
            if (_recurrenceType == ReminderRecurrenceType.customWeekdays) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List<Widget>.generate(7, (index) {
                  final weekday = index + 1;
                  final selected = _customWeekdays.contains(weekday);
                  return FilterChip(
                    label: Text(_weekdayLabel(weekday)),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _customWeekdays.add(weekday);
                        } else {
                          _customWeekdays.remove(weekday);
                        }
                      });
                    },
                  );
                }),
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use default alert times'),
              subtitle: Text(
                _formatOffsets(
                  _useDefaultAlerts
                      ? reminderDefaults
                      : _customAlertOffsets.toList(),
                ),
              ),
              value: _useDefaultAlerts,
              onChanged: (value) => setState(() => _useDefaultAlerts = value),
            ),
            if (!_useDefaultAlerts) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetAlertOffsets.map((offset) {
                  final selected = _customAlertOffsets.contains(offset);
                  return FilterChip(
                    label: Text(offset == 0 ? 'At time' : '$offset min before'),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _customAlertOffsets.add(offset);
                        } else {
                          _customAlertOffsets.remove(offset);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customAlertCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Custom minutes before',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _addCustomOffset,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(widget.existing == null
                    ? 'Save Reminder'
                    : 'Update Reminder'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() => _selectedTime = picked);
  }

  void _addCustomOffset() {
    final minutes = int.tryParse(_customAlertCtrl.text.trim());
    if (minutes == null || minutes < 0) return;
    setState(() {
      _customAlertOffsets.add(minutes);
      _customAlertCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    if (!_isAllDay && _selectedTime == null) return;
    if (_recurrenceType == ReminderRecurrenceType.customWeekdays &&
        _customWeekdays.isEmpty) {
      return;
    }

    final existing = widget.existing;
    final nowIso = DateTime.now().toIso8601String();
    final reminder = Reminder(
      id: existing?.id ?? _uuid.v4(),
      title: _titleCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      baseDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      time: _isAllDay || _selectedTime == null
          ? null
          : _timeString(_selectedTime!),
      isAllDay: _isAllDay,
      recurrenceType: _recurrenceType,
      recurrenceWeekdays:
          _recurrenceType == ReminderRecurrenceType.customWeekdays
              ? (_customWeekdays.toList()..sort())
              : const <int>[],
      useDefaultAlerts: _useDefaultAlerts,
      customAlertOffsets: _useDefaultAlerts
          ? const <int>[]
          : (_customAlertOffsets.toList()..sort()),
      createdAt: existing?.createdAt ?? nowIso,
      updatedAt: nowIso,
      archived: existing?.archived ?? false,
    );

    await context.read<AppProvider>().upsertReminder(reminder);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

String _formatTime(String hhmm) {
  final parts = hhmm.split(':');
  final time = TimeOfDay(
    hour: int.tryParse(parts[0]) ?? 0,
    minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
  );
  final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  return '$hour:${time.minute.toString().padLeft(2, '0')} $suffix';
}

String _recurrenceLabel(String recurrenceType) {
  switch (recurrenceType) {
    case ReminderRecurrenceType.daily:
      return 'Daily';
    case ReminderRecurrenceType.weekly:
      return 'Weekly';
    case ReminderRecurrenceType.customWeekdays:
      return 'Custom weekdays';
    case ReminderRecurrenceType.monthly:
      return 'Monthly';
    case ReminderRecurrenceType.yearly:
      return 'Yearly';
    default:
      return 'One-time';
  }
}

TimeOfDay? _parseTime(String? hhmm) {
  if (hhmm == null || hhmm.isEmpty) return null;
  final parts = hhmm.split(':');
  if (parts.length != 2) return null;
  return TimeOfDay(
    hour: int.tryParse(parts[0]) ?? 0,
    minute: int.tryParse(parts[1]) ?? 0,
  );
}

String _timeString(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case 1:
      return 'Mon';
    case 2:
      return 'Tue';
    case 3:
      return 'Wed';
    case 4:
      return 'Thu';
    case 5:
      return 'Fri';
    case 6:
      return 'Sat';
    case 7:
      return 'Sun';
    default:
      return 'Day';
  }
}

String _formatOffsets(List<int> offsets) {
  if (offsets.isEmpty) return 'No alerts';
  final normalized = offsets.toSet().toList()..sort();
  return normalized
      .map((offset) => offset == 0 ? 'At time' : '$offset min before')
      .join(' • ');
}
