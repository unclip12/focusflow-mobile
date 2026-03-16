// =============================================================
// RevisionConfidenceSheet — Reusable confidence rating bottom sheet
// Shows Hard / Good / Easy buttons for SRS-based revision marking
// Used from both Library (tracker) and Revision Hub
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/revision_item.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';

/// Shows a bottom sheet with Hard/Good/Easy confidence buttons.
///
/// Returns `true` if a revision was marked, `false` or `null` otherwise.
///
/// [revisionItemId] — The ID in the revision system (e.g. 'fa-page-35', 'sketchy-micro-12')
/// [title] — Display title for the item
/// [source] — Source label like 'FA', 'SKETCHY_MICRO', etc.
/// [isKBEntry] — Set true for Knowledge Base entries (uses different marking method)
/// [kbPageNumber] — Required when [isKBEntry] is true
Future<bool?> showRevisionConfidenceSheet({
  required BuildContext context,
  required String revisionItemId,
  required String title,
  required String source,
  bool isKBEntry = false,
  String? kbPageNumber,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RevisionConfidenceSheet(
      revisionItemId: revisionItemId,
      title: title,
      source: source,
      isKBEntry: isKBEntry,
      kbPageNumber: kbPageNumber,
    ),
  );
}

class _RevisionConfidenceSheet extends StatefulWidget {
  final String revisionItemId;
  final String title;
  final String source;
  final bool isKBEntry;
  final String? kbPageNumber;

  const _RevisionConfidenceSheet({
    required this.revisionItemId,
    required this.title,
    required this.source,
    this.isKBEntry = false,
    this.kbPageNumber,
  });

  @override
  State<_RevisionConfidenceSheet> createState() =>
      _RevisionConfidenceSheetState();
}

class _RevisionConfidenceSheetState extends State<_RevisionConfidenceSheet> {
  bool _saving = false;

  RevisionItem? _findRevisionItem(AppProvider app) {
    return app.revisionItems
        .cast<RevisionItem?>()
        .firstWhere(
          (r) => r!.id == widget.revisionItemId,
          orElse: () => null,
        );
  }

  Future<void> _markRevised(String quality) async {
    if (_saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final app = context.read<AppProvider>();
      if (widget.isKBEntry && widget.kbPageNumber != null) {
        await app.markKBEntryWithConfidence(widget.kbPageNumber!, quality);
      } else {
        await app.markRevisionItemWithConfidence(
            widget.revisionItemId, quality);
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color _sourceColor() {
    switch (widget.source) {
      case 'FA':
        return const Color(0xFF3B82F6);
      case 'SKETCHY_MICRO':
        return const Color(0xFF10B981);
      case 'SKETCHY_PHARM':
        return const Color(0xFF8B5CF6);
      case 'PATHOMA':
        return const Color(0xFFEC4899);
      case 'UWORLD':
        return const Color(0xFFF59E0B);
      case 'KB':
        return const Color(0xFF14B8A6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _sourceIcon() {
    switch (widget.source) {
      case 'FA':
        return Icons.menu_book_rounded;
      case 'SKETCHY_MICRO':
        return Icons.biotech_rounded;
      case 'SKETCHY_PHARM':
        return Icons.medication_rounded;
      case 'PATHOMA':
        return Icons.science_rounded;
      case 'UWORLD':
        return Icons.quiz_rounded;
      case 'KB':
        return Icons.library_books_rounded;
      default:
        return Icons.book_rounded;
    }
  }

  String _sourceLabel() {
    switch (widget.source) {
      case 'FA':
        return 'First Aid';
      case 'SKETCHY_MICRO':
        return 'Sketchy Micro';
      case 'SKETCHY_PHARM':
        return 'Sketchy Pharm';
      case 'PATHOMA':
        return 'Pathoma';
      case 'UWORLD':
        return 'UWorld';
      case 'KB':
        return 'Knowledge Base';
      default:
        return widget.source;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final revItem = _findRevisionItem(app);
    final srcColor = _sourceColor();

    final glassBg = isDark
        ? const Color(0xFF0E0E1A).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.95);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: glassBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? DashboardColors.glassBorderDark
                  : DashboardColors.glassBorderLight,
              width: 0.5,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Source badge + title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              srcColor.withValues(alpha: isDark ? 0.15 : 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: srcColor.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child:
                            Icon(_sourceIcon(), size: 20, color: srcColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color:
                                    DashboardColors.textPrimary(isDark),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _sourceLabel(),
                              style: TextStyle(
                                fontSize: 12,
                                color: srcColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (revItem != null)
                        _ProgressRingSmall(
                          step: revItem.currentRevisionIndex,
                          total: revItem.totalSteps,
                          color: srcColor,
                          isDark: isDark,
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // "How well do you remember?" label
                  Text(
                    'How well do you remember?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DashboardColors.textPrimary(isDark)
                          .withValues(alpha: 0.7),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Confidence buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ConfidenceBtn(
                          label: 'Hard',
                          subtitle: 'Review sooner',
                          color: const Color(0xFFEF4444),
                          icon: Icons.replay_rounded,
                          isDark: isDark,
                          saving: _saving,
                          onTap: () => _markRevised('hard'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ConfidenceBtn(
                          label: 'Good',
                          subtitle: 'Normal pace',
                          color: DashboardColors.primary,
                          icon: Icons.check_rounded,
                          isDark: isDark,
                          saving: _saving,
                          onTap: () => _markRevised('good'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ConfidenceBtn(
                          label: 'Easy',
                          subtitle: 'Skip ahead',
                          color: const Color(0xFF10B981),
                          icon: Icons.fast_forward_rounded,
                          isDark: isDark,
                          saving: _saving,
                          onTap: () => _markRevised('easy'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Revision log summary (if available)
                  if (revItem != null && revItem.revisionLog.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DashboardColors.textPrimary(isDark)
                            .withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DashboardColors.textPrimary(isDark)
                              .withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 14,
                            color: DashboardColors.textPrimary(isDark)
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${revItem.revisionLog.length} previous revision${revItem.revisionLog.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: DashboardColors.textPrimary(isDark)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          const Spacer(),
                          if (revItem.retentionScore > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: srcColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Score: ${revItem.retentionScore}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: srcColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Small progress ring for the sheet header
// ══════════════════════════════════════════════════════════════════

class _ProgressRingSmall extends StatelessWidget {
  final int step;
  final int total;
  final Color color;
  final bool isDark;

  const _ProgressRingSmall({
    required this.step,
    required this.total,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? step / total : 0.0;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 3,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(
                DashboardColors.textPrimary(isDark).withValues(alpha: 0.06),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text(
            'R$step',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Confidence button
// ══════════════════════════════════════════════════════════════════

class _ConfidenceBtn extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool isDark;
  final bool saving;
  final VoidCallback onTap;

  const _ConfidenceBtn({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.isDark,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  )
                : Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
