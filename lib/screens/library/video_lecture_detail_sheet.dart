// =============================================================
// VideoLectureDetailSheet — Detail view for a video lecture
// Shows draggable time slider, progress, revision info, notes
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/video_lecture.dart';
import 'package:focusflow_mobile/models/revision_item.dart';
import 'package:focusflow_mobile/models/activity_log.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/screens/revision_hub/revision_confidence_sheet.dart';

class VideoLectureDetailSheet extends StatefulWidget {
  final AppProvider app;
  final VideoLecture lecture;

  const VideoLectureDetailSheet({
    super.key,
    required this.app,
    required this.lecture,
  });

  @override
  State<VideoLectureDetailSheet> createState() =>
      _VideoLectureDetailSheetState();
}

class _VideoLectureDetailSheetState extends State<VideoLectureDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late int _sliderValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _sliderValue = widget.lecture.watchedMinutes;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  VideoLecture _getCurrentLecture(AppProvider app) {
    return app.videoLectures.firstWhere(
      (v) => v.id == widget.lecture.id,
      orElse: () => widget.lecture,
    );
  }

  RevisionItem? _getRevisionItem(AppProvider app) {
    final revId = 'video-lecture-${widget.lecture.id}';
    return app.revisionItems.cast<RevisionItem?>().firstWhere(
          (r) => r!.id == revId,
          orElse: () => null,
        );
  }

  void _onSliderChanged(double val) {
    setState(() => _sliderValue = val.round());
  }

  void _onSliderEnd(double val) {
    final app = context.read<AppProvider>();
    app.updateVideoLectureProgress(widget.lecture.id!, val.round());
    if (val.round() >= widget.lecture.durationMinutes) {
      HapticFeedback.mediumImpact();
    }
    setState(() => _isDragging = false);
  }

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
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lecture = _getCurrentLecture(app);
    final textColor = DashboardColors.textPrimary(isDark);
    final revItem = _getRevisionItem(app);
    const accentColor = Color(0xFFF59E0B);

    final currentProgress = _isDragging ? _sliderValue : lecture.watchedMinutes;
    final progressPercent = lecture.durationMinutes > 0
        ? (currentProgress / lecture.durationMinutes).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────
          Row(
            children: [
              // Video icon badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.15 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  Icons.ondemand_video_rounded,
                  size: 22,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lecture.customTitle ?? lecture.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          lecture.subject,
                          style: TextStyle(
                            fontSize: 12,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (lecture.isComplete) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: DashboardColors.success,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (revItem != null)
                _RevisionBadge(
                  revItem: revItem,
                  color: accentColor,
                  isDark: isDark,
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Time Slider ───────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: DashboardColors.glassBorder(isDark),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Watch Progress',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(progressPercent * 100).round()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 6,
                        activeTrackColor: lecture.isComplete
                            ? DashboardColors.success
                            : accentColor,
                        inactiveTrackColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        thumbColor: lecture.isComplete
                            ? DashboardColors.success
                            : accentColor,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 16),
                        overlayColor: accentColor.withValues(alpha: 0.15),
                      ),
                      child: Slider(
                        value: currentProgress.toDouble(),
                        min: 0,
                        max: lecture.durationMinutes.toDouble(),
                        divisions: lecture.durationMinutes > 0
                            ? lecture.durationMinutes
                            : 1,
                        onChangeStart: (_) =>
                            setState(() => _isDragging = true),
                        onChanged: _onSliderChanged,
                        onChangeEnd: _onSliderEnd,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatMinutes(currentProgress),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          _formatMinutes(lecture.durationMinutes),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Quick Actions ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: lecture.isComplete ? 'Mark Unwatched' : 'Mark Watched',
                  icon: lecture.isComplete
                      ? Icons.undo_rounded
                      : Icons.check_rounded,
                  color: lecture.isComplete
                      ? DashboardColors.warning
                      : DashboardColors.success,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    app.toggleVideoLectureWatched(
                        lecture.id!, !lecture.isComplete);
                    setState(() {
                      if (!lecture.isComplete) {
                        _sliderValue = lecture.durationMinutes;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              if (lecture.isComplete)
                Expanded(
                  child: _ActionButton(
                    label: 'Watched Again',
                    icon: Icons.replay_rounded,
                    color: DashboardColors.primary,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      final revId = 'video-lecture-${lecture.id}';
                      showRevisionConfidenceSheet(
                        context: context,
                        revisionItemId: revId,
                        title: lecture.title,
                        source: 'VIDEO_LECTURE',
                      );
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Info Cards ────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: 'Duration',
                value: lecture.durationLabel,
                icon: Icons.timer_outlined,
                isDark: isDark,
              ),
              _InfoChip(
                label: 'Watched',
                value: _formatMinutes(lecture.watchedMinutes),
                icon: Icons.play_circle_outline_rounded,
                isDark: isDark,
              ),
              if (revItem != null)
                _InfoChip(
                  label: 'Revision',
                  value: 'R${revItem.currentRevisionIndex}',
                  icon: Icons.repeat_rounded,
                  isDark: isDark,
                ),
              _InfoChip(
                label: 'Progress',
                value: '${(lecture.progressPercent * 100).round()}%',
                icon: Icons.trending_up_rounded,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Tabs ──────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: textColor,
              unselectedLabelColor: textColor.withValues(alpha: 0.4),
              labelStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'History & Progress'),
                Tab(text: 'Details'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Tab content ───────────────────────────────
          SizedBox(
            height: 260,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // History & Progress tab
                _HistoryTab(
                  lecture: lecture,
                  revItem: revItem,
                  app: app,
                  isDark: isDark,
                ),
                // Details tab
                _DetailsTab(
                  lecture: lecture,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Subwidgets
// ────────────────────────────────────────────────────────────────

class _RevisionBadge extends StatelessWidget {
  final RevisionItem revItem;
  final Color color;
  final bool isDark;

  const _RevisionBadge({
    required this.revItem,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = revItem.totalSteps > 0
        ? revItem.currentRevisionIndex / revItem.totalSteps
        : 0.0;
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
            'R${revItem.currentRevisionIndex}',
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = DashboardColors.textPrimary(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: textColor.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor.withValues(alpha: 0.4)),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              color: textColor.withValues(alpha: 0.4),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── History Tab ────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final VideoLecture lecture;
  final RevisionItem? revItem;
  final AppProvider app;
  final bool isDark;

  const _HistoryTab({
    required this.lecture,
    required this.revItem,
    required this.app,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = DashboardColors.textPrimary(isDark);
    final itemId = 'video-lecture:${lecture.id}';

    return FutureBuilder<List<ActivityLogEntry>>(
      future: app.getActivityLogs(itemId),
      builder: (ctx, snapshot) {
        final logs = snapshot.data ?? [];
        final hasRevisionLog = revItem != null && revItem!.revisionLog.isNotEmpty;

        if (logs.isEmpty && !hasRevisionLog) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 32,
                  color: textColor.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 8),
                Text(
                  'No activity yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }

        // Combine revision log entries and activity logs into a single timeline
        final entries = <_TimelineEntry>[];

        // Activity logs
        for (final log in logs) {
          entries.add(_TimelineEntry(
            date: DateTime.tryParse(log.timestamp) ?? DateTime.now(),
            icon: log.action == 'watched'
                ? Icons.check_circle_rounded
                : Icons.undo_rounded,
            color: log.action == 'watched'
                ? DashboardColors.success
                : DashboardColors.warning,
            label: log.action == 'watched' ? 'Watched' : 'Unwatched',
          ));
        }

        // Revision log entries
        if (hasRevisionLog) {
          for (final entry in revItem!.revisionLog) {
            entries.add(_TimelineEntry(
              date: DateTime.tryParse(entry.actualAt) ?? DateTime.now(),
              icon: Icons.replay_rounded,
              color: entry.response == 'hard'
                  ? const Color(0xFFEF4444)
                  : entry.response == 'easy'
                      ? DashboardColors.success
                      : DashboardColors.primary,
              label:
                  'Revision ${entry.response[0].toUpperCase()}${entry.response.substring(1)}',
            ));
          }
        }

        entries.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: entries.length,
          itemBuilder: (ctx, i) {
            final e = entries[i];
            final timeAgo = _formatTimeAgo(e.date);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: e.color.withValues(alpha: 0.12),
                    ),
                    child: Icon(e.icon, size: 14, color: e.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _TimelineEntry {
  final DateTime date;
  final IconData icon;
  final Color color;
  final String label;

  const _TimelineEntry({
    required this.date,
    required this.icon,
    required this.color,
    required this.label,
  });
}

// ── Details Tab ───────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  final VideoLecture lecture;
  final bool isDark;

  const _DetailsTab({
    required this.lecture,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = DashboardColors.textPrimary(isDark);

    final details = [
      ('Subject', lecture.subject),
      ('Title', lecture.title),
      ('Duration', lecture.durationLabel),
      ('Watched', lecture.watchedLabel),
      ('Remaining', lecture.remainingLabel),
      ('Status', lecture.isComplete ? 'Complete' : 'In Progress'),
    ];

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: details.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: textColor.withValues(alpha: 0.06),
      ),
      itemBuilder: (ctx, i) {
        final (label, value) = details[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
