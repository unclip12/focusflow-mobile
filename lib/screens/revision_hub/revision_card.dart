// =============================================================
// RevisionCard — card for a single KB entry in Revision Hub
// Shows pageNumber, topic, subject chip, days until due, revise button
// =============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:focusflow_mobile/models/knowledge_base.dart';
import 'package:focusflow_mobile/app_router.dart';

class RevisionCard extends StatelessWidget {
  final KnowledgeBaseEntry entry;

  const RevisionCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Calculate days until due
    final nextRev = entry.nextRevisionAt != null
        ? DateTime.tryParse(entry.nextRevisionAt!)
        : null;
    final now = DateTime.now();
    final daysUntilDue = nextRev != null
        ? nextRev.difference(now).inDays
        : 999;

    // Due color
    final Color dueColor;
    final String dueLabel;
    if (daysUntilDue < 0) {
      dueColor = const Color(0xFFEF4444); // overdue — red
      dueLabel = '${-daysUntilDue}d overdue';
    } else if (daysUntilDue == 0) {
      dueColor = const Color(0xFFF59E0B); // today — amber
      dueLabel = 'Due today';
    } else {
      dueColor = const Color(0xFF10B981); // upcoming — green
      dueLabel = 'In ${daysUntilDue}d';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          // ── Left color indicator ──────────────────────────────
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: dueColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // ── Content ──────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page number + topic
                Text(
                  entry.pageNumber.isNotEmpty
                      ? 'Page ${entry.pageNumber} — ${entry.title}'
                      : entry.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Subject chip
                    if (entry.subject.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.subject,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Due label
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: dueColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        dueLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: dueColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Revise Now button ─────────────────────────────────
          GestureDetector(
            onTap: () => context.pushNamed(
              Routes.knowledgeBase,
              extra: entry,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: dueColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Revise',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: dueColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
