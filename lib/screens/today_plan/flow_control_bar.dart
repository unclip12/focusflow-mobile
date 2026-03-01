// =============================================================
// FlowControlBar — Start / Resume / Pause / Stop controls
// =============================================================


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/daily_flow.dart';
import 'flow_session_screen.dart';

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

    if (flow == null || flow!.activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  await app.initializeDailyFlow(dateKey);
                  await app.startFlow(dateKey);
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FlowSessionScreen(dateKey: dateKey),
                      ),
                    );
                  }
                },
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
                    child: Icon(Icons.add_rounded, color: cs.primary, size: 22),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final f = flow!;
    final completed = f.completedCount;
    final total = f.totalCount;
    final progress = total > 0 ? completed / total : 0.0;
    final elapsed = Duration(seconds: f.totalElapsedSeconds);
    final elapsedStr = '${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}m';

    // Navigate to full-screen session
    void openSession() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FlowSessionScreen(dateKey: dateKey),
        ),
      );
    }

    return GestureDetector(
      onTap: (f.isActive || f.isPaused) ? openSession : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            // Progress row
            Row(
              children: [
                // Circular progress
                SizedBox(
                  width: 42,
                  height: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3.5,
                        backgroundColor: cs.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(
                          f.isCompleted
                              ? const Color(0xFF10B981)
                              : cs.primary,
                        ),
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
                        f.isCompleted
                            ? 'Flow Complete! 🎉'
                            : f.isActive
                                ? 'Flow Active'
                                : f.isPaused
                                    ? 'Flow Paused'
                                    : f.isStopped
                                        ? 'Flow Stopped'
                                        : 'Ready to Start',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        '$elapsedStr elapsed',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Open arrow for active/paused flows
                if (f.isActive || f.isPaused)
                  Icon(Icons.open_in_full_rounded,
                      size: 18, color: cs.primary.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 10),
            // Action buttons
            Row(
              children: [
                if (f.isNotStarted || f.isStopped)
                  Expanded(
                    child: _ActionBtn(
                      onTap: () async {
                        await app.startFlow(dateKey);
                        if (context.mounted) openSession();
                      },
                      icon: Icons.play_arrow_rounded,
                      label: 'Start',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                if (f.isPaused)
                  Expanded(
                    child: _ActionBtn(
                      onTap: () async {
                        await app.resumeFlow(dateKey);
                        if (context.mounted) openSession();
                      },
                      icon: Icons.play_arrow_rounded,
                      label: 'Resume',
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                if (f.isActive)
                  Expanded(
                    child: _ActionBtn(
                      onTap: openSession,
                      icon: Icons.open_in_full_rounded,
                      label: 'Open Session',
                      color: cs.primary,
                    ),
                  ),
                // Compact + button
                if (onAddTask != null) ...[
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
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
