import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class RoutineLogSummaryScreen extends StatefulWidget {
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

  @override
  State<RoutineLogSummaryScreen> createState() => _RoutineLogSummaryScreenState();
}

class _RoutineLogSummaryScreenState extends State<RoutineLogSummaryScreen> {
  late RoutineLog _log;
  bool _isUpdatingActuals = false;

  @override
  void initState() {
    super.initState();
    _log = widget.log;
  }

  String _fmt(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = seconds ~/ 60;
    final remainingMinutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    }
    if (minutes > 0) return '${minutes}m ${remainingSeconds}s';
    return '${remainingSeconds}s';
  }

  Routine? _resolveRoutine(BuildContext context) {
    Routine? resolvedRoutine = widget.routine;
    if (resolvedRoutine == null) {
      final app = context.read<AppProvider>();
      for (final candidate in app.routines) {
        if (candidate.id == _log.routineId) {
          resolvedRoutine = candidate;
          break;
        }
      }
    }
    return resolvedRoutine;
  }

  RoutineLog _rebuildLogFromEdits(List<_RoutineLogEditValue> edits) {
    var cursor = DateTime.tryParse(_log.startTime) ?? DateTime.now();
    var totalDurationSeconds = 0;
    final rebuiltEntries = <RoutineLogEntry>[];

    for (var index = 0; index < _log.entries.length; index++) {
      final originalEntry = _log.entries[index];
      final edit = edits[index];
      final durationSeconds = edit.durationMinutes * 60;
      final startTime = cursor;
      cursor = cursor.add(Duration(minutes: edit.durationMinutes));
      totalDurationSeconds += durationSeconds;

      rebuiltEntries.add(
        originalEntry.copyWith(
          startTime: startTime.toIso8601String(),
          endTime: cursor.toIso8601String(),
          durationSeconds: durationSeconds,
          skipped: edit.skipped,
        ),
      );
    }

    return _log.copyWith(
      entries: rebuiltEntries,
      totalDurationSeconds: totalDurationSeconds,
      endTime: cursor.toIso8601String(),
    );
  }

  Future<void> _editActuals() async {
    final edits = await showModalBottomSheet<List<_RoutineLogEditValue>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoutineLogEditSheet(log: _log, formatDuration: _fmt),
    );
    if (edits == null || !mounted) return;

    setState(() => _isUpdatingActuals = true);
    try {
      final updatedLog = _rebuildLogFromEdits(edits);
      final savedLog = await context.read<AppProvider>().updateCompletedRoutineActuals(
        log: updatedLog,
        sourceBlockId: widget.sourceBlockId,
      );
      if (!mounted) return;
      setState(() {
        _log = savedLog;
        _isUpdatingActuals = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine actuals updated')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUpdatingActuals = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update routine actuals')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedRoutine = _resolveRoutine(context);
    final totalSeconds = _log.totalDurationSeconds ?? 0;
    final title = resolvedRoutine?.name ?? _log.routineName;
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _isUpdatingActuals ? null : _editActuals,
                  icon: _isUpdatingActuals
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_rounded, size: 18),
                  label: Text(_isUpdatingActuals ? 'Updating...' : 'Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _log.entries.length,
                itemBuilder: (context, index) {
                  final entry = _log.entries[index];
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
                  if (widget.showRerun && resolvedRoutine != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUpdatingActuals
                            ? null
                            : () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => RoutineRunnerScreen(
                                routine: resolvedRoutine,
                                dateKey: _log.date,
                                sourceBlockId: widget.sourceBlockId,
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
                      onPressed: _isUpdatingActuals ? null : widget.onDone,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(widget.showRerun ? 'Close' : 'Continue'),
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

class _RoutineLogEditValue {
  final int durationMinutes;
  final bool skipped;

  const _RoutineLogEditValue({
    required this.durationMinutes,
    required this.skipped,
  });
}

class _RoutineLogEditSheet extends StatefulWidget {
  final RoutineLog log;
  final String Function(int seconds) formatDuration;

  const _RoutineLogEditSheet({
    required this.log,
    required this.formatDuration,
  });

  @override
  State<_RoutineLogEditSheet> createState() => _RoutineLogEditSheetState();
}

class _RoutineLogEditSheetState extends State<_RoutineLogEditSheet> {
  late final List<TextEditingController> _durationControllers;
  late final List<bool> _skippedStates;

  @override
  void initState() {
    super.initState();
    _durationControllers = widget.log.entries
        .map(
          (entry) => TextEditingController(
            text: _initialMinutes(entry).toString(),
          ),
        )
        .toList(growable: false);
    _skippedStates = widget.log.entries
        .map((entry) => entry.skipped)
        .toList(growable: false);
  }

  int _initialMinutes(RoutineLogEntry entry) {
    final seconds = entry.durationSeconds ?? 0;
    if (seconds <= 0) return 0;
    return (seconds / 60).ceil();
  }

  @override
  void dispose() {
    for (final controller in _durationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final values = List<_RoutineLogEditValue>.generate(widget.log.entries.length, (
      index,
    ) {
      final isSkipped = _skippedStates[index];
      final parsedMinutes = int.tryParse(_durationControllers[index].text.trim()) ?? 0;
      final durationMinutes = isSkipped
          ? 0
          : parsedMinutes.clamp(0, 24 * 60).toInt();
      return _RoutineLogEditValue(
        durationMinutes: durationMinutes,
        skipped: isSkipped,
      );
    });

    Navigator.of(context).pop(values);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.82;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SizedBox(
        height: maxHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Actual Durations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update what you actually did for each step.',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.log.entries.length,
                  itemBuilder: (context, index) {
                    final entry = widget.log.entries[index];
                    final isSkipped = _skippedStates[index];
                    final enabled = !isSkipped;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: enabled
                                      ? cs.primary.withValues(alpha: 0.12)
                                      : cs.error.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  enabled
                                      ? Icons.check_rounded
                                      : Icons.skip_next_rounded,
                                  size: 16,
                                  color: enabled ? cs.primary : cs.error,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.stepTitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                    decoration: isSkipped
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Original: ${widget.formatDuration(entry.durationSeconds ?? 0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.58),
                            ),
                          ),
                          if (entry.skipped) ...[
                            const SizedBox(height: 12),
                            CheckboxListTile(
                              value: !isSkipped,
                              onChanged: (value) {
                                setState(() {
                                  _skippedStates[index] = !(value ?? false);
                                  if (_skippedStates[index]) {
                                    _durationControllers[index].text = '0';
                                  }
                                });
                              },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text('I actually completed this step'),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextField(
                            controller: _durationControllers[index],
                            enabled: enabled,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Actual minutes',
                              hintText: '0',
                              helperText: enabled
                                  ? 'Enter minutes for this step'
                                  : 'Marked as skipped',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Update'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
