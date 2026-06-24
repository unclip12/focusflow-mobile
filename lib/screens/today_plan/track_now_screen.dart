import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/daily_flow.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'package:focusflow_mobile/services/notification_service.dart';
import 'package:focusflow_mobile/services/background_timer_service.dart';
import 'package:focusflow_mobile/services/activity_history_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:focusflow_mobile/screens/today_plan/add_task_sheet.dart';


// Preset backfill durations shown as quick chips
const _kBackfillPresets = [0, 2, 5, 10, 15, 20, 25, 30];

enum _TrackNowInterruptChoice { pauseAndTrack, linkToCurrent }

// ═══════════════════════════════════════════════════════════════
// TrackNowScreen
// ═══════════════════════════════════════════════════════════════

class TrackNowScreen extends StatefulWidget {
  final String dateKey;
  /// If resuming an existing Track Now activity, pass its ID.
  final String? existingActivityId;

  const TrackNowScreen({
    super.key,
    required this.dateKey,
    this.existingActivityId,
  });

  @override
  State<TrackNowScreen> createState() => _TrackNowScreenState();
}

class _TrackNowScreenState extends State<TrackNowScreen>
    with WidgetsBindingObserver {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isTracking = false;
  String? _trackingActivityId;
  DateTime? _startedAt;
  String? _initialActivityLabel;

  // Selected existing task to link to
  String? _selectedTaskId;
  String? _selectedTaskTitle;
  String? _pausedPlannedBlockId;

  // Timer state
  int _elapsed = 0;
  Timer? _tickTimer;

  // Activity history autocomplete
  List<MapEntry<String, int>> _suggestions = [];

  // Recently tracked tasks
  List<MapEntry<String, Map<String, dynamic>>> _recentTasks = [];
  bool _showAllRecent = false;

  // "Started X minutes ago" backfill (0 = right now)
  int _backfillMinutes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecentTasks();
    // If resuming an existing activity
    if (widget.existingActivityId != null) {
      final app = context.read<AppProvider>();
      final activity = _findActivityById(app, widget.existingActivityId);
      if (activity != null) {
        _initialActivityLabel = activity.label;
        final linkedTaskId = activity.linkedTaskIds.isNotEmpty
            ? activity.linkedTaskIds.first
            : null;
        final linkedTaskTitle = linkedTaskId != null
            ? _resolveLinkedTaskTitle(app, linkedTaskId)
            : null;
        _selectedTaskId = linkedTaskId;
        _selectedTaskTitle = linkedTaskTitle;
        _nameCtrl.text = linkedTaskTitle ?? activity.label;
        _notesCtrl.text = activity.notes ?? '';
        _trackingActivityId = activity.id;
        _isTracking = true;
        if (activity.startedAt != null) {
          _startedAt = DateTime.tryParse(activity.startedAt!);
          if (_startedAt != null) {
            _elapsed = DateTime.now().difference(_startedAt!).inSeconds;
          }
        }
        WakelockPlus.enable();
        _resumeTimerState();
      }
    }
  }

  Future<void> _loadRecentTasks() async {
    final recent = await ActivityHistoryService.getRecent();
    if (mounted) {
      setState(() {
        _recentTasks = recent;
      });
    }
  }

  Future<void> _resumeTimerState() async {
    final bgElapsed = await BackgroundTimerService.getElapsed();
    if (bgElapsed != null && bgElapsed > _elapsed && mounted) {
      setState(() {
        _elapsed = bgElapsed;
        if (_startedAt != null) {
          _startedAt = DateTime.now().subtract(Duration(seconds: bgElapsed));
        }
      });
    }
    _startTimer();
  }

  FlowActivity? _findActivityById(AppProvider app, String? activityId) {
    if (activityId == null) return null;
    final flow = app.getDailyFlow(widget.dateKey);
    if (flow == null) return null;
    try {
      return flow.activities.firstWhere(
        (a) => a.id == activityId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<_TrackNowInterruptChoice?> _showInterruptChoice(String blockTitle) {
    return showModalBottomSheet<_TrackNowInterruptChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$blockTitle is already running',
                    style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how Track Now should handle the current task.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.pause_circle_outline_rounded),
                    title: const Text('Pause current task'),
                    subtitle: const Text('Pause it, then start Track Now'),
                    onTap: () => Navigator.of(sheetContext).pop(
                      _TrackNowInterruptChoice.pauseAndTrack,
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.link_rounded),
                    title: const Text('Link to current task'),
                    subtitle: const Text('Keep the current task running instead'),
                    onTap: () => Navigator.of(sheetContext).pop(
                      _TrackNowInterruptChoice.linkToCurrent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<TrackNowConflictChoice?> _showConflictChoice(List<Block> conflicts) {
    return showModalBottomSheet<TrackNowConflictChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        final conflictTitle = conflicts.first.title;
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This tracked time overlaps $conflictTitle',
                    style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how the timeline should save this session.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_send_rounded),
                    title: const Text('Push planned block'),
                    subtitle:
                        const Text('Move the planned task later and keep this tracked block'),
                    onTap: () => Navigator.of(sheetContext)
                        .pop(TrackNowConflictChoice.push),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.content_cut_rounded),
                    title: const Text('Consume planned time'),
                    subtitle: const Text(
                      'Use this tracked block inside the planned time window',
                    ),
                    onTap: () => Navigator.of(sheetContext)
                        .pop(TrackNowConflictChoice.consume),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.layers_rounded),
                    title: const Text('Overlap'),
                    subtitle:
                        const Text('Show both the planned block and this tracked block'),
                    onTap: () => Navigator.of(sheetContext)
                        .pop(TrackNowConflictChoice.overlap),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmCascadePush() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Push later tasks too?'),
        content: const Text(
          'This push would collide with later planned tasks. Push all later movable tasks forward as well?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Push Later Tasks'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<TrackNowResumeChoice?> _showResumeChoice(String blockTitle) {
    return showModalBottomSheet<TrackNowResumeChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resume $blockTitle?',
                    style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The task was paused when Track Now started.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_arrow_rounded),
                    title: const Text('Resume now'),
                    onTap: () =>
                        Navigator.of(sheetContext).pop(TrackNowResumeChoice.now),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Resume after delay'),
                    onTap: () => Navigator.of(sheetContext)
                        .pop(TrackNowResumeChoice.later),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.pause_rounded),
                    title: const Text('Leave paused'),
                    onTap: () => Navigator.of(sheetContext)
                        .pop(TrackNowResumeChoice.keepPaused),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<int?> _askDelayMinutes() async {
    final controller = TextEditingController(text: '15');
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resume after how many minutes?'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Minutes',
            hintText: '15',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text.trim());
              Navigator.of(dialogContext).pop(minutes);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result <= 0) return null;
    return result;
  }

  void _startTimer() {
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });

    final name = _trackingDisplayName;
    if (name.isNotEmpty) {
      BackgroundTimerService.start(
        activityName: name,
        elapsedSeconds: _elapsed,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isTracking && _startedAt != null) {
      setState(() {
        _elapsed = DateTime.now().difference(_startedAt!).inSeconds;
      });
      final name = _trackingDisplayName;
      BackgroundTimerService.start(
        activityName: name.isNotEmpty ? name : 'Session',
        elapsedSeconds: _elapsed,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickTimer?.cancel();
    _nameCtrl.dispose();
    _notesCtrl.dispose();
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

  String get _trackingDisplayName {
    final selectedTitle = _selectedTaskTitle?.trim();
    if (selectedTitle != null && selectedTitle.isNotEmpty) return selectedTitle;

    final manualName = _nameCtrl.text.trim();
    if (manualName.isNotEmpty) return manualName;

    final initialLabel = _initialActivityLabel?.trim();
    if (initialLabel != null && initialLabel.isNotEmpty) return initialLabel;

    return '';
  }

  String? _resolveLinkedTaskTitle(AppProvider app, String taskId) {
    final flow = app.getDailyFlow(widget.dateKey);
    if (flow != null) {
      for (final activity in flow.activities) {
        if (activity.id == taskId) return activity.label;
      }
    }

    final blocks = app.getDayPlan(widget.dateKey)?.blocks ?? const [];
    for (final block in blocks) {
      if (block.id == taskId) return block.title;
      for (final task in block.tasks ?? const []) {
        if (task.id == taskId) return task.detail;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _buildLinkableItems(
    AppProvider app,
    ColorScheme cs,
  ) {
    final flow = app.getDailyFlow(widget.dateKey);
    final dayPlan = app.getDayPlan(widget.dateKey);
    final linkableItems = <Map<String, dynamic>>[];

    if (flow != null) {
      for (final activity in flow.activities) {
        if (activity.activityType == 'TRACK_NOW') continue;
        linkableItems.add({
          'id': activity.id,
          'title': activity.label,
          'subtitle': 'Today\'s Flow',
          'icon': Icons.list_alt_rounded,
          'color': cs.tertiary,
        });
      }
    }

    if (dayPlan != null) {
      final linkedBlockIds = flow?.activities.expand((a) => a.linkedTaskIds).toSet() ??
          <String>{};
      for (final block in dayPlan.blocks ?? const []) {
        if (block.type == BlockType.breakBlock || block.isVirtual == true) {
          continue;
        }
        if (linkedBlockIds.contains(block.id)) continue;
        linkableItems.add({
          'id': block.id,
          'title': block.title,
          'subtitle': 'Today\'s Plan',
          'icon': Icons.calendar_today_rounded,
          'color': const Color(0xFF6366F1),
        });
      }
    }

    return linkableItems;
  }

  Future<void> _selectExistingTask(
    Map<String, dynamic> item, {
    bool allowToggle = false,
  }) async {
    final itemId = item['id'] as String;
    final itemTitle = item['title'] as String;
    final isSelected = _selectedTaskId == itemId;

    if (isSelected && allowToggle) {
      setState(() {
        _selectedTaskId = null;
        _selectedTaskTitle = null;
        _nameCtrl.clear();
      });
      HapticsService.light();
      return;
    }

    setState(() {
      _selectedTaskId = itemId;
      _selectedTaskTitle = itemTitle;
      _nameCtrl.text = itemTitle;
      _suggestions = [];
    });
    HapticsService.light();

    if (!_isTracking || _trackingActivityId == null) return;

    final app = context.read<AppProvider>();
    final trackedActivity = _findActivityById(app, _trackingActivityId);
    if (trackedActivity != null) {
      await app.updateFlowActivity(
        widget.dateKey,
        trackedActivity.copyWith(
          label: itemTitle,
          linkedTaskIds: [itemId],
        ),
      );
    }
    if (mounted) {
      await BackgroundTimerService.start(
        activityName: _trackingDisplayName,
        elapsedSeconds: _elapsed,
      );
    }
  }

  // ── Actions ──────────────────────────────────────────────────

  Future<void> _startTracking() async {
    final name = _trackingDisplayName;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select what you are doing')),
      );
      return;
    }

    HapticsService.medium();
    final app = context.read<AppProvider>();
    final activeBlock = app.getActivePlannedBlock(widget.dateKey);
    if (activeBlock != null &&
        activeBlock.status == BlockStatus.inProgress &&
        activeBlock.id != _selectedTaskId) {
      final choice = await _showInterruptChoice(activeBlock.title);
      if (choice == null) return;
      if (choice == _TrackNowInterruptChoice.linkToCurrent) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${activeBlock.title} is already running, so its timer will continue.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
        return;
      }
      await app.pausePlannedBlock(widget.dateKey, activeBlock.id);
      _pausedPlannedBlockId = activeBlock.id;
    }

    final activity = await app.startTrackNow(
      widget.dateKey,
      label: name,
      category: null,
    );

    // Link to the selected task immediately upon start if applicable
    if (_selectedTaskId != null) {
      await app.updateFlowActivity(
        widget.dateKey,
        activity.copyWith(
          label: name,
          linkedTaskIds: [_selectedTaskId!],
        ),
      );
    }

    // Apply backfill: shift start time back by _backfillMinutes
    final backfillDuration = Duration(minutes: _backfillMinutes);
    final actualStart = DateTime.now().subtract(backfillDuration);

    if (_backfillMinutes > 0) {
      await app.updateFlowActivity(
        widget.dateKey,
        activity.copyWith(
          startedAt: actualStart.toIso8601String(),
        ),
      );
    }

    setState(() {
      _isTracking = true;
      _trackingActivityId = activity.id;
      _startedAt = actualStart;
      _elapsed = backfillDuration.inSeconds;
    });
    _startTimer();
  }

  Future<void> _stopTracking() async {
    if (_trackingActivityId == null) return;

    HapticsService.heavy();
    final app = context.read<AppProvider>();
    final name = _trackingDisplayName;
    var resolution = TrackNowConflictChoice.overlap;
    var cascadePush = false;

    if (_selectedTaskId == null && _startedAt != null) {
      final conflicts = app.getTrackNowConflictingBlocks(
        widget.dateKey,
        startedAt: _startedAt!,
        completedAt: DateTime.now(),
      );
      if (conflicts.isNotEmpty) {
        final selectedResolution = await _showConflictChoice(conflicts);
        if (selectedResolution == null) return;
        resolution = selectedResolution;
        if (resolution == TrackNowConflictChoice.push &&
            app.trackNowPushNeedsCascade(
              widget.dateKey,
              startedAt: _startedAt!,
              completedAt: DateTime.now(),
            )) {
          final approved = await _confirmCascadePush();
          if (!approved) return;
          cascadePush = true;
        }
      }
    }

    await app.stopTrackNow(
      widget.dateKey,
      _trackingActivityId!,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      linkedTaskIds: _selectedTaskId != null ? [_selectedTaskId!] : null,
      resolution: resolution,
      cascadePush: cascadePush,
      trackedColorHex: null,
    );

    _tickTimer?.cancel();
    BackgroundTimerService.stop();

    // Record label to history for future autocomplete
    if (name.isNotEmpty) {
      unawaited(ActivityHistoryService.record(name, durationSecs: _elapsed));
    }

    // Fire notification: session complete
    unawaited(NotificationService.instance.showFocusTimerDone(
      activityName: name.isNotEmpty ? name : 'Activity',
      dateKey: widget.dateKey,
    ));

    if (mounted) {
      final dur = Duration(seconds: _elapsed);
      final durStr = dur.inHours > 0
          ? '${dur.inHours}h ${dur.inMinutes.remainder(60)}m'
          : '${dur.inMinutes}m ${dur.inSeconds.remainder(60)}s';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name tracked for $durStr ✅'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (_pausedPlannedBlockId != null) {
        Block? pausedBlock;
        final blocks = app.getDayPlan(widget.dateKey)?.blocks ?? const <Block>[];
        for (final block in blocks) {
          if (block.id == _pausedPlannedBlockId) {
            pausedBlock = block;
            break;
          }
        }
        if (pausedBlock != null) {
          final resumeChoice = await _showResumeChoice(pausedBlock.title);
          if (resumeChoice == TrackNowResumeChoice.now) {
            await app.startPlannedBlock(widget.dateKey, pausedBlock.id);
          } else if (resumeChoice == TrackNowResumeChoice.later) {
            final delayMinutes = await _askDelayMinutes();
            if (delayMinutes != null) {
              await app.delayPausedBlock(
                widget.dateKey,
                pausedBlock.id,
                delay: Duration(minutes: delayMinutes),
              );
            }
          }
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Future<void> _cancelTracking() async {
    if (_trackingActivityId == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    HapticsService.medium();
    _tickTimer?.cancel();
    BackgroundTimerService.stop();
    await context.read<AppProvider>().discardTrackNow(
          widget.dateKey,
          _trackingActivityId!,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _openAddTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(dateKey: widget.dateKey),
    );
  }

  void _openExistingTaskPicker() {
    final app = context.read<AppProvider>();
    final cs = Theme.of(context).colorScheme;
    final items = _buildLinkableItems(app, cs);
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No existing tasks found for today')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'Choose Today\'s Task',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 48,
                      color: cs.outlineVariant.withValues(alpha: 0.2),
                    ),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      final isSelected = _selectedTaskId == item['id'];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          await _selectExistingTask(item);
                        },
                        leading: Icon(
                          item['icon'] as IconData,
                          color: item['color'] as Color,
                        ),
                        title: Text(
                          item['title'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(item['subtitle'] as String),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: cs.primary)
                            : Icon(
                                Icons.chevron_right_rounded,
                                color: cs.onSurface.withValues(alpha: 0.3),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLeaveConfirm() {
    if (!_isTracking) {
      Navigator.of(context).pop();
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave tracker?'),
        content: const Text(
          'The timer will keep running in the background. '
          'You can return from the Track Now banner on your plan screen.',
        ),
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

  // ── Backfill chip helper ──────────────────────────────────────

  Widget _backfillChip(int minutes, String label, ColorScheme cs) {
    final selected = _backfillMinutes == minutes;
    return GestureDetector(
      onTap: () {
        setState(() => _backfillMinutes = minutes);
        HapticsService.light();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.15)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? cs.primary
                : cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomBackfill() async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Started how many minutes ago?'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Minutes',
            hintText: 'e.g. 8',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final m = int.tryParse(controller.text.trim());
              Navigator.of(ctx).pop(m);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result > 0) {
      setState(() => _backfillMinutes = result);
      HapticsService.light();
    }
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                    onPressed: _showLeaveConfirm,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isTracking
                          ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                          : cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle,
                            size: 8,
                            color: _isTracking
                                ? const Color(0xFFEF4444)
                                : cs.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(width: 6),
                        Text(
                          _isTracking ? 'Tracking' : 'Ready',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.add_rounded, color: cs.primary),
                    onPressed: _openAddTask,
                    tooltip: 'Add Task',
                  ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────
            Expanded(
              child: _isTracking
                  ? _buildTrackingView(theme, cs)
                  : _buildSetupView(theme, cs),
            ),

            // ── Bottom action ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _isTracking
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _cancelTracking,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _stopTracking,
                            icon: const Icon(Icons.stop_rounded, size: 20),
                            label: const Text('Stop & Save'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _startTracking,
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text('Start Tracking'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Setup view (before tracking starts) ──────────────────────

  Widget _buildSetupView(ThemeData theme, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            '⏱️ Track Now',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start tracking what you\'re doing right now',
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),

          _buildExistingTasksList(theme, cs),

          const SizedBox(height: 24),

          if (_selectedTaskId == null) ...[
            Text('Or enter custom activity:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.7),
                )),
            const SizedBox(height: 8),

            // ── Activity text field with autocomplete ────────
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (val) {
                if (val.isNotEmpty && _selectedTaskId != null) {
                  setState(() {
                    _selectedTaskId = null;
                    _selectedTaskTitle = null;
                  });
                }
                if (val.trim().isEmpty) {
                  setState(() => _suggestions = []);
                  return;
                }
                ActivityHistoryService.suggest(val).then((results) {
                  if (mounted) setState(() => _suggestions = results);
                });
              },
              decoration: InputDecoration(
                hintText: 'e.g. Making Biryani',
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(fontSize: 15),
            ),

            // ── Autocomplete suggestion chips ─────────────────
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _suggestions.map((entry) {
                  return GestureDetector(
                    onTap: () {
                      _nameCtrl.text = entry.key;
                      setState(() => _suggestions = []);
                      HapticsService.light();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: cs.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${entry.value}×',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: cs.primary.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 16),

            // ── Recently Tracked section ─────────────────────────────
            if (_recentTasks.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recently Tracked',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (_recentTasks.length > 10)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showAllRecent = !_showAllRecent;
                        });
                        HapticsService.light();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _showAllRecent ? 'Show Less' : 'More',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_showAllRecent ? _recentTasks : _recentTasks.take(10))
                    .map((entry) {
                  final count = entry.value['count'] ?? 0;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _nameCtrl.text = entry.key;
                        _suggestions = [];
                      });
                      HapticsService.light();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$count×',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // ── "When did you start?" backfill section ────────
            Text(
              'When did you start?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _backfillChip(0, 'Right now', cs),
                _backfillChip(2, '2 min ago', cs),
                _backfillChip(5, '5 min ago', cs),
                _backfillChip(10, '10 min ago', cs),
                _backfillChip(15, '15 min ago', cs),
                _backfillChip(20, '20 min ago', cs),
                _backfillChip(25, '25 min ago', cs),
                _backfillChip(30, '30 min ago', cs),
                // Custom input chip
                GestureDetector(
                  onTap: _pickCustomBackfill,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (_backfillMinutes > 0 &&
                              !_kBackfillPresets
                                  .skip(1)
                                  .contains(_backfillMinutes))
                          ? cs.tertiary.withValues(alpha: 0.15)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (_backfillMinutes > 0 &&
                                !_kBackfillPresets
                                    .skip(1)
                                    .contains(_backfillMinutes))
                            ? cs.tertiary.withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      (_backfillMinutes > 0 &&
                              !_kBackfillPresets
                                  .skip(1)
                                  .contains(_backfillMinutes))
                          ? '$_backfillMinutes min ago'
                          : '⌨️ Custom',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_backfillMinutes > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 13,
                      color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 5),
                  Text(
                    'Tracking will start from $_backfillMinutes min ago',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle_rounded, color: cs.primary, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    'Ready to track:',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedTaskTitle ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Backfill section shown for existing task selection too
            Text(
              'When did you start?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _backfillChip(0, 'Right now', cs),
                _backfillChip(2, '2 min ago', cs),
                _backfillChip(5, '5 min ago', cs),
                _backfillChip(10, '10 min ago', cs),
                _backfillChip(15, '15 min ago', cs),
                _backfillChip(20, '20 min ago', cs),
                _backfillChip(25, '25 min ago', cs),
                _backfillChip(30, '30 min ago', cs),
                GestureDetector(
                  onTap: _pickCustomBackfill,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (_backfillMinutes > 0 &&
                              !_kBackfillPresets
                                  .skip(1)
                                  .contains(_backfillMinutes))
                          ? cs.tertiary.withValues(alpha: 0.15)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (_backfillMinutes > 0 &&
                                !_kBackfillPresets
                                    .skip(1)
                                    .contains(_backfillMinutes))
                            ? cs.tertiary.withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      (_backfillMinutes > 0 &&
                              !_kBackfillPresets
                                  .skip(1)
                                  .contains(_backfillMinutes))
                          ? '$_backfillMinutes min ago'
                          : '⌨️ Custom',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_backfillMinutes > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 13,
                      color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 5),
                  Text(
                    'Tracking will start from $_backfillMinutes min ago',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildExistingTasksList(ThemeData theme, ColorScheme cs) {
    final app = context.watch<AppProvider>();
    final linkableItems = _buildLinkableItems(app, cs);

    if (linkableItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select an existing task for today:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.7),
            )),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: linkableItems.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 48,
              color: cs.outlineVariant.withValues(alpha: 0.2),
            ),
            itemBuilder: (context, index) {
              final item = linkableItems[index];
              final isSelected = _selectedTaskId == item['id'];
              return ListTile(
                dense: true,
                onTap: () => _selectExistingTask(item, allowToggle: true),
                leading: Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 20,
                ),
                title: Text(
                  item['title'] as String,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item['subtitle'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: cs.primary)
                    : Icon(Icons.circle_outlined,
                        color: cs.onSurface.withValues(alpha: 0.2)),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Tracking view (timer running) ────────────────────────────

  Widget _buildTrackingView(ThemeData theme, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          Text(
            'Currently tracking',
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 0.3,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '⏱️',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            _trackingDisplayName.isNotEmpty ? _trackingDisplayName : 'Session',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 32),

          // Large timer
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  _fmtTime(_elapsed),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 56,
                    color: const Color(0xFFEF4444),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (_startedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Started at ${DateFormat('h:mm a').format(_startedAt!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notes field
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _notesCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Notes... (what did you cook?)',
                hintStyle: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 8, top: 14),
                  child: Icon(Icons.sticky_note_2_outlined,
                      size: 18,
                      color: cs.onSurface.withValues(alpha: 0.3)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),

          const SizedBox(height: 16),

          // Existing task picker row
          Material(
            color: cs.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _openExistingTaskPicker,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.playlist_add_check_rounded,
                        size: 18, color: cs.primary.withValues(alpha: 0.6)),
                    const SizedBox(width: 6),
                    Text(
                      'Choose Existing Task For Today',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
