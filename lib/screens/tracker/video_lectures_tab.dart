// =============================================================
// VideoLecturesTab — Video lectures grouped by subject
// PSM | Ophthalmology | ENT (and more subjects later)
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/video_lecture.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/utils/show_app_bottom_sheet.dart';
import 'package:focusflow_mobile/screens/library/video_lecture_detail_sheet.dart';
import 'package:focusflow_mobile/screens/revision_hub/revision_confidence_sheet.dart';
import 'package:focusflow_mobile/screens/tracker/tracker_sheets.dart';

class VideoLecturesTab extends StatelessWidget {
  final AppProvider app;
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;
  final String searchQuery;

  const VideoLecturesTab({
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
    final lectures = app.videoLectures;

    if (lectures.isEmpty) {
      return _VideoLecturesEmptyState();
    }

    // Filter by search
    var filtered = List<VideoLecture>.from(lectures);
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered
          .where((v) =>
              v.title.toLowerCase().contains(q) ||
              v.subject.toLowerCase().contains(q))
          .toList();
    }

    // Group by subject
    final subjectOrder = <String>[];
    final grouped = <String, List<VideoLecture>>{};
    for (final v in filtered) {
      if (!grouped.containsKey(v.subject)) {
        subjectOrder.add(v.subject);
        grouped[v.subject] = [];
      }
      grouped[v.subject]!.add(v);
    }

    // Calculate totals
    final watchedCount = lectures.where((v) => v.isComplete).length;
    final totalCount = lectures.length;
    final totalMinutes = lectures.fold<int>(0, (sum, v) => sum + v.durationMinutes);
    final watchedMinutes = lectures.fold<int>(0, (sum, v) => sum + v.watchedMinutes);

    return Column(
      children: [
        // ── Progress header ─────────────────────────────
        _VideoProgressHeader(
          watchedCount: watchedCount,
          totalCount: totalCount,
          totalMinutes: totalMinutes,
          watchedMinutes: watchedMinutes,
          isDark: isDark,
        ),

        // ── Subject groups ──────────────────────────────
        Expanded(
          child: subjectOrder.isEmpty
              ? Center(
                  child: Text(
                    'No matching videos',
                    style: TextStyle(
                      color: DashboardColors.textPrimary(isDark)
                          .withValues(alpha: 0.5),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 72 + 24,
                    top: 8,
                  ),
                  itemCount: subjectOrder.length,
                  itemBuilder: (context, i) {
                    final subject = subjectOrder[i];
                    final subjectLectures = grouped[subject]!;
                    return _SubjectGroup(
                      subject: subject,
                      lectures: subjectLectures,
                      app: app,
                      selectionMode: selectionMode,
                      selectedItems: selectedItems,
                      onToggleSelect: onToggleSelect,
                      isDark: isDark,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Progress header ────────────────────────────────────────────

class _VideoProgressHeader extends StatelessWidget {
  final int watchedCount;
  final int totalCount;
  final int totalMinutes;
  final int watchedMinutes;
  final bool isDark;

  const _VideoProgressHeader({
    required this.watchedCount,
    required this.totalCount,
    required this.totalMinutes,
    required this.watchedMinutes,
    required this.isDark,
  });

  String _formatMinutes(int min) {
    if (min >= 60) {
      final h = min ~/ 60;
      final m = min % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${min}m';
  }

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? watchedCount / totalCount : 0.0;
    final textColor = DashboardColors.textPrimary(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                // Progress ring
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
                              : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFF59E0B),
                          ),
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
                        '$watchedCount / $totalCount lectures',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatMinutes(watchedMinutes)} / ${_formatMinutes(totalMinutes)} watched',
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.ondemand_video_rounded,
                  size: 32,
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Subject group ──────────────────────────────────────────────

class _SubjectGroup extends StatelessWidget {
  final String subject;
  final List<VideoLecture> lectures;
  final AppProvider app;
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;
  final bool isDark;

  const _SubjectGroup({
    required this.subject,
    required this.lectures,
    required this.app,
    required this.selectionMode,
    required this.selectedItems,
    required this.onToggleSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final watchedInSubject = lectures.where((v) => v.isComplete).length;
    final totalMinutes = lectures.fold<int>(0, (s, v) => s + v.durationMinutes);
    final watchedMinutes = lectures.fold<int>(0, (s, v) => s + v.watchedMinutes);
    final subjectProgress = totalMinutes > 0 ? watchedMinutes / totalMinutes : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DashboardColors.glassBorder(isDark),
              width: 0.5,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              title: Text(
                subject,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.textPrimary(isDark),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: subjectProgress,
                        minHeight: 3,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          subjectProgress >= 1.0
                              ? DashboardColors.success
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(subjectProgress * 100).round()}% • ${lectures.length} Videos',
                      style: TextStyle(
                        fontSize: 10,
                        color: DashboardColors.textPrimary(isDark)
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$watchedInSubject/${lectures.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DashboardColors.textPrimary(isDark)
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: DashboardColors.textPrimary(isDark)
                        .withValues(alpha: 0.3),
                  ),
                ],
              ),
              children: lectures
                  .map((lecture) => _buildLectureTile(context, lecture))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLectureTile(BuildContext context, VideoLecture lecture) {
    final key = 'video-lecture:${lecture.id}';
    final isSelected = selectedItems.contains(key);

    // Check for revision item
    final revId = 'video-lecture-${lecture.id}';
    final revItem = app.revisionItems.cast<dynamic>().firstWhere(
          (r) => r.id == revId,
          orElse: () => null,
        );
    final hasRevision = revItem != null;
    final revIndex = hasRevision ? revItem.currentRevisionIndex as int : 0;

    return Slidable(
      key: ValueKey(key),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: slidableActionExtentRatio,
        children: [
          SlidableAction(
            onPressed: (_) =>
                app.toggleVideoLectureWatched(lecture.id!, !lecture.watched),
            backgroundColor: lecture.watched
                ? DashboardColors.warning
                : DashboardColors.success,
            foregroundColor: Colors.white,
            icon: lecture.watched ? Icons.undo_rounded : Icons.check_rounded,
            label: lecture.watched ? 'Undo' : 'Done',
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        dense: true,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lecture.customTitle ?? lecture.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: DashboardColors.textPrimary(isDark),
                            decoration: lecture.isComplete
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Revision badge
                      if (hasRevision && lecture.isComplete) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 22,
                          height: 22,
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
                                color: DashboardColors.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 4,
                                spreadRadius: -1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'R$revIndex',
                              style: const TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Time progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: lecture.progressPercent,
                            minHeight: 3,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.06),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              lecture.isComplete
                                  ? DashboardColors.success
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lecture.isComplete
                            ? lecture.durationLabel
                            : lecture.remainingLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: lecture.isComplete
                              ? DashboardColors.success
                              : DashboardColors.textPrimary(isDark)
                                  .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: selectionMode
            ? Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected
                    ? DashboardColors.primary
                    : DashboardColors.textPrimary(isDark)
                        .withValues(alpha: 0.3),
                size: 20,
              )
            : null,
        trailing: InkWell(
          onTap: () async {
            if (!lecture.isComplete) {
              // Mark as watched
              final proceed = await confirmTodayTaskConflictForLibraryItem(
                context: context,
                app: app,
                itemId: lecture.id!,
                candidateTitles: [
                  lecture.title,
                  '${lecture.subject}: ${lecture.title}',
                ],
              );
              if (!proceed || !context.mounted) return;
              app.toggleVideoLectureWatched(lecture.id!, true);
            } else {
              // Already watched — show revision confidence
              final revId = 'video-lecture-${lecture.id}';
              final hasRev = app.revisionItems.any((r) => r.id == revId);
              if (hasRev) {
                showRevisionConfidenceSheet(
                  context: context,
                  revisionItemId: revId,
                  title: lecture.title,
                  source: 'VIDEO_LECTURE',
                );
              } else {
                app.toggleVideoLectureWatched(lecture.id!, false);
              }
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: lecture.isComplete
                  ? DashboardColors.success.withValues(alpha: 0.12)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: lecture.isComplete
                    ? DashboardColors.success.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              lecture.isComplete ? 'Watched ✓' : 'Not Watched',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: lecture.isComplete
                    ? DashboardColors.success
                    : DashboardColors.textPrimary(isDark)
                        .withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        onTap: selectionMode
            ? () => onToggleSelect(key)
            : () {
                showAppBottomSheet(
                  context: context,
                  initialChildSize: 0.9,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  builder: (_, __) => VideoLectureDetailSheet(
                    app: app,
                    lecture: lecture,
                  ),
                );
              },
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────

class _VideoLecturesEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.ondemand_video_rounded,
            size: 56,
            color: DashboardColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No video lectures loaded',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DashboardColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Video lecture data will appear here once loaded',
            style: TextStyle(
              fontSize: 13,
              color:
                  DashboardColors.textPrimary(isDark).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
