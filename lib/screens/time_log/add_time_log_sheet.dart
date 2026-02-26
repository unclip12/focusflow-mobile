// =============================================================
// AddTimeLogSheet — bottom sheet form for adding a time log entry
// Subject picker, start/end time, category dropdown, notes, save
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/time_log_entry.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/utils/date_utils.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';

class AddTimeLogSheet extends StatefulWidget {
  const AddTimeLogSheet({super.key});

  @override
  State<AddTimeLogSheet> createState() => _AddTimeLogSheetState();
}

class _AddTimeLogSheetState extends State<AddTimeLogSheet> {
  final _activityController = TextEditingController();
  final _notesController = TextEditingController();
  TimeLogCategory _category = TimeLogCategory.study;
  TimeOfDay _startTime = TimeOfDay.now().replacing(minute: 0);
  TimeOfDay _endTime = TimeOfDay.now();

  @override
  void dispose() {
    _activityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _durationMinutes {
    final startMin = _startTime.hour * 60 + _startTime.minute;
    final endMin = _endTime.hour * 60 + _endTime.minute;
    final diff = endMin - startMin;
    return diff > 0 ? diff : diff + 1440;
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _save() {
    final activity = _activityController.text.trim();
    if (activity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an activity name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticsService.medium();
    final app = context.read<AppProvider>();
    final now = DateTime.now();
    final dateStr = AppDateUtils.todayKey();
    final id = 'tl_${now.millisecondsSinceEpoch}';

    final startDt = DateTime(now.year, now.month, now.day,
        _startTime.hour, _startTime.minute);
    final endDt = DateTime(
        now.year, now.month, now.day, _endTime.hour, _endTime.minute);

    final entry = TimeLogEntry(
      id: id,
      date: dateStr,
      startTime: startDt.toIso8601String(),
      endTime: endDt.toIso8601String(),
      durationMinutes: _durationMinutes,
      category: _category,
      source: TimeLogSource.manual,
      activity: activity,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    app.upsertTimeLog(entry);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ────────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text('Add Time Log',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),

            // ── Activity name ─────────────────────────────────────────
            TextField(
              controller: _activityController,
              decoration: InputDecoration(
                labelText: 'Activity',
                hintText: 'e.g. FA Pages 101-105',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.edit_rounded, size: 20),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // ── Time pickers ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Start',
                    time: _formatTimeOfDay(_startTime),
                    onTap: () => _pickTime(true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
                ),
                Expanded(
                  child: _TimePicker(
                    label: 'End',
                    time: _formatTimeOfDay(_endTime),
                    onTap: () => _pickTime(false),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_durationMinutes}m',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Category dropdown ─────────────────────────────────────
            DropdownButtonFormField<TimeLogCategory>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.category_rounded, size: 20),
              ),
              items: TimeLogCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(_categoryDisplayName(c)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 16),

            // ── Notes ───────────────────────────────────────────────────
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.notes_rounded, size: 20),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // ── Save button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text('Save Log'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryDisplayName(TimeLogCategory c) {
    switch (c) {
      case TimeLogCategory.study:         return 'Study';
      case TimeLogCategory.revision:      return 'Revision';
      case TimeLogCategory.qbank:         return 'QBank';
      case TimeLogCategory.anki:          return 'Anki';
      case TimeLogCategory.video:         return 'Video';
      case TimeLogCategory.noteTaking:    return 'Note Taking';
      case TimeLogCategory.breakTime:     return 'Break';
      case TimeLogCategory.personal:      return 'Personal';
      case TimeLogCategory.sleep:         return 'Sleep';
      case TimeLogCategory.entertainment: return 'Entertainment';
      case TimeLogCategory.outing:        return 'Outing';
      case TimeLogCategory.life:          return 'Life';
      case TimeLogCategory.other:         return 'Other';
    }
  }
}

// ── Time picker tile ──────────────────────────────────────────────
class _TimePicker extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurface.withValues(alpha: 0.45))),
            const SizedBox(height: 2),
            Text(time,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
