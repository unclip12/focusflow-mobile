// =============================================================
// RevisionCard — card for a single KB entry in Revision Hub
// Shows pageNumber, topic, subject chip, days until due,
// SRS step indicator, Mark Revised button, View button
// =============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/models/knowledge_base.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/app_router.dart';
import 'package:focusflow_mobile/utils/text_sanitizer.dart';

class RevisionCard extends StatefulWidget {
  final KnowledgeBaseEntry entry;

  const RevisionCard({super.key, required this.entry});

  @override
  State<RevisionCard> createState() => _RevisionCardState();
}

class _RevisionCardState extends State<RevisionCard> {
  bool _saving = false;

  Future<void> _markRevised() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final app = context.read<AppProvider>();
      final mode = app.revisionSettings?.mode ?? 'strict';
      final newIndex =
          (widget.entry.currentRevisionIndex + 1).clamp(0, 11);
      final nextDate = SrsService.calculateNextRevisionDateString(
        lastStudiedAt: DateTime.now().toIso8601String(),
        revisionIndex: newIndex,
        mode: mode,
      );
      final updated = widget.entry.copyWith(
        currentRevisionIndex: newIndex,
        lastStudiedAt: DateTime.now().toIso8601String(),
        nextRevisionAt: nextDate,
        revisionCount: widget.entry.revisionCount + 1,
      );
      await app.upsertKBEntry(updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Sanitize display text
    final displayTitle = TextSanitizer.clean(entry.title);
    final displayPage  = TextSanitizer.clean(entry.pageNumber);

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
      dueColor = const Color(0xFFEF4444); // overdue - red
      dueLabel = '${-daysUntilDue}d overdue';
    } else if (daysUntilDue == 0) {
      dueColor = const Color(0xFFF59E0B); // today - amber
      dueLabel = 'Due today';
    } else {
      dueColor = const Color(0xFF10B981); // upcoming - green
      dueLabel = 'In ${daysUntilDue}d';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          // Left color indicator
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: dueColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page number + topic
                Text(
                  displayPage.isNotEmpty
                      ? 'Page $displayPage \u2014 $displayTitle'
                      : displayTitle,
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
                    const SizedBox(width: 8),
                    // SRS step indicator
                    Text(
                      'Step ${entry.currentRevisionIndex} / 11',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Action buttons (stacked vertically)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mark Revised
              FilledButton.tonal(
                onPressed: _saving ? null : _markRevised,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Mark Revised \u2713'),
              ),
              const SizedBox(height: 4),
              // View
              TextButton(
                onPressed: () => context.pushNamed(
                  Routes.knowledgeBase,
                  extra: entry,
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('View'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
