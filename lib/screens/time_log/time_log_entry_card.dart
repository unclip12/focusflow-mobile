// =============================================================
// TimeLogEntryCard â€” card for a single TimeLogEntry
// Shows activity, duration, time range, category chip, swipe delete
// =============================================================

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/time_log_entry.dart';
import 'package:focusflow_mobile/utils/constants.dart';

class TimeLogEntryCard extends StatelessWidget {
  final TimeLogEntry entry;
  final VoidCallback onDelete;

  const TimeLogEntryCard({
    super.key,
    required this.entry,
    required this.onDelete,
  });

  Color _categoryColor(TimeLogCategory cat) {
    switch (cat) {
      case TimeLogCategory.study:         return const Color(0xFF6366F1);
      case TimeLogCategory.revision:      return const Color(0xFF8B5CF6);
      case TimeLogCategory.qbank:         return const Color(0xFFEC4899);
      case TimeLogCategory.anki:          return const Color(0xFFF59E0B);
      case TimeLogCategory.video:         return const Color(0xFF3B82F6);
      case TimeLogCategory.prayer:        return const Color(0xFF34D399);
      case TimeLogCategory.noteTaking:    return const Color(0xFF10B981);
      case TimeLogCategory.breakTime:     return const Color(0xFF94A3B8);
      case TimeLogCategory.personal:      return const Color(0xFFF97316);
      case TimeLogCategory.sleep:         return const Color(0xFF64748B);
      case TimeLogCategory.entertainment: return const Color(0xFFEF4444);
      case TimeLogCategory.outing:        return const Color(0xFF14B8A6);
      case TimeLogCategory.life:          return const Color(0xFF84CC16);
      case TimeLogCategory.other:         return const Color(0xFF78716C);
    }
  }

  String _categoryLabel(TimeLogCategory cat) {
    switch (cat) {
      case TimeLogCategory.study:         return 'Study';
      case TimeLogCategory.revision:      return 'Revision';
      case TimeLogCategory.qbank:         return 'QBank';
      case TimeLogCategory.anki:          return 'Anki';
      case TimeLogCategory.video:         return 'Video';
      case TimeLogCategory.prayer:        return 'Prayer';
      case TimeLogCategory.noteTaking:    return 'Notes';
      case TimeLogCategory.breakTime:     return 'Break';
      case TimeLogCategory.personal:      return 'Personal';
      case TimeLogCategory.sleep:         return 'Sleep';
      case TimeLogCategory.entertainment: return 'Entertainment';
      case TimeLogCategory.outing:        return 'Outing';
      case TimeLogCategory.life:          return 'Life';
      case TimeLogCategory.other:         return 'Other';
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String _formatTimeRange() {
    // startTime and endTime are ISO strings â€” extract HH:mm
    String extract(String iso) {
      final dt = DateTime.tryParse(iso);
      if (dt != null) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      // Fallback: if it's already HH:mm
      if (iso.length >= 5) return iso.substring(0, 5);
      return iso;
    }
    return '${extract(entry.startTime)} â†’ ${extract(entry.endTime)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final catColor = _categoryColor(entry.category);

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded,
            color: Color(0xFFEF4444), size: 22),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete time log?'),
            content: Text('Remove "${entry.activity}" log?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete',
                      style: TextStyle(color: Color(0xFFEF4444)))),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            // â”€â”€ Category dot â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: catColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // â”€â”€ Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.activity,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTimeRange(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // â”€â”€ Duration â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Text(
              _formatDuration(entry.durationMinutes),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),

            const SizedBox(width: 10),

            // â”€â”€ Category chip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _categoryLabel(entry.category),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: catColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
