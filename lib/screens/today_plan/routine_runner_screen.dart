import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focusflow_mobile/models/routine.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'package:focusflow_mobile/services/notification_service.dart';
import 'package:focusflow_mobile/services/offline_suggestion_catalog.dart';
import 'package:focusflow_mobile/services/timer_reminder_service.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
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

  static Future<void> open(
    BuildContext context, {
    required Routine routine,
    required String dateKey,
    String? sourceBlockId,
    VoidCallback? onComplete,
    bool forceRestart = false,
    bool replaceCurrent = false,
  }) async {
    final app = context.read<AppProvider>();
    final existingRun = app.getActiveRoutineRun();
    final activeRun = await app.startOrResumeRoutineRun(
      routine: routine,
      dateKey: dateKey,
      sourceBlockId: sourceBlockId,
      forceRestart: forceRestart,
    );
    if (!context.mounted) return;

    final resolvedRoutine = app.getRoutineById(activeRun.routineId) ?? routine;
    final shouldKeepOnComplete = existingRun == null ||
        forceRestart ||
        (existingRun.routineId == routine.id && existingRun.dateKey == dateKey);
    final route = MaterialPageRoute<void>(
      builder: (_) => RoutineRunnerScreen(
        routine: resolvedRoutine,
        dateKey: activeRun.dateKey,
        sourceBlockId: activeRun.sourceBlockId,
        onComplete: shouldKeepOnComplete ? onComplete : null,
      ),
    );

    final navigator = Navigator.of(context);
    if (replaceCurrent) {
      await navigator.pushReplacement(route);
      return;
    }
    await navigator.push(route);
  }

  @override
  State<RoutineRunnerScreen> createState() => _RoutineRunnerScreenState();
}

class _RoutineRunnerScreenState extends State<RoutineRunnerScreen>
    with WidgetsBindingObserver {
  static const _motivations = <String>[
    'You got this.',
    'Keep going.',
    'One step at a time.',
    'Almost there.',
    'Stay focused.',
    'Great progress.',
    'Keep the momentum.',
  ];

  bool _isSaving = false;
  bool _isLoading = true;
  Timer? _timer;
  RoutineLog? _completedLog;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_ensureRoutineRun());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _completedLog != null || _isSaving) return;
      unawaited(_processRoutineCue());
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    TimerReminderService.instance
        .clearSession('routine:${widget.routine.id}:${widget.dateKey}');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  Future<void> _ensureRoutineRun() async {
    await context.read<AppProvider>().startOrResumeRoutineRun(
          routine: widget.routine,
          dateKey: widget.dateKey,
          sourceBlockId: widget.sourceBlockId,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    unawaited(_processRoutineCue());
  }

  Future<void> _processRoutineCue() async {
    if (!mounted || _isLoading || _completedLog != null || _isSaving) {
      return;
    }

    final app = context.read<AppProvider>();
    final settings = context.read<SettingsProvider>();
    final routine = app.getRoutineById(widget.routine.id) ?? widget.routine;
    final run = app.getActiveRoutineRunForRoutine(routine.id, widget.dateKey);
    if (run == null || routine.steps.isEmpty) {
      return;
    }

    final stepIndex = run.currentStepIndex.clamp(0, routine.steps.length - 1);
    final step = routine.steps[stepIndex];
    final estimatedMinutes = step.estimatedMinutes;
    if (estimatedMinutes == null || estimatedMinutes <= 0) {
      return;
    }

    final nextLabel = stepIndex + 1 < routine.steps.length
        ? routine.steps[stepIndex + 1].title
        : null;

    await TimerReminderService.instance.processActiveTimerCue(
      config: settings.timerReminders,
      context: ActiveTimerCueContext(
        sessionKey: 'routine:${routine.id}:${widget.dateKey}',
        taskKey: step.id,
        currentLabel: step.title,
        nextLabel: nextLabel,
        totalDurationSeconds: estimatedMinutes * 60,
        elapsedSeconds: run.currentStepElapsedSecondsAt(),
        intent: NotificationIntent.todayPlan(
          dateKey: widget.dateKey,
          routineId: routine.id,
        ),
      ),
    );
  }

  Future<void> _markDone(
    AppProvider app,
    ActiveRoutineRun run,
    Routine routine,
  ) async {
    if (_isSaving) return;
    HapticsService.medium();
    if (run.currentStepIndex >= routine.steps.length - 1) {
      await _completeRoutine(app, routine: routine, skipped: false);
      return;
    }
    await app.advanceActiveRoutineStep(routine: routine, skipped: false);
  }

  Future<void> _skipStep(
    AppProvider app,
    ActiveRoutineRun run,
    Routine routine,
  ) async {
    if (_isSaving) return;
    HapticsService.light();
    if (run.currentStepIndex >= routine.steps.length - 1) {
      await _completeRoutine(app, routine: routine, skipped: true);
      return;
    }
    await app.advanceActiveRoutineStep(routine: routine, skipped: true);
  }

  Future<void> _completeRoutine(
    AppProvider app, {
    required Routine routine,
    required bool skipped,
  }) async {
    if (_isSaving) return;
    HapticsService.heavy();
    setState(() => _isSaving = true);

    final log = await app.completeActiveRoutineRun(
      routine: routine,
      skipped: skipped,
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
            onPressed: () async {
              final app = context.read<AppProvider>();
              final dialogNavigator = Navigator.of(ctx);
              final pageNavigator = Navigator.of(context);
              await app.cancelActiveRoutineRun();
              if (!mounted) return;
              dialogNavigator.pop();
              pageNavigator.pop();
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

  Future<void> _setChecklistItemChecked(
    AppProvider app, {
    required String stepId,
    required String itemId,
    required bool checked,
  }) async {
    await app.setActiveRoutineChecklistItemChecked(
      stepId: stepId,
      itemId: itemId,
      checked: checked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedLog = _completedLog;
    if (completedLog != null) {
      return RoutineLogSummaryScreen(
        routine: context.read<AppProvider>().getRoutineById(widget.routine.id) ??
            widget.routine,
        log: completedLog,
        sourceBlockId: widget.sourceBlockId,
        onDone: () {
          Navigator.pop(context);
          widget.onComplete?.call();
        },
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final app = context.watch<AppProvider>();
    final routine = app.getRoutineById(widget.routine.id) ?? widget.routine;
    final activeRun = app.getActiveRoutineRunForRoutine(
      routine.id,
      widget.dateKey,
    );
    if (activeRun == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_off_rounded, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'This routine is no longer active.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final steps = routine.steps;
    if (steps.isEmpty) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(routine.icon, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    '${routine.name} has no steps.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentStepIndex =
        activeRun.currentStepIndex.clamp(0, steps.length - 1).toInt();
    final totalElapsed = activeRun.totalElapsedSecondsAt();
    final stepElapsed = activeRun.currentStepElapsedSecondsAt();
    final step = steps[currentStepIndex];
    final remainingStepSeconds = step.estimatedMinutes == null
        ? 0
        : math.max(0, (step.estimatedMinutes! * 60) - stepElapsed);
    final progress = (currentStepIndex + 1) / steps.length;
    final motivation = _motivations[currentStepIndex % _motivations.length];
    final stepEmoji = step.emoji.trim().isEmpty ? routine.icon : step.emoji;
    final animationPreset = OfflineSuggestionCatalog.animationPresetFor(
      step.title,
    );

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(routine.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      routine.name,
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
                        'Step ${currentStepIndex + 1} of ${steps.length}',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AnimatedStepEmojiCard(
                        emoji: stepEmoji,
                        color: Color(routine.color),
                        animationPreset: animationPreset,
                        stepLabel: '${currentStepIndex + 1}',
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
                      if (step.checklistItems.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Checklist',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final item in step.checklistItems)
                                CheckboxListTile(
                                  value: activeRun.isChecklistItemChecked(
                                    step.id,
                                    item.id,
                                  ),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    _setChecklistItemChecked(
                                      app,
                                      stepId: step.id,
                                      itemId: item.id,
                                      checked: value ?? false,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
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
                          value: _fmtTimer(stepElapsed),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimerCard(
                          label: 'Remaining',
                          value: _fmtTimer(remainingStepSeconds),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimerCard(
                          label: 'Total',
                          value: _fmtTimer(totalElapsed),
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
                            onPressed: () => _skipStep(app, activeRun, routine),
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
                            onPressed: () => _markDone(app, activeRun, routine),
                            icon: Icon(
                              currentStepIndex == steps.length - 1
                                  ? Icons.task_alt_rounded
                                  : Icons.check_rounded,
                              size: 18,
                            ),
                            label: Text(
                              currentStepIndex == steps.length - 1
                                  ? 'Finish'
                                  : 'Done',
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

class _AnimatedStepEmojiCard extends StatefulWidget {
  final String emoji;
  final Color color;
  final String animationPreset;
  final String stepLabel;

  const _AnimatedStepEmojiCard({
    required this.emoji,
    required this.color,
    required this.animationPreset,
    required this.stepLabel,
  });

  @override
  State<_AnimatedStepEmojiCard> createState() => _AnimatedStepEmojiCardState();
}

class _AnimatedStepEmojiCardState extends State<_AnimatedStepEmojiCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    Widget child = Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.12),
            blurRadius: 26,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            widget.emoji,
            style: const TextStyle(fontSize: 44),
          ),
          Positioned(
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Step ${widget.stepLabel}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    switch (widget.animationPreset) {
      case 'bounce':
        child = ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.05).animate(curved),
          child: child,
        );
        break;
      case 'slide':
        child = SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.03, 0),
            end: const Offset(0.03, 0),
          ).animate(curved),
          child: child,
        );
        break;
      case 'breathe':
        child = FadeTransition(
          opacity: Tween<double>(begin: 0.78, end: 1).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.03).animate(curved),
            child: child,
          ),
        );
        break;
      case 'float':
      case 'sunrise':
      case 'sway':
      case 'bob':
      default:
        child = SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: const Offset(0, -0.02),
          ).animate(curved),
          child: child,
        );
        break;
    }

    return child;
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
                            : () => RoutineRunnerScreen.open(
                                  context,
                                  routine: resolvedRoutine,
                                  dateKey: _log.date,
                                  sourceBlockId: widget.sourceBlockId,
                                  forceRestart: true,
                                  replaceCurrent: true,
                                ),
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
