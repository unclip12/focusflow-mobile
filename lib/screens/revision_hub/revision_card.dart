// =============================================================
// UnifiedRevisionCard — Premium liquid glass revision card
// Features: progress ring, urgency stripe, confidence buttons,
// swipe gestures, expandable details, shimmer effects
// =============================================================

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
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
  late final AnimationController _shimmerController;
  late final AnimationController _expandController;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
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
    _shimmerController.dispose();
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
        final kbEntry = app.knowledgeBase.firstWhere(
          (e) => 'kb-${e.pageNumber}' == widget.item.id,
        );
        final mode = app.revisionSettings?.mode ?? 'strict';

        // Adjust revision index based on confidence
        int newIndex;
        switch (quality) {
          case 'easy':
            newIndex = (kbEntry.currentRevisionIndex + 2).clamp(0, 11);
            break;
          case 'hard':
            newIndex = (kbEntry.currentRevisionIndex).clamp(0, 11);
            break;
          default: // good
            newIndex = (kbEntry.currentRevisionIndex + 1).clamp(0, 11);
        }

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

  void _toggleExpand() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
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
        ? const Color(0xFF1E1E3A).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.82);
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
            return false; // Don't actually dismiss, the list updates via provider
          }
          // Swipe left = skip for now — no action needed
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
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Container(
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
                          if (isOverdue)
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(
                                  alpha:
                                      0.06 + (math.sin(_shimmerController.value * math.pi * 2) * 0.04)),
                              blurRadius: 16,
                              spreadRadius: -2,
                            ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Stack(
                    children: [
                      // ── Shimmer overlay ────────────────────────
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _ShimmerOverlay(
                            controller: _shimmerController,
                            isDark: isDark,
                          ),
                        ),
                      ),

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
                                  Colors.white.withValues(alpha: isDark ? 0.08 : 0.25),
                                  Colors.transparent,
                                  item.sourceColor.withValues(alpha: isDark ? 0.04 : 0.02),
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
                                // Source icon with glass container
                                _SourceBadge(
                                  icon: item.sourceIcon,
                                  color: item.sourceColor,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 10),

                                // Title + subject
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

                                // SRS Progress Ring
                                _ProgressRing(
                                  progress: item.progressPercent,
                                  step: item.currentRevisionIndex,
                                  total: item.totalSteps,
                                  color: item.sourceColor,
                                  isDark: isDark,
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Chips row: source label + due status
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
                                if (due.timeDetail.isNotEmpty)
                                  _InfoPill(
                                    icon: Icons.access_time_rounded,
                                    text: due.timeDetail,
                                    isDark: isDark,
                                  ),
                                if (item.lastStudiedAt != null)
                                  _InfoPill(
                                    icon: Icons.history_rounded,
                                    text: _formatLastStudied(item.lastStudiedAt!),
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

  String _formatLastStudied(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Studied today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

// ══════════════════════════════════════════════════════════════════
// SOURCE BADGE — glass icon container
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
// SRS PROGRESS RING
// ══════════════════════════════════════════════════════════════════

class _ProgressRing extends StatelessWidget {
  final double progress;
  final int step;
  final int total;
  final Color color;
  final bool isDark;

  const _ProgressRing({
    required this.progress,
    required this.step,
    required this.total,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track
          SizedBox(
            width: 36,
            height: 36,
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
            width: 36,
            height: 36,
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
                  valueColor: AlwaysStoppedAnimation(color),
                );
              },
            ),
          ),
          // Step text
          Text(
            '$step',
            style: TextStyle(
              fontSize: 12,
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
// GLASS CHIP — frosted source/status chip
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
// INFO PILL — subtle time/status info
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
            color: DashboardColors.textPrimary(isDark).withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// MARK REVISED BUTTON — gradient glass button
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
              DashboardColors.primaryViolet.withValues(alpha: isDark ? 0.12 : 0.08),
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
                    valueColor: AlwaysStoppedAnimation(DashboardColors.primary),
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
// EXPANDED DETAILS — confidence buttons + revision timeline
// ══════════════════════════════════════════════════════════════════

class _ExpandedDetails extends StatelessWidget {
  final RevisionDisplayItem item;
  final bool isDark;
  final Future<void> Function({String quality}) onRevise;
  final bool saving;

  const _ExpandedDetails({
    required this.item,
    required this.isDark,
    required this.onRevise,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),

        // ── Divider ──────────────────────────────────────────
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

        // ── Revision Progress Timeline ──────────────────────
        Text(
          'SRS Progress',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: DashboardColors.textPrimary(isDark).withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        _SrsTimeline(
          currentStep: item.currentRevisionIndex,
          totalSteps: item.totalSteps,
          color: item.sourceColor,
          isDark: isDark,
        ),

        const SizedBox(height: 16),

        // ── Confidence Buttons ──────────────────────────────
        Text(
          'How well do you remember?',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: DashboardColors.textPrimary(isDark).withValues(alpha: 0.6),
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
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CONFIDENCE BUTTON — glass-styled action button
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
// SRS TIMELINE — visual step indicator
// ══════════════════════════════════════════════════════════════════

class _SrsTimeline extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color color;
  final bool isDark;

  const _SrsTimeline({
    required this.currentStep,
    required this.totalSteps,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final displaySteps = totalSteps.clamp(1, 12);

    return Row(
      children: List.generate(displaySteps, (i) {
        final done = i < currentStep;
        final current = i == currentStep;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < displaySteps - 1 ? 2 : 0),
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: done
                  ? color.withValues(alpha: 0.8)
                  : current
                      ? color.withValues(alpha: 0.35)
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
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SHIMMER OVERLAY
// ══════════════════════════════════════════════════════════════════

class _ShimmerOverlay extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;

  const _ShimmerOverlay({
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final shimmerWidth = width * 1.5;
        final travel = width + shimmerWidth;

        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final x = shimmerWidth / 2 - (travel * controller.value);
            return Transform.translate(
              offset: Offset(x, 0),
              child: Transform.rotate(
                angle: -0.25,
                child: child,
              ),
            );
          },
          child: Container(
            width: width * 0.4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  DashboardColors.shimmerTransparent,
                  DashboardColors.shimmerSoft,
                  DashboardColors.shimmerBright,
                  DashboardColors.shimmerSoft,
                  DashboardColors.shimmerTransparent,
                ],
              ),
            ),
          ),
        );
      },
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
      padding: EdgeInsets.symmetric(horizontal: 24),
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
