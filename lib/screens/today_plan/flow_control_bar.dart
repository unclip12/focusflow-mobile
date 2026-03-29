// =============================================================
// FlowControlBar - Start / Resume / Pause / Stop controls
// Premium Redesign with glassmorphic styling
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/daily_flow.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:provider/provider.dart';

import 'flow_session_screen.dart';
import 'study_session_picker.dart';

class FlowControlBar extends StatelessWidget {
  final String dateKey;
  final DailyFlow? flow;
  final VoidCallback? onAddTask;

  const FlowControlBar({
    super.key,
    required this.dateKey,
    required this.flow,
    this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final app = context.read<AppProvider>();

    void openStudySessionPicker() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => StudySessionPicker(dateKey: dateKey),
      );
    }

    Future<void> startAndOpenFlow() async {
      await app.startFlow(dateKey);
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FlowSessionScreen(dateKey: dateKey),
        ),
      );
    }

    void openSession() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FlowSessionScreen(dateKey: dateKey),
        ),
      );
    }

    // ── EMPTY STATE: No flow yet ──────────────────────────────────
    if (flow == null || flow!.activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DashboardColors.primary,
                      DashboardColors.primaryDeep,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: DashboardColors.primary
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: startAndOpenFlow,
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Start Flow',
                            style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactStudyBtn(
                  onTap: openStudySessionPicker, isDark: isDark),
            ),
            if (onAddTask != null) ...[
              const SizedBox(width: 8),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAddTask,
                    borderRadius: BorderRadius.circular(14),
                    child: Icon(Icons.add_rounded,
                        color: cs.primary, size: 22),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // ── ACTIVE STATE: Flow has activities ───────────────────────────
    final dailyFlow = flow!;
    final completed = dailyFlow.completedCount;
    final total = dailyFlow.totalCount;
    final progress = total > 0 ? completed / total : 0.0;
    final elapsed = Duration(seconds: dailyFlow.totalElapsedSeconds);
    final elapsedLabel =
        '${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}m';
    final hasPendingNotStarted =
        dailyFlow.activities.any((activity) => activity.isNotStarted);
    final allDone = completed == total && total > 0;
    final showStartFlow = dailyFlow.isNotStarted ||
        dailyFlow.isStopped ||
        (hasPendingNotStarted && !dailyFlow.isPaused && !dailyFlow.isActive);

    // ── ALL DONE STATE ──────────────────────────────────────────
    if (allDone) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFF10B981).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.celebration_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'All Done for Today! 🎉',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$completed tasks • $elapsedLabel total',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onAddTask != null)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onAddTask,
                              borderRadius: BorderRadius.circular(10),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded,
                                        size: 16, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'Add',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (onAddTask != null)
                  Expanded(
                    child: _GlassActionBtn(
                      onTap: onAddTask!,
                      icon: Icons.add_rounded,
                      label: 'Add More',
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ),
                if (onAddTask != null) const SizedBox(width: 8),
                Expanded(
                  child: _GlassActionBtn(
                    onTap: openStudySessionPicker,
                    icon: Icons.school_rounded,
                    label: 'Study',
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ── IN-PROGRESS STATE ───────────────────────────────────────
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap:
                (dailyFlow.isActive || dailyFlow.isPaused) ? openSession : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.06),
                              Colors.white.withValues(alpha: 0.02),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.70),
                              Colors.white.withValues(alpha: 0.45),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? DashboardColors.glassBorderDark
                          : DashboardColors.glassBorderLight,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Circular progress
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 3.5,
                                    backgroundColor:
                                        cs.primary.withValues(alpha: 0.1),
                                    valueColor:
                                        AlwaysStoppedAnimation(cs.primary),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Text(
                                  '$completed/$total',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: cs.primary,
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
                                  dailyFlow.isActive
                                      ? 'Flow Active'
                                      : dailyFlow.isPaused
                                          ? 'Flow Paused'
                                          : 'Start Flow',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.timer_outlined,
                                        size: 12,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.4)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$elapsedLabel elapsed',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 3,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$completed/$total done',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (dailyFlow.isActive || dailyFlow.isPaused)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.open_in_full_rounded,
                                size: 16,
                                color: cs.primary.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                      // Linear progress bar
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: cs.primary.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation(
                            DashboardColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Action buttons row
                      Row(
                        children: [
                          if (showStartFlow)
                            Expanded(
                              child: _GlassActionBtn(
                                onTap: () async {
                                  await app.startFlow(dateKey);
                                  if (context.mounted) {
                                    openSession();
                                  }
                                },
                                icon: Icons.play_arrow_rounded,
                                label: 'Start Flow',
                                color: const Color(0xFF10B981),
                                isDark: isDark,
                              ),
                            ),
                          if (dailyFlow.isPaused)
                            Expanded(
                              child: _GlassActionBtn(
                                onTap: () async {
                                  await app.resumeFlow(dateKey);
                                  if (context.mounted) {
                                    openSession();
                                  }
                                },
                                icon: Icons.play_arrow_rounded,
                                label: 'Resume',
                                color: const Color(0xFF3B82F6),
                                isDark: isDark,
                              ),
                            ),
                          if (dailyFlow.isActive)
                            Expanded(
                              child: _GlassActionBtn(
                                onTap: openSession,
                                icon: Icons.open_in_full_rounded,
                                label: 'Open Session',
                                color: cs.primary,
                                isDark: isDark,
                              ),
                            ),
                          if (onAddTask != null) ...[
                            if (showStartFlow ||
                                dailyFlow.isPaused ||
                                dailyFlow.isActive)
                              const SizedBox(width: 8),
                            SizedBox(
                              width: 44,
                              child: _GlassActionBtn(
                                onTap: onAddTask!,
                                icon: Icons.add_rounded,
                                label: '',
                                color: cs.primary,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (onAddTask != null) ...[
                Expanded(
                  child: _GlassActionBtn(
                    onTap: onAddTask!,
                    icon: Icons.add_rounded,
                    label: '',
                    color: cs.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _CompactStudyBtn(
                    onTap: openStudySessionPicker, isDark: isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Compact Study Session Button ────────────────────────────────
class _CompactStudyBtn extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _CompactStudyBtn({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_rounded, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text('Study',
                  style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glass Action Button ─────────────────────────────────────────
class _GlassActionBtn extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _GlassActionBtn({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
