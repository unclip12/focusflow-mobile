// =============================================================
// KBEntryCard — compact card for Knowledge Base list items
// Shows: pageNumber, topic, subject chip, system chip,
//        mastery progress bar, next revision date badge.
// =============================================================

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/knowledge_base.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/core/theme/app_colors.dart';

class KBEntryCard extends StatelessWidget {
  final KnowledgeBaseEntry entry;
  final VoidCallback? onTap;

  const KBEntryCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // ── Mastery computation ──────────────────────────────────────
    const String mode = 'strict';
    final int totalSteps = SrsService.totalSteps(mode);
    final int masteredCount = entry.currentRevisionIndex.clamp(0, totalSteps);
    final double masteryRatio =
        totalSteps > 0 ? masteredCount / totalSteps : 0.0;
    final bool isMastered =
        SrsService.isMastered(revisionIndex: entry.currentRevisionIndex, mode: mode);

    // ── Next revision badge ──────────────────────────────────────
    final now = DateTime.now();
    final bool isOverdue = SrsService.isDueNow(nextRevisionAt: entry.nextRevisionAt);
    final DateTime? nextDate = entry.nextRevisionAt != null
        ? DateTime.tryParse(entry.nextRevisionAt!)
        : null;

    Color badgeColor;
    String badgeText;
    if (isMastered) {
      badgeColor = AppColors.success;
      badgeText = 'Mastered';
    } else if (isOverdue) {
      badgeColor = AppColors.error;
      badgeText = 'Overdue';
    } else if (nextDate != null) {
      final diff = nextDate.difference(now);
      if (diff.inDays > 0) {
        badgeText = '${diff.inDays}d left';
      } else if (diff.inHours > 0) {
        badgeText = '${diff.inHours}h left';
      } else {
        badgeText = 'Due soon';
      }
      badgeColor = AppColors.warning;
    } else {
      badgeColor = cs.onSurface.withValues(alpha: 0.3);
      badgeText = 'Not started';
    }

    // ── Subject colour ───────────────────────────────────────────
    final subjectHash = entry.subject.hashCode.abs();
    final subjectColor =
        AppColors.subjectColors[subjectHash % AppColors.subjectColors.length];

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
            // ── Top row: page number + badge ──────────────────────
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'P ${entry.pageNumber}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Title ────────────────────────────────────────────
            Text(
              entry.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // ── Chips row ────────────────────────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _Chip(label: entry.subject, color: subjectColor),
                _Chip(
                  label: entry.system,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Mastery progress bar ─────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: masteryRatio,
                      minHeight: 5,
                      backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(
                        isMastered ? AppColors.success : cs.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$masteredCount / $totalSteps',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tiny chip widget ──────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
