// =============================================================
// Pathoma Tab — Premium redesigned Pathoma chapters tab
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/pathoma_chapter.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/screens/library/library_item_detail_sheet.dart';
import 'package:focusflow_mobile/utils/show_app_bottom_sheet.dart';
import 'package:focusflow_mobile/screens/revision_hub/revision_confidence_sheet.dart';
import 'package:focusflow_mobile/screens/tracker/tracker_sheets.dart';

class PathomaTab extends StatelessWidget {
  final AppProvider app;
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;
  final String searchQuery;

  const PathomaTab({
    super.key,
    required this.app,
    required this.selectionMode,
    required this.selectedItems,
    required this.onToggleSelect,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (app.pathomaChapters.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.biotech_rounded,
              size: 56,
              color: DashboardColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Pathoma chapters loaded',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DashboardColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Import your Pathoma data to get started',
              style: TextStyle(
                fontSize: 13,
                color: DashboardColors.textPrimary(isDark)
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    var chapters = List<PathomaChapter>.from(app.pathomaChapters)
      ..sort((a, b) => a.chapter.compareTo(b.chapter));

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      chapters = chapters
          .where((c) =>
              c.title.toLowerCase().contains(q) ||
              'chapter ${c.chapter}'.contains(q))
          .toList();
    }

    final watchedCount = app.pathomaChapters.where((c) => c.watched).length;
    final totalCount = app.pathomaChapters.length;

    return Column(
      children: [
        // ── Progress header ─────────────────────────────
        _PathomaProgressHeader(
          watchedCount: watchedCount,
          totalCount: totalCount,
          isDark: isDark,
        ),

        // ── Chapter list ────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 72 + 24,
              top: 4,
            ),
            itemCount: chapters.length,
            itemBuilder: (context, i) =>
                _buildChapterTile(context, chapters[i], isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildChapterTile(
      BuildContext context, PathomaChapter chapter, bool isDark) {
    final key = 'pathoma:${chapter.id}';
    final isSelected = selectedItems.contains(key);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Slidable(
        key: ValueKey(key),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: slidableActionExtentRatio,
          children: [
            SlidableAction(
              onPressed: (_) =>
                  app.togglePathomaChapterWatched(chapter.id!, !chapter.watched),
              backgroundColor: chapter.watched
                  ? DashboardColors.warning
                  : DashboardColors.success,
              foregroundColor: Colors.white,
              icon:
                  chapter.watched ? Icons.undo_rounded : Icons.check_rounded,
              label: chapter.watched ? 'Undo' : 'Done',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Material(
              color: isSelected
                  ? DashboardColors.primary.withValues(alpha: 0.08)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: selectionMode
                    ? () => onToggleSelect(key)
                    : () {
                        showAppBottomSheet(
                          context: context,
                          initialChildSize: 0.9,
                          minChildSize: 0.5,
                          maxChildSize: 0.95,
                          builder: (_, __) => LibraryItemDetailSheet(
                            app: app,
                            item: chapter,
                            itemType: 'pathoma',
                          ),
                        );
                      },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? DashboardColors.primary
                          : DashboardColors.glassBorder(isDark),
                      width: isSelected ? 2 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (selectionMode) ...[
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected
                              ? DashboardColors.primary
                              : DashboardColors.textPrimary(isDark)
                                  .withValues(alpha: 0.3),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                      ],
                      // Chapter number badge
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: chapter.watched
                                ? [
                                    DashboardColors.success
                                        .withValues(alpha: 0.15),
                                    DashboardColors.success
                                        .withValues(alpha: 0.08),
                                  ]
                                : [
                                    DashboardColors.primary
                                        .withValues(alpha: 0.12),
                                    DashboardColors.primaryViolet
                                        .withValues(alpha: 0.08),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: chapter.watched
                                ? DashboardColors.success
                                    .withValues(alpha: 0.3)
                                : DashboardColors.primary
                                    .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${chapter.chapter}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: chapter.watched
                                  ? DashboardColors.success
                                  : DashboardColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapter.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: DashboardColors.textPrimary(isDark),
                                decoration: chapter.watched
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Chapter ${chapter.chapter}',
                              style: TextStyle(
                                fontSize: 11,
                                color: DashboardColors.textPrimary(isDark)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Revision badge
                      Builder(builder: (context) {
                        final revId = 'pathoma-ch-${chapter.id}';
                        final revItem = app.revisionItems.cast<dynamic>().firstWhere(
                              (r) => r.id == revId,
                              orElse: () => null,
                            );
                        if (revItem != null && chapter.watched) {
                          final revIndex = revItem.currentRevisionIndex as int;
                          return Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  DashboardColors.primary,
                                  DashboardColors.primaryViolet,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: DashboardColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  spreadRadius: -1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'R$revIndex',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      const SizedBox(width: 6),
                      // Status badge
                      InkWell(
                        onTap: selectionMode
                            ? null
                            : () async {
                                if (!chapter.watched) {
                                  final proceed =
                                      await confirmTodayTaskConflictForLibraryItem(
                                    context: context,
                                    app: app,
                                    itemId: chapter.id!,
                                    candidateTitles: [
                                      chapter.title,
                                      'Pathoma Ch${chapter.chapter}: ${chapter.title}',
                                    ],
                                  );
                                  if (!proceed || !context.mounted) return;
                                  app.togglePathomaChapterWatched(
                                      chapter.id!, true);
                                } else {
                                  final revId = 'pathoma-${chapter.id}';
                                  final hasRev = app.revisionItems
                                      .any((r) => r.id == revId);
                                  if (hasRev) {
                                    showRevisionConfidenceSheet(
                                      context: context,
                                      revisionItemId: revId,
                                      title: chapter.title,
                                      source: 'Pathoma',
                                    );
                                  } else {
                                    app.togglePathomaChapterWatched(
                                        chapter.id!, false);
                                  }
                                }
                              },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: chapter.watched
                                ? DashboardColors.success
                                    .withValues(alpha: 0.12)
                                : isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: chapter.watched
                                  ? DashboardColors.success
                                      .withValues(alpha: 0.3)
                                  : Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            chapter.watched ? 'Watched ✓' : 'Not Watched',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: chapter.watched
                                  ? DashboardColors.success
                                  : DashboardColors.textPrimary(isDark)
                                      .withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Progress header ────────────────────────────────────────────

class _PathomaProgressHeader extends StatelessWidget {
  final int watchedCount;
  final int totalCount;
  final bool isDark;

  const _PathomaProgressHeader({
    required this.watchedCount,
    required this.totalCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? watchedCount / totalCount : 0.0;
    final textColor = DashboardColors.textPrimary(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DashboardColors.glassBorder(isDark),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          strokeCap: StrokeCap.round,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.orange.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.deepOrange),
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$watchedCount / $totalCount chapters',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${totalCount - watchedCount} remaining',
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.biotech_rounded,
                  size: 32,
                  color: Colors.deepOrange.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
