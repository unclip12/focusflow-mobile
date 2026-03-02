// =============================================================
// UnifiedRevisionCard — card for any revision item in the hub
// Shows source badge, title, subject, revision step, due info,
// Mark Revised button.  ALL text constrained — no overflow.
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'revision_hub_screen.dart';

class UnifiedRevisionCard extends StatefulWidget {
  final RevisionDisplayItem item;

  const UnifiedRevisionCard({super.key, required this.item});

  @override
  State<UnifiedRevisionCard> createState() => _UnifiedRevisionCardState();
}

class _UnifiedRevisionCardState extends State<UnifiedRevisionCard> {
  bool _saving = false;

  Future<void> _markRevised() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final app = context.read<AppProvider>();
      if (widget.item.isKBEntry) {
        final kbEntry = app.knowledgeBase.firstWhere(
          (e) => 'kb-${e.pageNumber}' == widget.item.id,
        );
        final mode = app.revisionSettings?.mode ?? 'strict';
        final newIndex = (kbEntry.currentRevisionIndex + 1).clamp(0, 11);
        final nextDate = SrsService.calculateNextRevisionDateString(
          lastStudiedAt: DateTime.now().toIso8601String(),
          revisionIndex: newIndex,
          mode: mode,
        );
        final updated = kbEntry.copyWith(
          currentRevisionIndex: newIndex,
          lastStudiedAt: DateTime.now().toIso8601String(),
          nextRevisionAt: nextDate,
          revisionCount: kbEntry.revisionCount + 1,
        );
        await app.upsertKBEntry(updated);
      } else {
        await app.markRevisionItemDone(widget.item.id);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final due = item.dueInfo;

    return Container(
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
          // ── Row 1: Source badge + Title ──────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source icon badge
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.sourceColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(item.sourceIcon, size: 16, color: item.sourceColor),
              ),
              const SizedBox(width: 10),

              // Title + parent — EXPANDED so it never overflows
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.parentTitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.parentTitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Row 2: Chips + Mark Revised ──────────────────────
          // Use Wrap for all children to guarantee no overflow
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip(item.sourceLabel, item.sourceColor, cs),
              _chip(due.label, due.color, cs),
              _chip(
                'R${item.currentRevisionIndex}/${item.totalSteps}',
                cs.onSurface.withValues(alpha: 0.5),
                cs,
              ),
              // Mark Revised button inline
              SizedBox(
                height: 28,
                child: FilledButton.tonal(
                  onPressed: _saving ? null : _markRevised,
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
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
                      : const Text('Revised ✓'),
                ),
              ),
            ],
          ),

          // ── Row 3: Due time detail (flexible, never overflows) ──
          if (due.timeDetail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 12,
                          color: cs.onSurface.withValues(alpha: 0.35)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          due.timeDetail,
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (item.lastStudiedAt != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded,
                            size: 12,
                            color: cs.onSurface.withValues(alpha: 0.35)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatLastStudied(item.lastStudiedAt!),
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatLastStudied(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Studied today';
    if (diff.inDays == 1) return 'Studied yesterday';
    if (diff.inDays < 7) return 'Studied ${diff.inDays}d ago';
    return 'Studied ${(diff.inDays / 7).floor()}w ago';
  }
}
