// =============================================================
// FlowControlBar - Start / Resume / Pause / Stop controls
// =============================================================

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/daily_flow.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
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

    if (flow == null || flow!.activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: startAndOpenFlow,
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Start Flow'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                if (onAddTask != null) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: Material(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: openStudySessionPicker,
                icon: const Icon(Icons.school_rounded, size: 20),
                label: const Text('Start Study Session'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

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

    if (allDone) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 88,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.celebration_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'All Done for Today!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$completed tasks completed • $elapsedLabel',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onAddTask != null)
                      OutlinedButton.icon(
                        onPressed: onAddTask,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Task'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: openStudySessionPicker,
                icon: const Icon(Icons.school_rounded, size: 20),
                label: const Text('Start Study Session'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap:
                (dailyFlow.isActive || dailyFlow.isPaused) ? openSession : null,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.08),
                    cs.primary.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 3.5,
                              backgroundColor:
                                  cs.primary.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation(cs.primary),
                            ),
                            Text(
                              '$completed/$total',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
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
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              '$elapsedLabel elapsed • $completed/$total done',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (dailyFlow.isActive || dailyFlow.isPaused)
                        Icon(
                          Icons.open_in_full_rounded,
                          size: 18,
                          color: cs.primary.withValues(alpha: 0.5),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (showStartFlow)
                        Expanded(
                          child: _ActionBtn(
                            onTap: () async {
                              await app.startFlow(dateKey);
                              if (context.mounted) {
                                openSession();
                              }
                            },
                            icon: Icons.play_arrow_rounded,
                            label: 'Start Flow',
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      if (dailyFlow.isPaused)
                        Expanded(
                          child: _ActionBtn(
                            onTap: () async {
                              await app.resumeFlow(dateKey);
                              if (context.mounted) {
                                openSession();
                              }
                            },
                            icon: Icons.play_arrow_rounded,
                            label: 'Resume',
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      if (dailyFlow.isActive)
                        Expanded(
                          child: _ActionBtn(
                            onTap: openSession,
                            icon: Icons.open_in_full_rounded,
                            label: 'Open Session',
                            color: cs.primary,
                          ),
                        ),
                      if (onAddTask != null) ...[
                        if (showStartFlow ||
                            dailyFlow.isPaused ||
                            dailyFlow.isActive)
                          const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: _ActionBtn(
                            onTap: onAddTask!,
                            icon: Icons.add_rounded,
                            label: '',
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: openStudySessionPicker,
              icon: const Icon(Icons.school_rounded, size: 20),
              label: const Text('Start Study Session'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color color;

  const _ActionBtn({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 4),
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
    );
  }
}
