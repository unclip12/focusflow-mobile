// =============================================================
// KBEntryDetailScreen â€” full detail view for one KnowledgeBaseEntry
// Shows all fields, topics list, revision log timeline,
// "Mark Revised" button, "Add Note" FAB.
// Keyed by pageNumber (never id).
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/utils/text_sanitizer.dart';
import 'package:focusflow_mobile/models/knowledge_base.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/core/theme/app_colors.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';

class KBEntryDetailScreen extends StatelessWidget {
  /// Primary key â€” we look up the entry by [pageNumber].
  final String pageNumber;

  const KBEntryDetailScreen({super.key, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final entry = app.knowledgeBase.cast<KnowledgeBaseEntry?>().firstWhere(
          (e) => e!.pageNumber == pageNumber,
          orElse: () => null,
        );

    if (entry == null) {
      return AppScaffold(
        screenName: 'KB Detail',
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

    return AppScaffold(
      screenName: 'Page ${TextSanitizer.clean(entry.pageNumber)}',
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'kb_add_note',
        backgroundColor: cs.primary,
        onPressed: () => _showAddNoteDialog(context, entry),
        child: const Icon(Icons.note_add_rounded, size: 20),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // â”€â”€ Back button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded,
                  color: cs.onSurface.withValues(alpha: 0.6)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 4),

          // â”€â”€ Title & page number â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Text(
            TextSanitizer.clean(entry.title),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _Badge(label: 'Page ${TextSanitizer.clean(entry.pageNumber)}', color: cs.primary),
              const SizedBox(width: 6),
              _Badge(
                  label: TextSanitizer.clean(entry.subject),
                  color: AppColors.subjectColors[
                      entry.subject.hashCode.abs() %
                          AppColors.subjectColors.length]),
              const SizedBox(width: 6),
              _Badge(
                  label: TextSanitizer.clean(entry.system),
                  color: cs.onSurface.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 16),

          // â”€â”€ Mastery card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

          // â”€â”€ Mark Revised button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

          // â”€â”€ Details card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionCard(
            title: 'Details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow('Revision Count', '${entry.revisionCount}'),
                if (entry.firstStudiedAt != null)
                  _DetailRow(
                      'First Studied', _formatDate(entry.firstStudiedAt!)),
                if (entry.lastStudiedAt != null)
                  _DetailRow(
                      'Last Studied', _formatDate(entry.lastStudiedAt!)),
                _DetailRow('Anki', '${entry.ankiCovered}/${entry.ankiTotal}'),
                if (entry.ankiTag != null)
                  _DetailRow('Anki Tag', TextSanitizer.clean(entry.ankiTag!)),
                if (entry.tags.isNotEmpty)
                  _DetailRow('Tags', TextSanitizer.clean(entry.tags.join(', '))),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // â”€â”€ Notes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (entry.notes.isNotEmpty)
            _SectionCard(
              title: 'Notes',
              child: Text(
                TextSanitizer.clean(entry.notes),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
          if (entry.notes.isNotEmpty) const SizedBox(height: 12),

          // â”€â”€ Key Points â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (entry.keyPoints != null && entry.keyPoints!.isNotEmpty)
            _SectionCard(
              title: 'Key Points',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entry.keyPoints!
                    .map((k) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('â€¢ ',
                                  style: TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700)),
                              Expanded(
                                child: Text(TextSanitizer.clean(k),
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                            color: cs.onSurface
                                                .withValues(alpha: 0.7))),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          if (entry.keyPoints != null && entry.keyPoints!.isNotEmpty)
            const SizedBox(height: 12),

          // â”€â”€ Topics (quiz questions list) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (entry.topics.isNotEmpty) ...[
            _SectionCard(
              title: 'Topics',
              child: Column(
                children: entry.topics
                    .map((t) => _TopicTile(topic: t))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // â”€â”€ Video Links â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (entry.videoLinks.isNotEmpty) ...[
            _SectionCard(
              title: 'Video Resources',
              child: Column(
                children: entry.videoLinks
                    .map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(Icons.play_circle_outline_rounded,
                                  size: 18, color: cs.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  TextSanitizer.clean(v.title.isNotEmpty ? v.title : v.url),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // â”€â”€ Revision Log Timeline â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionCard(
            title: 'Revision Log (${entry.logs.length})',
            child: entry.logs.isEmpty
                ? Text('No revisions yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ))
                : Column(
                    children: entry.logs.reversed
                        .map((log) => _RevisionLogTile(log: log))
                        .toList(),
                  ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // â”€â”€ Mark Revised dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showMarkRevisedDialog(
      BuildContext context, KnowledgeBaseEntry entry) {
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
                Text('How well did you recall this page?',
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
      BuildContext context, KnowledgeBaseEntry entry, int score) async {
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

    final newLog = RevisionLog(
      id: '${entry.pageNumber}_${now.millisecondsSinceEpoch}',
      timestamp: now.toIso8601String(),
      revisionIndex: newIndex,
      type: 'REVISION',
      notes: 'Score: $score/5',
      source: 'MODAL',
    );

    final updated = entry.copyWith(
      revisionCount: entry.revisionCount + 1,
      currentRevisionIndex: newIndex,
      lastStudiedAt: now.toIso8601String(),
      nextRevisionAt: nextRevision,
      logs: [...entry.logs, newLog],
    );

    await app.upsertKBEntry(updated);
  }

  // â”€â”€ Add Note dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showAddNoteDialog(BuildContext context, KnowledgeBaseEntry entry) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add Note',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          content: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Write a noteâ€¦',
              hintStyle: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.3)),
              filled: true,
              fillColor: cs.onSurface.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style:
                      TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                final newNote = entry.notes.isEmpty
                    ? controller.text.trim()
                    : '${entry.notes}\n\n${controller.text.trim()}';
                final updated = entry.copyWith(notes: newNote);
                context.read<AppProvider>().upsertKBEntry(updated);
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
      },
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? DashboardColors.glassBorderDark
                  : DashboardColors.glassBorderLight,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textPrimary(isDark),
                  )),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
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

class _TopicTile extends StatelessWidget {
  final TrackableItem topic;

  const _TopicTile({required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(TextSanitizer.clean(topic.name),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          if (topic.logs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${topic.revisionCount} revisions â€¢ Index ${topic.currentRevisionIndex}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          if (topic.subTopics != null && topic.subTopics!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: topic.subTopics!
                    .map((st) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'â†³ ${TextSanitizer.clean(st.name)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _RevisionLogTile extends StatelessWidget {
  final RevisionLog log;

  const _RevisionLogTile({required this.log});

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
                      isRevision ? 'Revision #${log.revisionIndex}' : 'Initial Study',
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
                      TextSanitizer.clean(log.notes!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
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
