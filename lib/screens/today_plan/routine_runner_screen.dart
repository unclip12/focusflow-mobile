import 'dart:async';

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/routine.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'package:provider/provider.dart';

class RoutineRunnerScreen extends StatefulWidget {
  final Routine routine;
  final String dateKey;
  final String? sourceBlockId;
  final VoidCallback? onComplete;

  const RoutineRunnerScreen({
    super.key,
    required this.routine,
    required this.dateKey,
    this.sourceBlockId,
    this.onComplete,
  });

  @override
  State<RoutineRunnerScreen> createState() => _RoutineRunnerScreenState();
}

class _RoutineRunnerScreenState extends State<RoutineRunnerScreen> {
  static const _motivations = <String>[
    'You got this.',
    'Keep going.',
    'One step at a time.',
    'Almost there.',
    'Stay focused.',
    'Great progress.',
    'Keep the momentum.',
  ];

  int _currentStep = 0;
  int _totalElapsed = 0;
  int _stepElapsed = 0;
  bool _isSaving = false;
  Timer? _timer;
  DateTime? _stepStartTime;
  late DateTime _startTime;
  RoutineLog? _completedLog;
  final List<RoutineLogEntry> _entries = <RoutineLogEntry>[];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _stepStartTime = _startTime;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _completedLog != null || _isSaving) return;
      setState(() {
        _totalElapsed++;
        _stepElapsed++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _markDone() {
    if (_isSaving) return;
    HapticsService.medium();
    _recordCurrentStep(skipped: false);
    _advance();
  }

  void _skipStep() {
    if (_isSaving) return;
    HapticsService.light();
    _recordCurrentStep(skipped: true);
    _advance();
  }

  void _recordCurrentStep({required bool skipped}) {
    final step = widget.routine.steps[_currentStep];
    _entries.add(
      RoutineLogEntry(
        stepId: step.id,
        stepTitle: step.title,
        startTime: (_stepStartTime ?? DateTime.now()).toIso8601String(),
        endTime: DateTime.now().toIso8601String(),
        durationSeconds: _stepElapsed,
        skipped: skipped,
      ),
    );
  }

  void _advance() {
    if (_currentStep < widget.routine.steps.length - 1) {
      setState(() {
        _currentStep++;
        _stepElapsed = 0;
        _stepStartTime = DateTime.now();
      });
      return;
    }

    unawaited(_completeRoutine());
  }

  Future<void> _completeRoutine() async {
    if (_isSaving) return;
    HapticsService.heavy();
    _timer?.cancel();
    setState(() => _isSaving = true);

    final log = await context.read<AppProvider>().completeRoutineRun(
      routine: widget.routine,
      dateKey: widget.dateKey,
      startedAt: _startTime,
      completedAt: DateTime.now(),
      totalDurationSeconds: _totalElapsed,
      entries: List<RoutineLogEntry>.from(_entries),
      sourceBlockId: widget.sourceBlockId,
    );

    if (!mounted) return;
    setState(() {
      _completedLog = log;
      _isSaving = false;
    });
  }

  void _cancelRoutine() {
    showDialog<void>(
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final completedLog = _completedLog;
    if (completedLog != null) {
      return RoutineLogSummaryScreen(
        routine: widget.routine,
        log: completedLog,
        sourceBlockId: widget.sourceBlockId,
        onDone: () {
          Navigator.pop(context);
          widget.onComplete?.call();
        },
      );
    }

    final cs = Theme.of(context).colorScheme;
    final steps = widget.routine.steps;
    final step = steps[_currentStep];
    final progress = (_currentStep + 1) / steps.length;
    final motivation = _motivations[_currentStep % _motivations.length];

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(widget.routine.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
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
                    onPressed: _isSaving ? null : _cancelRoutine,
                    icon: Icon(Icons.close_rounded, color: cs.error),
                  ),
                ],
              ),
            ),
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
                      backgroundColor: cs.primary.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Color(widget.routine.color).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${_currentStep + 1}',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Color(widget.routine.color),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        step.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      if (step.estimatedMinutes != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          '~${step.estimatedMinutes} min estimated',
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        motivation,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.primary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TimerCard(
                          label: 'This step',
                          value: _fmtTimer(_stepElapsed),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimerCard(
                          label: 'Total',
                          value: _fmtTimer(_totalElapsed),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_isSaving)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _skipStep,
                            icon: const Icon(Icons.skip_next_rounded, size: 18),
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
                          child: FilledButton.icon(
                            onPressed: _markDone,
                            icon: Icon(
                              _currentStep == steps.length - 1
                                  ? Icons.task_alt_rounded
                                  : Icons.check_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _currentStep == steps.length - 1 ? 'Finish' : 'Done',
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

class RoutineLogSummaryScreen extends StatelessWidget {
  final RoutineLog log;
  final Routine? routine;
  final String? sourceBlockId;
  final bool showRerun;
  final VoidCallback onDone;

  const RoutineLogSummaryScreen({
    super.key,
    required this.log,
    this.routine,
    this.sourceBlockId,
    this.showRerun = false,
    required this.onDone,
  });

  String _fmt(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) return '${minutes}m ${remainingSeconds}s';
    return '${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Routine? resolvedRoutine = routine;
    if (resolvedRoutine == null) {
      final app = context.read<AppProvider>();
      for (final candidate in app.routines) {
        if (candidate.id == log.routineId) {
          resolvedRoutine = candidate;
          break;
        }
      }
    }

    final totalSeconds = log.totalDurationSeconds ?? 0;
    final title = resolvedRoutine?.name ?? log.routineName;
    final icon = resolvedRoutine?.icon ?? 'R';

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 16),
            Text(
              '$icon $title Complete!',
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
                itemCount: log.entries.length,
                itemBuilder: (context, index) {
                  final entry = log.entries[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: entry.skipped
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
                            color: entry.skipped
                                ? cs.error.withValues(alpha: 0.15)
                                : const Color(0xFF10B981).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            entry.skipped
                                ? Icons.skip_next_rounded
                                : Icons.check_rounded,
                            size: 16,
                            color: entry.skipped ? cs.error : const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.stepTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                              decoration: entry.skipped
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        Text(
                          _fmt(entry.durationSeconds ?? 0),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: entry.skipped ? cs.error : cs.primary,
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
              child: Row(
                children: [
                  if (showRerun && resolvedRoutine != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => RoutineRunnerScreen(
                                routine: resolvedRoutine!,
                                dateKey: log.date,
                                sourceBlockId: sourceBlockId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.replay_rounded, size: 18),
                        label: const Text('Rerun'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: onDone,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(showRerun ? 'Close' : 'Continue'),
                    ),
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

class _TimerCard extends StatelessWidget {
  final String label;
  final String value;

  const _TimerCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
