import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/daily_flow.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'package:focusflow_mobile/services/notification_service.dart';
import 'package:focusflow_mobile/services/background_timer_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:focusflow_mobile/screens/today_plan/add_task_sheet.dart';

// ── Category data ──────────────────────────────────────────────
class _Category {
  final String name;
  final String emoji;
  final Color color;
  const _Category(this.name, this.emoji, this.color);
}

const _categories = [
  _Category('Cooking',  '🍳', Color(0xFFEF4444)),
  _Category('Cleaning', '🧹', Color(0xFF10B981)),
  _Category('Exercise', '💪', Color(0xFF3B82F6)),
  _Category('Study',    '📚', Color(0xFF8B5CF6)),
  _Category('Prayer',   '🕌', Color(0xFF059669)),
  _Category('Shopping', '🛒', Color(0xFFF59E0B)),
  _Category('Eating',   '🍽️', Color(0xFFEC4899)),
  _Category('Rest',     '😴', Color(0xFF6366F1)),
  _Category('Travel',   '🚗', Color(0xFF14B8A6)),
  _Category('Work',     '💼', Color(0xFF0EA5E9)),
  _Category('Other',    '⏱️', Color(0xFF64748B)),
];

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
  String? _selectedCategory;
  bool _isTracking = false;
  String? _trackingActivityId;
  DateTime? _startedAt;

  // Selected existing task to link to
  String? _selectedTaskId;
  String? _selectedTaskTitle;

  // Timer state
  int _elapsed = 0;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // If resuming an existing activity
    if (widget.existingActivityId != null) {
      final app = context.read<AppProvider>();
      final activity = _findActivity(app);
      if (activity != null) {
        _nameCtrl.text = activity.label;
        _selectedCategory = activity.category;
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

  FlowActivity? _findActivity(AppProvider app) {
    final flow = app.getDailyFlow(widget.dateKey);
    if (flow == null) return null;
    try {
      return flow.activities.firstWhere(
        (a) => a.id == widget.existingActivityId,
      );
    } catch (_) {
      return null;
    }
  }

  void _startTimer() {
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
    
    // Start background timer
    final name = _selectedTaskTitle ?? _nameCtrl.text.trim();
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
      // Recompute elapsed from startedAt when app resumes from background
      setState(() {
        _elapsed = DateTime.now().difference(_startedAt!).inSeconds;
      });
      // Re-sync background service time in case it drifted
      final name = _selectedTaskTitle ?? _nameCtrl.text.trim();
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

  // ── Actions ──────────────────────────────────────────────────

  Future<void> _startTracking() async {
    final name = _selectedTaskTitle ?? _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select what you are doing')),
      );
      return;
    }

    HapticsService.medium();
    final app = context.read<AppProvider>();
    final activity = await app.startTrackNow(
      widget.dateKey,
      label: name,
      category: _selectedCategory,
    );
    
    // Link to the selected task immediately upon start if applicable
    if (_selectedTaskId != null) {
      await app.updateFlowActivity(
        widget.dateKey, 
        activity.copyWith(linkedTaskIds: [_selectedTaskId!])
      );
    }

    setState(() {
      _isTracking = true;
      _trackingActivityId = activity.id;
      _startedAt = DateTime.now();
      _elapsed = 0;
    });
    _startTimer();
  }

  Future<void> _stopTracking() async {
    if (_trackingActivityId == null) return;

    HapticsService.heavy();
    final app = context.read<AppProvider>();
    final name = _selectedTaskTitle ?? _nameCtrl.text.trim();
    await app.stopTrackNow(
      widget.dateKey,
      _trackingActivityId!,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      linkedTaskIds: _selectedTaskId != null ? [_selectedTaskId!] : null,
    );

    _tickTimer?.cancel();
    BackgroundTimerService.stop();

    // Fire notification: session complete
    unawaited(NotificationService.instance.showFocusTimerDone(
      activityName: name.isNotEmpty ? name : 'Activity',
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
                  // Add task button (only while tracking)
                  if (_isTracking)
                    IconButton(
                      icon: Icon(Icons.add_rounded, color: cs.primary),
                      onPressed: _openAddTask,
                      tooltip: 'Add Task',
                    )
                  else
                    const SizedBox(width: 48),
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
              child: SizedBox(
                width: double.infinity,
                child: _isTracking
                    ? FilledButton.icon(
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
                      )
                    : FilledButton.icon(
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
          // Title
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

          // Activity Query / Inline Selection
          _buildExistingTasksList(theme, cs),

          const SizedBox(height: 24),
          
          if (_selectedTaskId == null) ...[
            // Activity name (Custom Input)
            Text('Or enter custom activity:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.7),
                )),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              autofocus: _selectedTaskId == null,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (val) {
                if (val.isNotEmpty && _selectedTaskId != null) {
                  setState(() {
                    _selectedTaskId = null;
                    _selectedTaskTitle = null;
                  });
                }
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
            const SizedBox(height: 24),

            // Category selector (only for manual)
            Text('Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.7),
                )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final selected = _selectedCategory == c.name;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory =
                      _selectedCategory == c.name ? null : c.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? c.color.withValues(alpha: 0.15)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? c.color.withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? c.color
                                : cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
             // Notice when existing task is selected
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
          ],
        ],
      ),
    );
  }

  Widget _buildExistingTasksList(ThemeData theme, ColorScheme cs) {
    final app = context.watch<AppProvider>();
    final flow = app.getDailyFlow(widget.dateKey);
    final dayPlan = app.getDayPlan(widget.dateKey);

    final linkableItems = <Map<String, dynamic>>[];

    // Add today's flow activities that are not already track now
    if (flow != null) {
      for (final a in flow.activities) {
        if (a.activityType == 'TRACK_NOW') continue;
        linkableItems.add({
          'id': a.id,
          'title': a.label,
          'subtitle': 'Today\'s Flow',
          'icon': Icons.list_alt_rounded,
          'color': cs.tertiary,
        });
      }
    }

    // Add today's plan blocks
    if (dayPlan != null) {
      final blocks = dayPlan.blocks ?? [];
      final linkedBlockIds = flow?.activities
          .expand((a) => a.linkedTaskIds)
          .toSet() ?? {};
          
      for (final b in blocks) {
        if (b.type == BlockType.breakBlock || b.isVirtual == true) continue;
        if (linkedBlockIds.contains(b.id)) continue;
        linkableItems.add({
          'id': b.id,
          'title': b.title,
          'subtitle': 'Today\'s Plan',
          'icon': Icons.calendar_today_rounded,
          'color': const Color(0xFF6366F1),
        });
      }
    }

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
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTaskId = null;
                      _selectedTaskTitle = null;
                    } else {
                      _selectedTaskId = item['id'];
                      _selectedTaskTitle = item['title'];
                      _nameCtrl.clear();
                      _selectedCategory = null;
                    }
                  });
                  HapticsService.light();
                },
                leading: Icon(
                  item['icon'],
                  color: item['color'],
                  size: 20,
                ),
                title: Text(
                  item['title'],
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item['subtitle'],
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
    final categoryData = _categories.firstWhere(
      (c) => c.name == _selectedCategory,
      orElse: () => _categories.last,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Category icon + name
          Text(
            categoryData.emoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            _nameCtrl.text,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (_selectedCategory != null) ...[
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: categoryData.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _selectedCategory!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: categoryData.color,
                ),
              ),
            ),
          ],

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

          // Add task button row
          Material(
            color: cs.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _openAddTask,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded,
                        size: 18, color: cs.primary.withValues(alpha: 0.6)),
                    const SizedBox(width: 6),
                    Text(
                      'Add Task (FA Page, UWorld, etc.)',
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
