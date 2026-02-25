// =============================================================
// FMGEEntryDetailScreen â€” full detail view for one FMGEEntry
// Shows subject, slide range, notes, revision timeline,
// "Mark Revised" button with 5-star tap row.
// Saves via AppProvider.upsertFMGEEntry().
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/fmge_entry.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/core/theme/app_colors.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';

class FMGEEntryDetailScreen extends StatelessWidget {
  final String entryId;

  const FMGEEntryDetailScreen({super.key, required this.entryId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final entry = app.fmgeEntries.cast<FMGEEntry?>().firstWhere(
          (e) => e!.id == entryId,
          orElse: () => null,
        );

    if (entry == null) {
      return AppScaffold(
        screenName: 'FMGE Detail',
        body: Center(
          child: Text('Entry not found',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.4))),
        ),
      );
    }

    const String mode = 'strict';
    final totalSteps = SrsService.totalSteps(mode);
    final masteredCount = entry.currentRevisionIndex.clamp(0, totalSteps);
    final masteryRatio = totalSteps > 0 ? masteredCount / totalSteps : 0.0;
    final isMastered = SrsService.isMastered(
        revisionIndex: entry.currentRevisionIndex, mode: mode);
    final isOverdue =
        SrsService.isDueNow(nextRevisionAt: entry.nextRevisionAt);

    final subjectColor = AppColors.subjectColors[
        entry.subject.hashCode.abs() % AppColors.subjectColors.length];

    return AppScaffold(
      screenName: 'FMGE Detail',
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // â”€â”€ Back â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded,
                  color: cs.onSurface.withValues(alpha: 0.6)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 4),

          // â”€â”€ Title â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Text(
            'Slides ${entry.slideStart}â€“${entry.slideEnd}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          // â”€â”€ Badges â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _Badge(label: entry.subject, color: subjectColor),
              _Badge(
                label: '${entry.revisionCount} revisions',
                color: cs.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // â”€â”€ Mastery card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionCard(
            title: 'Mastery Progress',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: masteryRatio,
                          minHeight: 6,
                          backgroundColor:
                              cs.onSurface.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation(
                            isMastered ? AppColors.success : cs.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$masteredCount / $totalSteps',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isMastered
                            ? AppColors.success
                            : cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isMastered)
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('Mastered!',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600)),
                    ],
                  )
                else if (isOverdue)
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text('Overdue for revision',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600)),
                    ],
                  )
                else if (entry.nextRevisionAt != null)
                  Text(
                    'Next revision: ${_formatDate(entry.nextRevisionAt!)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // â”€â”€ Mark Revised button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (!isMastered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showMarkRevisedDialog(context, entry),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Mark Revised'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // â”€â”€ Details card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionCard(
            title: 'Details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow('Subject', entry.subject),
                _DetailRow(
                    'Slide Range', '${entry.slideStart}â€“${entry.slideEnd}'),
                _DetailRow('Revision Count', '${entry.revisionCount}'),
                _DetailRow(
                    'Revision Index', '${entry.currentRevisionIndex}'),
                if (entry.lastStudiedAt != null)
                  _DetailRow(
                      'Last Studied', _formatDate(entry.lastStudiedAt!)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // â”€â”€ Notes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (entry.notes != null && entry.notes!.isNotEmpty)
            _SectionCard(
              title: 'Notes',
              child: Text(
                entry.notes!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
          if (entry.notes != null && entry.notes!.isNotEmpty)
            const SizedBox(height: 12),

          // â”€â”€ Revision Log Timeline â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionCard(
            title: 'Revision Log (${entry.logs.length})',
            child: entry.logs.isEmpty
                ? Text('No revisions yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ))
                : Column(
                    children: entry.logs.reversed
                        .map((log) => _FMGELogTile(log: log))
                        .toList(),
                  ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // â”€â”€ Mark Revised dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showMarkRevisedDialog(BuildContext context, FMGEEntry entry) {
    int score = 4;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          final theme = Theme.of(ctx);
          final cs = theme.colorScheme;
          return AlertDialog(
            backgroundColor: cs.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Rate Your Recall',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How well did you recall this topic?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    )),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starVal = i + 1;
                    return IconButton(
                      onPressed: () =>
                          setDialogState(() => score = starVal),
                      icon: Icon(
                        starVal <= score
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 32,
                        color: starVal <= score
                            ? AppColors.warning
                            : cs.onSurface.withValues(alpha: 0.2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  score >= 4
                      ? 'âœ… Counts toward mastery'
                      : 'âš ï¸ Won\'t advance mastery',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: score >= 4 ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancel',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.5))),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _markRevised(context, entry, score);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _markRevised(
      BuildContext context, FMGEEntry entry, int score) async {
    final app = context.read<AppProvider>();
    final now = DateTime.now();
    const String mode = 'strict';

    // Only advance revision index if score >= 4
    final newIndex =
        score >= 4 ? entry.currentRevisionIndex + 1 : entry.currentRevisionIndex;

    final nextRevision = SrsService.calculateNextRevisionDateString(
      lastStudiedAt: now.toIso8601String(),
      revisionIndex: newIndex,
      mode: mode,
    );

    final newLog = FMGELog(
      id: '${entry.id}_${now.millisecondsSinceEpoch}',
      timestamp: now.toIso8601String(),
      revisionIndex: newIndex,
      type: 'REVISION',
      notes: 'Score: $score/5',
      source: 'MODAL',
      slideStart: entry.slideStart,
      slideEnd: entry.slideEnd,
    );

    final updated = entry.copyWith(
      revisionCount: entry.revisionCount + 1,
      currentRevisionIndex: newIndex,
      lastStudiedAt: now.toIso8601String(),
      nextRevisionAt: nextRevision,
      logs: [...entry.logs, newLog],
    );

    await app.upsertFMGEEntry(updated);
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('d MMM yyyy, h:mm a').format(dt);
  }
}

// â”€â”€ Helper widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
                )),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}

class _FMGELogTile extends StatelessWidget {
  final FMGELog log;

  const _FMGELogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final dt = DateTime.tryParse(log.timestamp);
    final timeStr = dt != null
        ? DateFormat('d MMM yyyy, h:mm a').format(dt)
        : log.timestamp;

    final isRevision = log.type == 'REVISION';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRevision ? cs.primary : AppColors.success,
                ),
              ),
              Container(
                width: 2,
                height: 30,
                color: cs.onSurface.withValues(alpha: 0.08),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isRevision
                          ? 'Revision #${log.revisionIndex}'
                          : 'Initial Study',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeStr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                if (log.notes != null && log.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      log.notes!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Slides ${log.slideStart}â€“${log.slideEnd}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
