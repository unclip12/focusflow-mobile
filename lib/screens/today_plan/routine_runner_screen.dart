// =============================================================
// RoutineRunnerScreen — Full-screen sequential task execution
// Timer + step display + Done/Skip/Cancel controls
// Records all timings to RoutineLog
// =============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/routine.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';

class RoutineRunnerScreen extends StatefulWidget {
  final Routine routine;
  final String dateKey;
  final VoidCallback? onComplete;

  const RoutineRunnerScreen({
    super.key,
    required this.routine,
    required this.dateKey,
    this.onComplete,
  });

  @override
  State<RoutineRunnerScreen> createState() => _RoutineRunnerScreenState();
}

class _RoutineRunnerScreenState extends State<RoutineRunnerScreen> {
  int _currentStep = 0;
  bool _finished = false;
  Timer? _timer;
  int _totalElapsed = 0; // seconds
  int _stepElapsed = 0;
  DateTime? _stepStartTime;
  final _uuid = const Uuid();
  final List<RoutineLogEntry> _entries = [];
  late DateTime _startTime;

  static const _motivations = [
    'You got this! 💪',
    'Keep going, champ! 🏆',
    'One step at a time 🚀',
    'Almost there! 🎯',
    'Stay focused! 🔥',
    'Great progress! ⭐',
    'You\'re crushing it! 🌟',
  ];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _stepStartTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_finished && mounted) {
        setState(() {
          _totalElapsed++;
          _stepElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _markDone() {
    HapticsService.medium();
    _entries.add(RoutineLogEntry(
      stepId: widget.routine.steps[_currentStep].id,
      stepTitle: widget.routine.steps[_currentStep].title,
      startTime: _stepStartTime!.toIso8601String(),
      endTime: DateTime.now().toIso8601String(),
      durationSeconds: _stepElapsed,
      skipped: false,
    ));
    _nextStep();
  }

  void _skipStep() {
    HapticsService.light();
    _entries.add(RoutineLogEntry(
      stepId: widget.routine.steps[_currentStep].id,
      stepTitle: widget.routine.steps[_currentStep].title,
      startTime: _stepStartTime!.toIso8601String(),
      endTime: DateTime.now().toIso8601String(),
      durationSeconds: _stepElapsed,
      skipped: true,
    ));
    _nextStep();
  }

  void _nextStep() {
    if (_currentStep < widget.routine.steps.length - 1) {
      setState(() {
        _currentStep++;
        _stepElapsed = 0;
        _stepStartTime = DateTime.now();
      });
    } else {
      _completeRoutine();
    }
  }

  void _completeRoutine() {
    HapticsService.heavy();
    setState(() => _finished = true);
    _timer?.cancel();

    final log = RoutineLog(
      id: _uuid.v4(),
      routineId: widget.routine.id,
      routineName: widget.routine.name,
      date: widget.dateKey,
      startTime: _startTime.toIso8601String(),
      endTime: DateTime.now().toIso8601String(),
      totalDurationSeconds: _totalElapsed,
      entries: _entries,
      completed: true,
    );
    context.read<AppProvider>().upsertRoutineLog(log);
  }

  void _cancelRoutine() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Routine?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _fmtTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final steps = widget.routine.steps;

    if (_finished) {
      return _SummaryScreen(
        routine: widget.routine,
        entries: _entries,
        totalSeconds: _totalElapsed,
        onDone: () {
          Navigator.pop(context);
          widget.onComplete?.call();
        },
      );
    }

    final step = steps[_currentStep];
    final progress = (_currentStep + 1) / steps.length;
    final motivation = _motivations[_currentStep % _motivations.length];

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(widget.routine.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.routine.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _cancelRoutine,
                    icon: Icon(Icons.close_rounded, color: cs.error),
                  ),
                ],
              ),
            ),

            // ── Progress bar ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of ${steps.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: cs.primary.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(cs.primary),
                    ),
                  ),
                ],
              ),
            ),

            // ── Main task display ─────────────────────────────
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Color(widget.routine.color).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${_currentStep + 1}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(widget.routine.color),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        step.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      if (step.estimatedMinutes != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '~${step.estimatedMinutes} min estimated',
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        motivation,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Timer + Controls ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Timers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            'This step',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmtTime(_stepElapsed),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        width: 1,
                        height: 40,
                        color: cs.onSurface.withValues(alpha: 0.1),
                      ),
                      Column(
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmtTime(_totalElapsed),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _skipStep,
                          icon: const Icon(Icons.skip_next_rounded, size: 20),
                          label: const Text('Skip'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _markDone,
                          icon: const Icon(Icons.check_rounded, size: 22),
                          label: Text(
                            _currentStep == steps.length - 1 ? 'Finish' : 'Done',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Screen ──────────────────────────────────────────────
class _SummaryScreen extends StatelessWidget {
  final Routine routine;
  final List<RoutineLogEntry> entries;
  final int totalSeconds;
  final VoidCallback onDone;

  const _SummaryScreen({
    required this.routine,
    required this.entries,
    required this.totalSeconds,
    required this.onDone,
  });

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.check_circle_rounded, size: 64, color: const Color(0xFF10B981)),
            const SizedBox(height: 16),
            Text(
              '${routine.name} Complete! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total time: ${_fmt(totalSeconds)}',
              style: TextStyle(
                fontSize: 16,
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final e = entries[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: e.skipped
                          ? cs.errorContainer.withValues(alpha: 0.3)
                          : cs.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: e.skipped
                                ? cs.error.withValues(alpha: 0.15)
                                : const Color(0xFF10B981).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              e.skipped ? Icons.skip_next_rounded : Icons.check_rounded,
                              size: 16,
                              color: e.skipped ? cs.error : const Color(0xFF10B981),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.stepTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                              decoration: e.skipped ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        Text(
                          _fmt(e.durationSeconds ?? 0),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: e.skipped ? cs.error : cs.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
