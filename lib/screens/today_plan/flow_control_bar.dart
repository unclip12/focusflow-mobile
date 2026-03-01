// =============================================================
// FlowControlBar — Start / Resume / Pause / Stop controls
// =============================================================


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/daily_flow.dart';
import 'package:focusflow_mobile/services/notification_service.dart';

class FlowControlBar extends StatelessWidget {
  final String dateKey;
  final DailyFlow? flow;

  const FlowControlBar({
    super.key,
    required this.dateKey,
    required this.flow,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.read<AppProvider>();

    if (flow == null || flow!.activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              await app.initializeDailyFlow(dateKey);
              await app.startFlow(dateKey);
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
      );
    }

    final f = flow!;
    final completed = f.completedCount;
    final total = f.totalCount;
    final progress = total > 0 ? completed / total : 0.0;
    final elapsed = Duration(seconds: f.totalElapsedSeconds);
    final elapsedStr = '${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}m';

    return Container(
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
            ],
          ),
          const SizedBox(height: 10),
          // Action buttons
          Row(
            children: [
              if (f.isNotStarted || f.isStopped)
                Expanded(
                  child: _ActionBtn(
                    onTap: () => app.startFlow(dateKey),
                    icon: Icons.play_arrow_rounded,
                    label: 'Start',
                    color: const Color(0xFF10B981),
                  ),
                ),
              if (f.isPaused)
                Expanded(
                  child: _ActionBtn(
                    onTap: () => app.resumeFlow(dateKey),
                    icon: Icons.play_arrow_rounded,
                    label: 'Resume',
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              if (f.isActive) ...[
                Expanded(
                  child: _ActionBtn(
                    onTap: () => _showPauseDialog(context, app),
                    icon: Icons.pause_rounded,
                    label: 'Pause',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    onTap: () => _showStopDialog(context, app),
                    icon: Icons.stop_rounded,
                    label: 'Stop',
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
              if (f.isActive || f.isPaused) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    onTap: () {
                      final active = f.activities.where((a) => a.isActive).toList();
                      if (active.isNotEmpty) {
                        app.completeFlowActivity(dateKey, active.first.id);
                      }
                    },
                    icon: Icons.check_rounded,
                    label: 'Done',
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showPauseDialog(BuildContext context, AppProvider app) {
    int pauseMinutes = 10;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Pause Flow'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How long do you want to pause?'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [5, 10, 15, 30, 60].map((m) {
                  final selected = pauseMinutes == m;
                  return ChoiceChip(
                    label: Text('${m}m'),
                    selected: selected,
                    onSelected: (_) => setState(() => pauseMinutes = m),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                app.pauseFlow(dateKey,
                    pauseDuration: Duration(minutes: pauseMinutes));
                // Schedule notification
                NotificationService.instance.scheduleAt(
                  id: 2000,
                  title: 'Flow Paused ⏸️',
                  body: 'Your pause is over — ready to continue?',
                  when: DateTime.now().add(Duration(minutes: pauseMinutes)),
                );
                Navigator.pop(ctx);
              },
              child: Text('Pause for ${pauseMinutes}m'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStopDialog(BuildContext context, AppProvider app) {
    TimeOfDay? remindTime;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Stop Flow'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('When should I remind you to resume?'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) setState(() => remindTime = picked);
                },
                icon: const Icon(Icons.schedule_rounded, size: 18),
                label: Text(remindTime != null
                    ? remindTime!.format(ctx)
                    : 'Pick a time'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                app.stopFlow(dateKey);
                Navigator.pop(ctx);
              },
              child: const Text('Stop without reminder'),
            ),
            FilledButton(
              onPressed: () {
                DateTime? remindAt;
                if (remindTime != null) {
                  final now = DateTime.now();
                  remindAt = DateTime(now.year, now.month, now.day,
                      remindTime!.hour, remindTime!.minute);
                  if (remindAt.isBefore(now)) {
                    remindAt = remindAt.add(const Duration(days: 1));
                  }
                  NotificationService.instance.scheduleAt(
                    id: 2001,
                    title: 'Resume Your Flow ▶️',
                    body: 'Time to get back to your daily plan!',
                    when: remindAt,
                  );
                }
                app.stopFlow(dateKey, remindAt: remindAt);
                Navigator.pop(ctx);
              },
              child: const Text('Stop & Remind'),
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
