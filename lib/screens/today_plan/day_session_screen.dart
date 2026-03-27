// =============================================================
// DaySessionScreen — Active day session view
// Shows: current task + timer, next task preview, progress bar
// Done Early / Skip / Pull Up buttons, cascades via scheduler
// =============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/day_session.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';

class DaySessionScreen extends StatefulWidget {
  final String dateKey;
  final DaySession session;

  const DaySessionScreen({
    super.key,
    required this.dateKey,
    required this.session,
  });

  @override
  State<DaySessionScreen> createState() => _DaySessionScreenState();
}

class _DaySessionScreenState extends State<DaySessionScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  String _formatElapsed(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Block? _currentBlock(List<Block> blocks) {
    final currentId = widget.session.currentBlockId;
    if (currentId == null) return null;
    try {
      return blocks.firstWhere((b) => b.id == currentId);
    } catch (_) {
      return null;
    }
  }

  Block? _nextBlock(List<Block> blocks) {
    final activeBlocks = blocks
        .where((b) => b.status != BlockStatus.done && b.status != BlockStatus.skipped)
        .toList()
      ..sort((a, b) {
        final aMin = _toMinutes(a.plannedStartTime);
        final bMin = _toMinutes(b.plannedStartTime);
        return aMin.compareTo(bMin);
      });
    final currentId = widget.session.currentBlockId;
    if (currentId == null && activeBlocks.isNotEmpty) return activeBlocks.first;
    final currentIdx = activeBlocks.indexWhere((b) => b.id == currentId);
    if (currentIdx < 0 || currentIdx + 1 >= activeBlocks.length) return null;
    return activeBlocks[currentIdx + 1];
  }

  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  double _progress(List<Block> blocks) {
    if (blocks.isEmpty) return 0;
    final done = blocks.where((b) => b.status == BlockStatus.done).length;
    return done / blocks.length;
  }

  void _completeCurrent(AppProvider app, Block block) {
    app.completeDayPlanBlock(
      widget.dateKey,
      block.id,
      startedAt: widget.session.startedAt,
      completedAt: DateTime.now(),
      autoAdvanceFlow: true,
    );
    app.rescheduleFromNow(widget.dateKey);
    setState(() => _elapsedSeconds = 0);
  }

  void _skipCurrent(AppProvider app, Block block) {
    final plan = app.getDayPlan(widget.dateKey);
    if (plan == null) return;
    final blocks = List<Block>.from(plan.blocks ?? []);
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx < 0) return;
    blocks[idx] = blocks[idx].copyWith(status: BlockStatus.skipped);
    app.upsertDayPlan(plan.copyWith(blocks: blocks));
    app.rescheduleFromNow(widget.dateKey);
    setState(() => _elapsedSeconds = 0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final app = context.watch<AppProvider>();
    final plan = app.getDayPlan(widget.dateKey);
    final blocks = plan?.blocks ?? const <Block>[];
    final current = _currentBlock(blocks);
    final next = _nextBlock(blocks);
    final progress = _progress(blocks);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Day Session',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              app.endDaySession(widget.dateKey);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.stop_rounded, size: 18, color: Colors.red),
            label: const Text('End',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: cs.onSurface.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).round()}% Complete',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  '${blocks.where((b) => b.status == BlockStatus.done).length}/${blocks.length} blocks',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Current task
            if (current != null) ...[
              Text(
                'NOW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withValues(alpha: 0.1),
                      cs.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      current.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${current.plannedStartTime} – ${current.plannedEndTime}',
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Timer
                    Text(
                      _formatElapsed(_elapsedSeconds),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _skipCurrent(app, current),
                            icon: const Icon(Icons.skip_next_rounded, size: 18),
                            label: const Text('Skip'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () => _completeCurrent(app, current),
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: const Text('Done Early',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 40),
              Icon(Icons.check_circle_outline_rounded,
                  size: 56, color: cs.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text(
                'All blocks completed!',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Great work today',
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Next task preview
            if (next != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'UP NEXT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface.withValues(alpha: 0.4),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.navigate_next_rounded,
                          color: Color(0xFF6366F1), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            next.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${next.plannedStartTime} – ${next.plannedEndTime}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
