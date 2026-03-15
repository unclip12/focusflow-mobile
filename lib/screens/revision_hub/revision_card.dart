// =============================================================
// UnifiedRevisionCard — Premium liquid glass revision card
// Features: progress ring, urgency stripe, confidence buttons,
// swipe gestures, expandable details, shimmer effects,
// revision log viewer, retention score, hard count display
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/models/revision_item.dart';
import 'revision_hub_screen.dart';

class UnifiedRevisionCard extends StatefulWidget {
  final RevisionDisplayItem item;
  final Duration delay;

  const UnifiedRevisionCard({
    super.key,
    required this.item,
    this.delay = Duration.zero,
  });

  @override
  State<UnifiedRevisionCard> createState() => _UnifiedRevisionCardState();
}

class _UnifiedRevisionCardState extends State<UnifiedRevisionCard>
    with TickerProviderStateMixin {
  bool _saving = false;
  bool _expanded = false;
  bool _showLogs = false;
  late final AnimationController _expandController;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnim = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  Future<void> _markRevised({String quality = 'good'}) async {
    if (_saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final app = context.read<AppProvider>();
      if (widget.item.isKBEntry) {
        // Extract page number from id (format: "kb-{pageNumber}")
        final pageNumber = widget.item.id.replaceFirst('kb-', '');
        await app.markKBEntryWithConfidence(pageNumber, quality);
      } else {
        await app.markRevisionItemWithConfidence(widget.item.id, quality);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleExpand() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
        _showLogs = false;
      }
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final due = item.dueInfo;
    final isOverdue = due.color == const Color(0xFFEF4444);

    final glassBg = isDark
        ? const Color(0xFF1E1E3A).withValues(alpha: 0.30)
        : Colors.white.withValues(alpha: 0.40);
    final borderCol = isDark
        ? const Color(0xFF6366F1).withValues(alpha: 0.25)
        : const Color(0xFF6366F1).withValues(alpha: 0.15);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + widget.delay.inMilliseconds),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Transform.scale(
              scale: 0.95 + (0.05 * value),
              child: child,
            ),
          ),
        );
      },
      child: Dismissible(
        key: ValueKey(item.id),
        background: _SwipeBackground(
          color: const Color(0xFF10B981),
          icon: Icons.check_rounded,
          label: 'Revised',
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: _SwipeBackground(
          color: const Color(0xFFF59E0B),
          icon: Icons.schedule_rounded,
          label: 'Skip',
          alignment: Alignment.centerRight,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await _markRevised(quality: 'good');
            return false;
          }
          return false;
        },
        child: GestureDetector(
          onTap: _toggleExpand,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: glassBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderCol, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: item.sourceColor
                            .withValues(alpha: isDark ? 0.12 : 0.08),
                        blurRadius: 20,
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // ── Inner gradient overlay ─────────────────
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(
                                      alpha: isDark ? 0.08 : 0.25),
                                  Colors.transparent,
                                  item.sourceColor.withValues(
                                      alpha: isDark ? 0.04 : 0.02),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Urgency left stripe ───────────────────
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 3.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                due.color.withValues(alpha: 0.9),
                                due.color.withValues(alpha: 0.4),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(18),
                              bottomLeft: Radius.circular(18),
                            ),
                          ),
                        ),
                      ),

                      // ── Card content ──────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row: source icon + title + progress ring
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SourceBadge(
                                  icon: item.sourceIcon,
                                  color: item.sourceColor,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.displayTitle,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: DashboardColors.textPrimary(isDark),
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item.parentTitle.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.subdirectory_arrow_right_rounded,
                                                size: 10,
                                                color: DashboardColors.textPrimary(isDark)
                                                    .withValues(alpha: 0.3),
                                              ),
                                              const SizedBox(width: 2),
                                              Flexible(
                                                child: Text(
                                                  item.parentTitle,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: DashboardColors.textPrimary(isDark)
                                                        .withValues(alpha: 0.45),
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
                                ),
                                const SizedBox(width: 8),
                                _ProgressRing(
                                  progress: item.progressPercent,
                                  step: item.currentRevisionIndex,
                                  total: item.totalSteps,
                                  hardCount: item.hardCount,
                                  easyFlag: item.easyFlag,
                                  color: item.sourceColor,
                                  isDark: isDark,
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Chips row
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _GlassChip(
                                  label: item.sourceLabel,
                                  color: item.sourceColor,
                                  isDark: isDark,
                                  icon: item.sourceIcon,
                                ),
                                _GlassChip(
                                  label: due.label,
                                  color: due.color,
                                  isDark: isDark,
                                  icon: isOverdue
                                      ? Icons.warning_amber_rounded
                                      : Icons.schedule_rounded,
                                ),
                                // Retention score badge
                                _RetentionBadge(
                                  score: item.retentionScore,
                                  isDark: isDark,
                                ),
                                if (due.timeDetail.isNotEmpty)
                                  _InfoPill(
                                    icon: Icons.access_time_rounded,
                                    text: due.timeDetail,
                                    isDark: isDark,
                                  ),
                              ],
                            ),

                            // ── Expandable section ──────────────
                            SizeTransition(
                              sizeFactor: _expandAnim,
                              axisAlignment: -1,
                              child: _ExpandedDetails(
                                item: item,
                                isDark: isDark,
                                onRevise: _markRevised,
                                saving: _saving,
                                showLogs: _showLogs,
                                onToggleLogs: () => setState(
                                    () => _showLogs = !_showLogs),
                              ),
                            ),

                            // ── Quick mark revised button (collapsed) ──
                            if (!_expanded) ...[
                              const SizedBox(height: 10),
                              _MarkRevisedButton(
                                saving: _saving,
                                onTap: () => _markRevised(quality: 'good'),
                                isDark: isDark,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ── Expand indicator ──────────────────────
                      Positioned(
                        right: 8,
                        bottom: 4,
                        child: AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: DashboardColors.textPrimary(isDark)
                                .withValues(alpha: 0.25),
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

// ══════════════════════════════════════════════════════════════════
// SOURCE BADGE
// ══════════════════════════════════════════════════════════════════

class _SourceBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SourceBadge({
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SRS PROGRESS RING — shows R{step}({hardCount})
// ══════════════════════════════════════════════════════════════════

class _ProgressRing extends StatelessWidget {
  final double progress;
  final int step;
  final int total;
  final int hardCount;
  final bool easyFlag;
  final Color color;
  final bool isDark;

  const _ProgressRing({
    required this.progress,
    required this.step,
    required this.total,
    required this.hardCount,
    required this.easyFlag,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Green ring color if easy flagged and no hard attempts
    final ringColor = easyFlag && hardCount == 0
        ? const Color(0xFF10B981)
        : color;

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track
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
          // Progress
          SizedBox(
            width: 40,
            height: 40,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(ringColor),
                );
              },
            ),
          ),
          // Step text with hard count
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'R$step',
                style: TextStyle(
                  fontSize: hardCount > 0 ? 9 : 11,
                  fontWeight: FontWeight.w700,
                  color: ringColor,
                ),
              ),
              if (hardCount > 0)
                Text(
                  '($hardCount)',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// RETENTION SCORE BADGE
// ══════════════════════════════════════════════════════════════════

class _RetentionBadge extends StatelessWidget {
  final int score;
  final bool isDark;

  const _RetentionBadge({required this.score, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData icon;

    if (score >= 80) {
      badgeColor = const Color(0xFF10B981);
      icon = Icons.stars_rounded;
    } else if (score >= 50) {
      badgeColor = const Color(0xFF3B82F6);
      icon = Icons.trending_up_rounded;
    } else if (score >= 20) {
      badgeColor = const Color(0xFFF59E0B);
      icon = Icons.auto_graph_rounded;
    } else if (score > 0) {
      badgeColor = const Color(0xFFF97316);
      icon = Icons.trending_flat_rounded;
    } else {
      badgeColor = DashboardColors.textPrimary(isDark).withValues(alpha: 0.3);
      icon = Icons.remove_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: badgeColor),
          const SizedBox(width: 3),
          Text(
            score > 0 ? '$score' : '0',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// GLASS CHIP
// ══════════════════════════════════════════════════════════════════

class _GlassChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final IconData? icon;

  const _GlassChip({
    required this.label,
    required this.color,
    required this.isDark,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// INFO PILL
// ══════════════════════════════════════════════════════════════════

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _InfoPill({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 10,
          color: DashboardColors.textPrimary(isDark).withValues(alpha: 0.3),
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 9,
            color:
                DashboardColors.textPrimary(isDark).withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// MARK REVISED BUTTON
// ══════════════════════════════════════════════════════════════════

class _MarkRevisedButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onTap;
  final bool isDark;

  const _MarkRevisedButton({
    required this.saving,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DashboardColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
              DashboardColors.primaryViolet
                  .withValues(alpha: isDark ? 0.12 : 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: DashboardColors.primary.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Center(
          child: saving
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation(DashboardColors.primary),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: DashboardColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Mark as Revised',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DashboardColors.primary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// EXPANDED DETAILS — confidence buttons + SRS timeline + logs
// ══════════════════════════════════════════════════════════════════

class _ExpandedDetails extends StatelessWidget {
  final RevisionDisplayItem item;
  final bool isDark;
  final Future<void> Function({String quality}) onRevise;
  final bool saving;
  final bool showLogs;
  final VoidCallback onToggleLogs;

  const _ExpandedDetails({
    required this.item,
    required this.isDark,
    required this.onRevise,
    required this.saving,
    required this.showLogs,
    required this.onToggleLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),

        // Divider
        Container(
          height: 0.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                DashboardColors.primary.withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // SRS Progress Timeline
        Text(
          'SRS Progress',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: DashboardColors.textPrimary(isDark)
                .withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        _SrsTimeline(
          currentStep: item.currentRevisionIndex,
          totalSteps: item.totalSteps,
          effectiveSrsStep: item.effectiveSrsStep,
          color: item.sourceColor,
          isDark: isDark,
        ),

        const SizedBox(height: 16),

        // Confidence Buttons
        Text(
          'How well do you remember?',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: DashboardColors.textPrimary(isDark)
                .withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ConfidenceButton(
                label: 'Hard',
                subtitle: 'Review sooner',
                color: const Color(0xFFEF4444),
                icon: Icons.replay_rounded,
                isDark: isDark,
                saving: saving,
                onTap: () => onRevise(quality: 'hard'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ConfidenceButton(
                label: 'Good',
                subtitle: 'Normal',
                color: DashboardColors.primary,
                icon: Icons.check_rounded,
                isDark: isDark,
                saving: saving,
                onTap: () => onRevise(quality: 'good'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ConfidenceButton(
                label: 'Easy',
                subtitle: 'Skip ahead',
                color: const Color(0xFF10B981),
                icon: Icons.fast_forward_rounded,
                isDark: isDark,
                saving: saving,
                onTap: () => onRevise(quality: 'easy'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // View Logs button
        GestureDetector(
          onTap: onToggleLogs,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: DashboardColors.textPrimary(isDark)
                  .withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DashboardColors.textPrimary(isDark)
                    .withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    showLogs
                        ? Icons.visibility_off_rounded
                        : Icons.history_rounded,
                    size: 13,
                    color: DashboardColors.textPrimary(isDark)
                        .withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    showLogs ? 'Hide Logs' : 'View Logs',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: DashboardColors.textPrimary(isDark)
                          .withValues(alpha: 0.45),
                    ),
                  ),
                  if (item.revisionLog.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: DashboardColors.primary
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.revisionLog.length}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: DashboardColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Log entries
        if (showLogs) ...[
          const SizedBox(height: 10),
          _RevisionLogList(
            logs: item.revisionLog,
            isDark: isDark,
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CONFIDENCE BUTTON
// ══════════════════════════════════════════════════════════════════

class _ConfidenceButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool isDark;
  final bool saving;
  final VoidCallback onTap;

  const _ConfidenceButton({
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 8,
                color: color.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SRS TIMELINE — with effective step indicator
// ══════════════════════════════════════════════════════════════════

class _SrsTimeline extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final int effectiveSrsStep;
  final Color color;
  final bool isDark;

  const _SrsTimeline({
    required this.currentStep,
    required this.totalSteps,
    required this.effectiveSrsStep,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final displaySteps = totalSteps.clamp(1, 12);
    final isLagging = effectiveSrsStep < currentStep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(displaySteps, (i) {
            final done = i < currentStep;
            final current = i == currentStep;
            final isEffective = i == effectiveSrsStep && isLagging;

            return Expanded(
              child: Container(
                margin:
                    EdgeInsets.only(right: i < displaySteps - 1 ? 2 : 0),
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: done
                      ? color.withValues(alpha: 0.8)
                      : current
                          ? color.withValues(alpha: 0.35)
                          : isEffective
                              ? const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.5)
                              : DashboardColors.textPrimary(isDark)
                                  .withValues(alpha: 0.08),
                  boxShadow: done
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: -1,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
        if (isLagging) ...[
          const SizedBox(height: 4),
          Text(
            'SRS lagging: interval at step ${effectiveSrsStep + 1} of ${currentStep + 1}',
            style: TextStyle(
              fontSize: 9,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// REVISION LOG LIST — timeline of all actions
// ══════════════════════════════════════════════════════════════════

class _RevisionLogList extends StatelessWidget {
  final List<RevisionLogEntry> logs;
  final bool isDark;

  const _RevisionLogList({required this.logs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'No revision logs yet',
            style: TextStyle(
              fontSize: 11,
              color: DashboardColors.textPrimary(isDark)
                  .withValues(alpha: 0.35),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: DashboardColors.textPrimary(isDark).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DashboardColors.textPrimary(isDark).withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(10),
        itemCount: logs.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            height: 0.5,
            color: DashboardColors.textPrimary(isDark)
                .withValues(alpha: 0.06),
          ),
        ),
        itemBuilder: (_, i) {
          final log = logs[logs.length - 1 - i]; // newest first
          return _LogEntry(log: log, isDark: isDark);
        },
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  final RevisionLogEntry log;
  final bool isDark;

  const _LogEntry({required this.log, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color responseColor;
    IconData responseIcon;
    switch (log.response) {
      case 'hard':
        responseColor = const Color(0xFFEF4444);
        responseIcon = Icons.replay_rounded;
        break;
      case 'easy':
        responseColor = const Color(0xFF10B981);
        responseIcon = Icons.fast_forward_rounded;
        break;
      default:
        responseColor = DashboardColors.primary;
        responseIcon = Icons.check_rounded;
    }

    final scheduledDt = DateTime.tryParse(log.scheduledAt);
    final actualDt = DateTime.tryParse(log.actualAt);
    final fmt = DateFormat('MMM d, h:mm a');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Response icon
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: responseColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(responseIcon, size: 10, color: responseColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Revision label
              Row(
                children: [
                  Text(
                    'R${log.revisionNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.textPrimary(isDark),
                    ),
                  ),
                  if (log.hardAttempt > 0)
                    Text(
                      ' (Hard #${log.hardAttempt})',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: responseColor,
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: responseColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.response.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: responseColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // Scheduled vs Actual
              if (scheduledDt != null)
                _LogDetailRow(
                  label: 'Scheduled',
                  value: fmt.format(scheduledDt),
                  isDark: isDark,
                ),
              if (actualDt != null)
                _LogDetailRow(
                  label: 'Actual',
                  value: fmt.format(actualDt),
                  isDark: isDark,
                ),
              if (log.nextScheduledHours > 0)
                _LogDetailRow(
                  label: 'Next in',
                  value: _formatHours(log.nextScheduledHours),
                  isDark: isDark,
                ),
              if (log.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    log.note,
                    style: TextStyle(
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                      color: DashboardColors.textPrimary(isDark)
                          .withValues(alpha: 0.35),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatHours(int hours) {
    if (hours < 24) return '${hours}h';
    final days = hours ~/ 24;
    final rem = hours % 24;
    if (rem == 0) return '${days}d';
    return '${days}d ${rem}h';
  }
}

class _LogDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _LogDetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: DashboardColors.textPrimary(isDark)
                  .withValues(alpha: 0.35),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              color: DashboardColors.textPrimary(isDark)
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════════
// SWIPE BACKGROUND
// ══════════════════════════════════════════════════════════════════

class _SwipeBackground extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerRight)
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          if (alignment == Alignment.centerRight) const SizedBox(width: 6),
          Icon(icon, size: 20, color: color),
          if (alignment == Alignment.centerLeft) const SizedBox(width: 6),
          if (alignment == Alignment.centerLeft)
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
    );
  }
}
