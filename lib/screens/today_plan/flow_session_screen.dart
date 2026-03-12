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
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'package:focusflow_mobile/services/notification_service.dart';
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
  bool _localPaused = false;

  // ── Quote rotation ──────────────────────────────────────────
  Timer? _quoteTimer;
  late String _currentQuote;
  final _rng = Random();

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
  }

  void _startTimers() {
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_localPaused && mounted) {
        setState(() {
          _activityElapsed++;
          _totalElapsed++;
        });
      }
    });
    _quoteTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(
          () => _currentQuote = kFocusQuotes[_rng.nextInt(kFocusQuotes.length)],
        );
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
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickTimer?.cancel();
    _quoteTimer?.cancel();
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

  // ── Actions ──────────────────────────────────────────────────

  void _completeCurrent() {
    HapticsService.medium();
    final app = context.read<AppProvider>();
    final flow = app.getDailyFlow(widget.dateKey);
    if (flow == null) return;

    final active = flow.activities.where((a) => a.isActive).toList();
    if (active.isNotEmpty) {
      app.completeFlowActivity(widget.dateKey, active.first.id);
      setState(() => _activityElapsed = 0);
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
                );
                setState(() => _localPaused = true);
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
    setState(() => _localPaused = false);
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

  Future<void> _beginPlannedStudySession(
    AppProvider app,
    Block block,
    List<StudyTask> queue,
  ) async {
    if (_localPaused) {
      await app.resumeFlow(widget.dateKey);
      if (mounted) {
        setState(() => _localPaused = false);
      }
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
            if (mounted) {
              setState(() => _activityElapsed = 0);
            }
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
        if (mounted) setState(() => _localPaused = isFlowPaused);
      });
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                onBegin: () => _beginPlannedStudySession(
                  app,
                  studySessionBlock,
                  plannedQueue,
                ),
              )
            else ...[
              // ── Large timer ────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
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
                      child: _ActionButton(
                        icon: Icons.play_arrow_rounded,
                        label: 'Resume',
                        color: Colors.white,
                        backgroundColor: const Color(0xFF3B82F6),
                        onTap: _resumeFlow,
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
          ],
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
  final VoidCallback onBegin;

  const _StudySessionLaunchCard({
    required this.queue,
    required this.durationLabel,
    required this.onBegin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final itemCount = StudyTask.totalItemCount(queue);

    return Container(
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: SingleChildScrollView(
              child: Column(
                children: queue
                    .map(
                      (task) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
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
                              task.type == 'FA'
                                  ? Icons.menu_book_rounded
                                  : Icons.quiz_rounded,
                              size: 20,
                              color: task.type == 'FA'
                                  ? const Color(0xFF8B5CF6)
                                  : const Color(0xFFF59E0B),
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
                                      color:
                                          cs.onSurface.withValues(alpha: 0.62),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
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
