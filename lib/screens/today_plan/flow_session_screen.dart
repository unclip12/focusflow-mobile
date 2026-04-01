// =============================================================
// FlowSessionScreen — Full-screen active flow session view
// Shows current activity, timer, pause/resume/stop/done/add-task
// =============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/daily_flow.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'package:focusflow_mobile/services/notification_service.dart';
import 'package:focusflow_mobile/services/timer_reminder_service.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'add_task_sheet.dart';
import 'study_flow_screen.dart';

class FlowSessionScreen extends StatefulWidget {
  final String dateKey;
  const FlowSessionScreen({super.key, required this.dateKey});

  @override
  State<FlowSessionScreen> createState() => _FlowSessionScreenState();
}

class _FlowSessionScreenState extends State<FlowSessionScreen>
    with WidgetsBindingObserver {
  static const _plannedStudySessionKind = 'planned_study_session';

  // ── Timer state ──────────────────────────────────────────────
  late final DateTime _sessionStartedAt;
  int _activityElapsed = 0;
  int _totalElapsed = 0;
  Timer? _tickTimer;
  Timer? _resumePulseTimer;
  bool _localPaused = false;
  bool _showResumeAtFullOpacity = true;

  // ── Quote rotation ──────────────────────────────────────────
  Timer? _quoteTimer;
  late String _currentQuote;
  final _rng = Random();

  String get _cueSessionKey => 'flow:${widget.dateKey}';

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionStartedAt = DateTime.now();
    _currentQuote = kFocusQuotes[_rng.nextInt(kFocusQuotes.length)];

    // Compute initial elapsed from existing flow data
    final app = context.read<AppProvider>();
    final flow = app.getDailyFlow(widget.dateKey);
    if (flow != null) {
      _totalElapsed = flow.totalElapsedSeconds;
      // Current activity elapsed
      final active = flow.nextPendingActivity;
      if (active?.startedAt != null) {
        final started = DateTime.tryParse(active!.startedAt!);
        if (started != null) {
          _activityElapsed = DateTime.now().difference(started).inSeconds;
        }
      }
      _localPaused = flow.isPaused || flow.isStopped;
    }

    // Keep screen on during active flow
    WakelockPlus.enable();

    _startTimers();
    _startResumePulse();
  }

  void _startTimers() {
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_localPaused) {
        _setStateIfMounted(() {
          _activityElapsed++;
          _totalElapsed++;
        });
        unawaited(_processFlowCue());
      }
    });
    _quoteTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _setStateIfMounted(
        () => _currentQuote = kFocusQuotes[_rng.nextInt(kFocusQuotes.length)],
      );
    });
  }

  void _startResumePulse() {
    _resumePulseTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (_localPaused) {
        _setStateIfMounted(() {
          _showResumeAtFullOpacity = !_showResumeAtFullOpacity;
        });
        return;
      }
      if (!_showResumeAtFullOpacity) {
        _setStateIfMounted(() => _showResumeAtFullOpacity = true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recompute elapsed from startedAt when app resumes from background
      final app = context.read<AppProvider>();
      final flow = app.getDailyFlow(widget.dateKey);
      if (flow != null) {
        _totalElapsed = flow.totalElapsedSeconds;
        final active = flow.nextPendingActivity;
        if (active?.startedAt != null) {
          final started = DateTime.tryParse(active!.startedAt!);
          if (started != null) {
            _activityElapsed = DateTime.now().difference(started).inSeconds;
          }
        }
        _setStateIfMounted(() {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickTimer?.cancel();
    _quoteTimer?.cancel();
    _resumePulseTimer?.cancel();
    TimerReminderService.instance.clearSession(_cueSessionKey);
    WakelockPlus.disable();
    super.dispose();
  }

  String _fmtTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _to12h(String hhmm) {
    final parts = hhmm.split(':');
    final h24 = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final suffix = h24 < 12 ? 'AM' : 'PM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return '$h12:${m.toString().padLeft(2, '0')} $suffix';
  }

  // ── Actions ──────────────────────────────────────────────────

  void _completeCurrent() {
    HapticsService.medium();
    final app = context.read<AppProvider>();
    final flow = app.getDailyFlow(widget.dateKey);
    if (flow == null) return;

    final active = flow.activities.where((a) => a.isActive).toList();
    if (active.isNotEmpty) {
      app.completeFlowActivity(widget.dateKey, active.first.id);
      _setStateIfMounted(() => _activityElapsed = 0);
    }
  }

  void _showPauseDialog() {
    final app = context.read<AppProvider>();
    int pauseMinutes = 10;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
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
                    onSelected: (_) => setDState(() => pauseMinutes = m),
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
                app.pauseFlow(widget.dateKey,
                    pauseDuration: Duration(minutes: pauseMinutes));
                NotificationService.instance.scheduleAt(
                  id: 2000,
                  title: 'Flow Paused ⏸️',
                  body: 'Your pause is over — ready to continue?',
                  when: DateTime.now().add(Duration(minutes: pauseMinutes)),
                  intent: NotificationIntent.daySession(dateKey: widget.dateKey),
                );
                _setStateIfMounted(() => _localPaused = true);
                Navigator.pop(ctx);
              },
              child: Text('Pause for ${pauseMinutes}m'),
            ),
          ],
        ),
      ),
    );
  }

  void _resumeFlow() {
    final app = context.read<AppProvider>();
    app.resumeFlow(widget.dateKey);
    _setStateIfMounted(() => _localPaused = false);
    unawaited(_processFlowCue());
  }

  void _showStopDialog() {
    final app = context.read<AppProvider>();
    TimeOfDay? remindTime;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
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
                  if (picked != null) setDState(() => remindTime = picked);
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
                app.stopFlow(widget.dateKey);
                Navigator.pop(ctx);
                Navigator.pop(context);
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
                    intent:
                        NotificationIntent.daySession(dateKey: widget.dateKey),
                  );
                }
                app.stopFlow(widget.dateKey, remindAt: remindAt);
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Stop & Remind'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave session?'),
        content: const Text(
            'Your flow will continue running in the background. You can return to it from the plan screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _openAddTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(dateKey: widget.dateKey),
    );
  }

  Block? _studySessionBlockForActivity(
      AppProvider app, FlowActivity? activity) {
    if (activity == null) return null;

    final planBlocks =
        app.getDayPlan(widget.dateKey)?.blocks ?? const <Block>[];
    final candidateIds = <String>{};
    if (activity.id.startsWith('task-') && activity.id.length > 5) {
      candidateIds.add(activity.id.substring(5));
    }
    candidateIds.addAll(activity.linkedTaskIds);

    for (final block in planBlocks) {
      if (candidateIds.contains(block.id) &&
          block.type == BlockType.studySession) {
        return block;
      }
    }

    return null;
  }

  Future<void> _processFlowCue() async {
    if (!mounted || _localPaused) {
      return;
    }

    final app = context.read<AppProvider>();
    final settings = context.read<SettingsProvider>();
    final flow = app.getDailyFlow(widget.dateKey);
    final currentActivity = flow?.nextPendingActivity;
    final currentBlock = _blockForCurrentActivity(app, currentActivity);
    if (currentActivity == null ||
        currentBlock == null ||
        currentBlock.plannedDurationMinutes <= 0) {
      return;
    }

    final nextBlock = _nextBlockAfterCurrent(app, currentBlock);
    await TimerReminderService.instance.processActiveTimerCue(
      config: settings.timerReminders,
      context: ActiveTimerCueContext(
        sessionKey: _cueSessionKey,
        taskKey: currentActivity.id,
        currentLabel: currentActivity.label,
        nextLabel: nextBlock?.title,
        totalDurationSeconds: currentBlock.plannedDurationMinutes * 60,
        elapsedSeconds: _activityElapsed,
        isPaused: _localPaused,
        intent: NotificationIntent.todayPlanBlock(
          dateKey: widget.dateKey,
          blockId: currentBlock.id,
        ),
      ),
    );
  }

  Block? _blockForCurrentActivity(AppProvider app, FlowActivity? activity) {
    if (activity == null || !activity.id.startsWith('task-')) return null;

    final blockId = activity.id.substring(5);
    final planBlocks =
        app.getDayPlan(widget.dateKey)?.blocks ?? const <Block>[];
    for (final block in planBlocks) {
      if (block.id == blockId) {
        return block;
      }
    }
    return null;
  }

  Block? _nextBlockAfterCurrent(AppProvider app, Block? currentBlock) {
    if (currentBlock == null) return null;

    final sortedBlocks =
        List<Block>.from(app.getDayPlan(widget.dateKey)?.blocks ?? const [])
          ..sort((a, b) => a.index.compareTo(b.index));
    final currentIndex =
        sortedBlocks.indexWhere((block) => block.id == currentBlock.id);
    if (currentIndex < 0 || currentIndex + 1 >= sortedBlocks.length) {
      return null;
    }
    return sortedBlocks[currentIndex + 1];
  }

  List<StudyTask> _plannedQueueFromBlock(Block block) {
    final notes = block.reflectionNotes;
    if (notes == null || notes.isEmpty) {
      return const <StudyTask>[];
    }
    try {
      final decoded = jsonDecode(notes);
      if (decoded is! Map<String, dynamic>) {
        return const <StudyTask>[];
      }
      if (decoded['kind'] != _plannedStudySessionKind) {
        return const <StudyTask>[];
      }
      return StudyTask.fromJsonList(decoded['tasks']);
    } catch (_) {
      return const <StudyTask>[];
    }
  }

  int _plannedQueueMinutes(Block block, List<StudyTask> queue) {
    final notes = block.reflectionNotes;
    if (notes != null && notes.isNotEmpty) {
      try {
        final decoded = jsonDecode(notes);
        if (decoded is Map<String, dynamic>) {
          final minutes = decoded['estimatedDurationMinutes'] as int?;
          if (minutes != null && minutes > 0) {
            return minutes;
          }
        }
      } catch (_) {
        // Fall back to the block data or queue estimate.
      }
    }
    if (block.plannedDurationMinutes > 0) {
      return block.plannedDurationMinutes;
    }
    return StudyTask.estimateQueueDurationMinutes(queue);
  }

  String _formatDurationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) {
      return '${mins}min';
    }
    return '${hours}h ${mins.toString().padLeft(2, '0')}min';
  }

  double _plannedStudySessionCardHeight(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    const reservedHeight = 400.0;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final extraHeight = ((textScale - 1).clamp(0, 1.5) * 72).toDouble();
    return (constraints.maxHeight - reservedHeight - extraHeight)
        .clamp(150.0, 360.0)
        .toDouble();
  }

  Future<void> _beginPlannedStudySession(
    AppProvider app,
    Block block,
    List<StudyTask> queue,
  ) async {
    if (_localPaused) {
      await app.resumeFlow(widget.dateKey);
      _setStateIfMounted(() => _localPaused = false);
    }

    final startedAt = DateTime.now();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyFlowScreen(
          dateKey: widget.dateKey,
          queuedTasks: queue,
          onComplete: () {
            final completedAt = DateTime.now();
            unawaited(
              app.completeDayPlanBlock(
                widget.dateKey,
                block.id,
                startedAt: startedAt,
                completedAt: completedAt,
                durationSeconds: completedAt.difference(startedAt).inSeconds,
                autoAdvanceFlow: true,
              ),
            );
            _setStateIfMounted(() => _activityElapsed = 0);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final app = context.watch<AppProvider>();
    final flow = app.getDailyFlow(widget.dateKey);

    // If flow completed, show celebration then pop
    if (flow != null && flow.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCompletionDialog();
      });
    }

    final activities = flow?.activities ?? [];
    final completed = activities.where((a) => a.isDone || a.isSkipped).length;
    final total = activities.length;
    final progress = total > 0 ? completed / total : 0.0;

    // Current active activity
    final currentActivity = flow?.nextPendingActivity;
    final isFlowPaused = flow?.isPaused == true || flow?.isStopped == true;
    final currentBlock = _blockForCurrentActivity(app, currentActivity);
    final nextBlock = _nextBlockAfterCurrent(app, currentBlock);
    final studySessionBlock =
        _studySessionBlockForActivity(app, currentActivity);
    final plannedQueue = studySessionBlock != null
        ? _plannedQueueFromBlock(studySessionBlock)
        : const <StudyTask>[];
    final hasPlannedStudySession =
        studySessionBlock != null && plannedQueue.isNotEmpty;
    final plannedQueueMinutes = hasPlannedStudySession
        ? _plannedQueueMinutes(studySessionBlock, plannedQueue)
        : 0;

    // Sync local pause state
    if (isFlowPaused != _localPaused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setStateIfMounted(() => _localPaused = isFlowPaused);
      });
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final plannedStudySessionCardMaxHeight = hasPlannedStudySession
                ? _plannedStudySessionCardHeight(context, constraints)
                : 0.0;
            return Column(
              children: [
                // ── Top bar ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: cs.onSurface.withValues(alpha: 0.5)),
                        onPressed: _showExitConfirm,
                      ),
                      const Spacer(),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle,
                                size: 8,
                                color: _localPaused
                                    ? Colors.orange
                                    : const Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Text(
                              _localPaused ? 'Paused' : 'In Flow',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Add task button
                      IconButton(
                        icon: Icon(Icons.add_rounded, color: cs.primary),
                        onPressed: _openAddTask,
                      ),
                    ],
                  ),
                ),

                // ── Progress bar ───────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$completed / $total activities',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
                          valueColor: AlwaysStoppedAnimation(
                            completed == total && total > 0
                                ? const Color(0xFF10B981)
                                : cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ── Current activity name ──────────────────────────
                if (currentActivity != null) ...[
                  Text(
                    currentActivity.icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      currentActivity.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (currentBlock != null &&
                      currentBlock.plannedEndTime.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Ends at ${_to12h(currentBlock.plannedEndTime)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.58),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ] else ...[
                  Icon(Icons.check_circle_rounded,
                      size: 64, color: const Color(0xFF10B981)),
                  const SizedBox(height: 16),
                  Text(
                    'All activities done!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                if (hasPlannedStudySession)
                  _StudySessionLaunchCard(
                    queue: plannedQueue,
                    durationLabel: _formatDurationLabel(plannedQueueMinutes),
                    maxHeight: plannedStudySessionCardMaxHeight,
                    onBegin: () => _beginPlannedStudySession(
                      app,
                      studySessionBlock,
                      plannedQueue,
                    ),
                  )
                else ...[
                  // ── Large timer ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 24),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _fmtTime(_activityElapsed),
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 56,
                            color: cs.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total: ${_fmtTime(_totalElapsed)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Started at ─────────────────────────────────────
                  Text(
                    'Session started at ${DateFormat('h:mm a').format(_sessionStartedAt)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],

                const Spacer(flex: 2),

                // ── Control buttons ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Pause / Resume
                      if (_localPaused)
                        Expanded(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 800),
                            opacity: _showResumeAtFullOpacity ? 1.0 : 0.6,
                            child: _ActionButton(
                              icon: Icons.play_arrow_rounded,
                              label: 'Resume',
                              color: Colors.white,
                              backgroundColor: const Color(0xFF3B82F6),
                              onTap: _resumeFlow,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.pause_rounded,
                            label: 'Pause',
                            color: const Color(0xFFF59E0B),
                            backgroundColor:
                                const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            onTap: _showPauseDialog,
                          ),
                        ),
                      const SizedBox(width: 10),
                      // Done / Next
                      if (currentActivity != null && !hasPlannedStudySession)
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.check_rounded,
                            label: 'Done',
                            color: Colors.white,
                            backgroundColor: const Color(0xFF10B981),
                            onTap: _completeCurrent,
                          ),
                        ),
                      const SizedBox(width: 10),
                      // Stop
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.stop_rounded,
                          label: 'Stop',
                          color: Colors.white,
                          backgroundColor: cs.error,
                          onTap: _showStopDialog,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // ── Motivational quote ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      '"$_currentQuote"',
                      key: ValueKey(_currentQuote),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: cs.onSurface.withValues(alpha: 0.35),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (nextBlock != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(18),
                      border: Border(
                        left: BorderSide(
                          color: cs.primary.withValues(alpha: 0.75),
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Up next',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          nextBlock.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_to12h(nextBlock.plannedStartTime)} • ${_formatDurationLabel(nextBlock.plannedDurationMinutes)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.56),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _completionShown = false;

  void _showCompletionDialog() {
    if (_completionShown) return;
    _completionShown = true;
    _tickTimer?.cancel();
    _quoteTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Flow Complete! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🌟',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              'Amazing! You completed all your activities.\n'
              'Total time: ${_fmtTime(_totalElapsed)}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Back to Plan'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ACTION BUTTON
// ═══════════════════════════════════════════════════════════════════

class _StudySessionLaunchCard extends StatelessWidget {
  final List<StudyTask> queue;
  final String durationLabel;
  final double maxHeight;
  final VoidCallback onBegin;

  const _StudySessionLaunchCard({
    required this.queue,
    required this.durationLabel,
    required this.maxHeight,
    required this.onBegin,
  });

  IconData _iconForTask(StudyTask task) {
    switch (task.type) {
      case 'FA':
        return Icons.menu_book_rounded;
      case 'UWORLD':
        return Icons.quiz_rounded;
      case 'SKETCHY_MICRO':
      case 'SKETCHY_PHARM':
        return Icons.play_circle_rounded;
      case 'PATHOMA':
        return Icons.ondemand_video_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  Color _colorForTask(StudyTask task) {
    switch (task.type) {
      case 'FA':
        return const Color(0xFF8B5CF6);
      case 'UWORLD':
        return const Color(0xFFF59E0B);
      case 'SKETCHY_MICRO':
        return const Color(0xFF3B82F6);
      case 'SKETCHY_PHARM':
        return const Color(0xFFEC4899);
      case 'PATHOMA':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final itemCount = StudyTask.totalItemCount(queue);

    return SizedBox(
      height: maxHeight,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.school_rounded, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Study Session',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$itemCount item${itemCount == 1 ? '' : 's'} • $durationLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final task = queue[index];
                  return Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(
                      bottom: index == queue.length - 1 ? 0 : 10,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _iconForTask(task),
                          size: 20,
                          color: _colorForTask(task),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                task.detail,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.62),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onBegin,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Begin Study Session'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
