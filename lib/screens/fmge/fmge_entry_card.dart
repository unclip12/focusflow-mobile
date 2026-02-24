// =============================================================
// FMGEEntryCard — compact card for FMGE list items
// Shows: subject, slide range (topic), log count badge,
//        last score as 5-star display, next revision chip.
// =============================================================

import 'package:flutter/material.dart';

import 'package:focusflow_mobile/models/fmge_entry.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/core/theme/app_colors.dart';

class FMGEEntryCard extends StatelessWidget {
  final FMGEEntry entry;
  final VoidCallback? onTap;

  const FMGEEntryCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    const String mode = 'strict';
    final isMastered = SrsService.isMastered(
        revisionIndex: entry.currentRevisionIndex, mode: mode);
    final isOverdue =
        SrsService.isDueNow(nextRevisionAt: entry.nextRevisionAt);

    // ── Next revision chip ───────────────────────────────────────
    Color chipColor;
    String chipText;
    if (isMastered) {
      chipColor = AppColors.success;
      chipText = 'Mastered';
    } else if (isOverdue) {
      chipColor = AppColors.error;
      chipText = 'Overdue';
    } else if (entry.nextRevisionAt != null) {
      final next = DateTime.tryParse(entry.nextRevisionAt!);
      final now = DateTime.now();
      if (next != null) {
        final diff = next.difference(now);
        chipText = diff.inDays > 0
            ? '${diff.inDays}d left'
            : diff.inHours > 0
                ? '${diff.inHours}h left'
                : 'Due soon';
      } else {
        chipText = 'Scheduled';
      }
      chipColor = AppColors.warning;
    } else {
      chipColor = cs.onSurface.withValues(alpha: 0.3);
      chipText = 'Not started';
    }

    // ── Last score (from most recent log's notes field) ──────────
    final lastScore = _parseLastScore(entry);

    // ── Subject colour ───────────────────────────────────────────
    final subjectColor = AppColors.subjectColors[
        entry.subject.hashCode.abs() % AppColors.subjectColors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: subject chip + revision chip ─────────────
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: subjectColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.subject,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: subjectColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    chipText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: chipColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Slide range (topic) ──────────────────────────────
            Text(
              'Slides ${entry.slideStart}–${entry.slideEnd}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // ── Bottom row: log count badge + 5-star display ─────
            Row(
              children: [
                // Log count badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${entry.logs.length} logs',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 5 star display
                ...List.generate(5, (i) {
                  return Icon(
                    i < lastScore
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 16,
                    color: i < lastScore
                        ? AppColors.warning
                        : cs.onSurface.withValues(alpha: 0.15),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Parse the last revision score from logs.
  /// Scores are stored as "Score: N/5" in the notes field.
  int _parseLastScore(FMGEEntry entry) {
    if (entry.logs.isEmpty) return 0;
    final lastLog = entry.logs.last;
    if (lastLog.notes == null) return 0;
    final match = RegExp(r'Score:\s*(\d)').firstMatch(lastLog.notes!);
    if (match != null) return int.parse(match.group(1)!);
    return 0;
  }
}
