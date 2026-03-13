// =============================================================
// TodayPlanScreen — shows today's blocks in timeline
// Date header with prev/next day arrows, block list, generate plan
// Swipe-to-complete on block cards, completion celebration.
// =============================================================

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:focusflow_mobile/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/utils/date_utils.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'add_task_sheet.dart';
import 'activity_selector.dart';
import 'todo_tab.dart';
import 'buying_tab.dart';
import 'routines_tab.dart';
import 'flow_control_bar.dart';
import 'flow_activity_card.dart';
import 'package:focusflow_mobile/models/daily_flow.dart';
import 'package:focusflow_mobile/screens/session/session_screen.dart';
import 'study_flow_screen.dart';
import 'track_now_screen.dart';

class TodayPlanScreen extends StatefulWidget {
  const TodayPlanScreen({super.key});

  @override
  State<TodayPlanScreen> createState() => _TodayPlanScreenState();
}

class _TodayPlanScreenState extends State<TodayPlanScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  String? _completedBlockId; // triggers celebration
  late TabController _tabCtrl;

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // ── Prayer times — Vijayawada (block = leave 10 min before prayer → +20 min)
  // Format: (name, blockStartH, blockStartM, blockEndH, blockEndM, prayerH, prayerM)
  static const _prayers = [
    ('Fajr', 5, 35, 6, 5, 5, 45),
    ('Zuhr', 13, 20, 13, 50, 13, 30),
    ('Asr', 16, 50, 17, 20, 17, 0),
    ('Maghrib', 18, 20, 18, 50, 18, 30),
    ('Isha', 20, 5, 20, 35, 20, 15),
  ];

  static TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  List<Block> _buildPrayerBlocks() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _prayers.map((p) {
      final startH = p.$2;
      final startM = p.$3;
      final endH = p.$4;
      final endM = p.$5;
      final dur = (endH * 60 + endM) - (startH * 60 + startM);
      final start =
          '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}';
      final end =
          '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
      return Block(
        id: 'prayer_${p.$1.toLowerCase()}',
        index: 0,
        date: dateStr,
        plannedStartTime: start,
        plannedEndTime: end,
        type: BlockType.other,
        title: '${p.$1} 🕌',
        plannedDurationMinutes: dur,
        status: BlockStatus.done,
        isVirtual: true,
      );
    }).toList();
  }

  /// Schedule OS notifications for today's prayers (10 min before prayer).
  void _schedulePrayerNotifications() {
    if (!_isToday) return;
    NotificationService.instance.cancelAll();
    final now = DateTime.now();
    for (int i = 0; i < _prayers.length; i++) {
      final p = _prayers[i];
      // Notification fires at block start time (= prayer − 10 min)
      final notifTime = DateTime(
        now.year,
        now.month,
        now.day,
        p.$2,
        p.$3,
      );
      if (notifTime.isAfter(now)) {
        NotificationService.instance.scheduleAt(
          id: 1000 + i,
          title: '${p.$1} 🕌',
          body: 'Time to head to the mosque — ${p.$1} prayer in 10 minutes.',
          when: notifTime,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = AppDateUtils.getAdjustedDate();
    _tabCtrl = TabController(length: 4, vsync: this);
    // Schedule prayer notifications for today on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _schedulePrayerNotifications();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String get _dateKey => AppDateUtils.formatDate(_selectedDate);
  bool get _isToday =>
      AppDateUtils.isSameDay(_selectedDate, AppDateUtils.getAdjustedDate());

  void _prevDay() => _setStateIfMounted(() {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      });

  void _nextDay() => _setStateIfMounted(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      });

  void _openTrackNow() {
    final app = context.read<AppProvider>();
    final activeTrackNow = app.getActiveTrackNow(_dateKey);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrackNowScreen(
          dateKey: _dateKey,
          existingActivityId: activeTrackNow?.id,
        ),
      ),
    );
  }

  void _completeBlock(AppProvider app, DayPlan plan, Block block) {
    HapticsService.heavy();
    final blocks = List<Block>.from(plan.blocks ?? []);
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx >= 0) {
      blocks[idx] = blocks[idx].copyWith(
        status: BlockStatus.done,
        actualEndTime: DateTime.now().toIso8601String(),
      );
    }
    app.upsertDayPlan(plan.copyWith(blocks: blocks));

    // Update tracker & revision hub for each task in the block
    final tasks = block.tasks ?? [];
    for (final task in tasks) {
      app.completeStudyTask(task);
    }
    // Also handle block-level FA pages if no explicit tasks
    if (tasks.isEmpty && block.type == BlockType.revisionFa) {
      final pages = block.relatedFaPages ?? [];
      for (final p in pages) {
        app.updateFAPageStatus(p, 'read');
      }
    }

    // Trigger celebration
    _setStateIfMounted(() => _completedBlockId = block.id);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final sp = context.watch<SettingsProvider>();
    final DayPlan? plan =
        app.getDayPlan(DateFormat('yyyy-MM-dd').format(_selectedDate));
    final realBlocks = List<Block>.from(plan?.blocks ?? []);

    // Merge prayer blocks for today
    final List<Block> displayBlocks;
    if (_isToday) {
      displayBlocks = [...realBlocks, ..._buildPrayerBlocks()];
    } else {
      displayBlocks = List<Block>.from(realBlocks);
    }
    displayBlocks
        .sort((a, b) => a.plannedStartTime.compareTo(b.plannedStartTime));

    // Available time (from Settings)
    final wake = _parseTime(sp.wakeTime);
    final sleep = _parseTime(sp.sleepTime);
    final wakeMinutes = wake.hour * 60 + wake.minute;
    final sleepMinutes = sleep.hour * 60 + sleep.minute;
    final daySpan = sleepMinutes - wakeMinutes;
    const prayerMinutes = 150; // 5 prayers × 30 min
    final availableMinutes = daySpan - prayerMinutes;

    // Planned minutes (real blocks only)
    final plannedMinutes = realBlocks.fold<int>(
      0,
      (sum, b) => sum + b.plannedDurationMinutes,
    );
    final isOverflow = _isToday && plannedMinutes > availableMinutes;

    // Calculate streak for scaffold
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final d = now.subtract(Duration(days: i));
      final ds = DateFormat('yyyy-MM-dd').format(d);
      final hasLogs =
          app.timeLogs.any((l) => l.date == ds && l.durationMinutes > 0);
      if (hasLogs) {
        streak++;
      } else {
        if (i == 0) continue;
        break;
      }
    }

    final activeTrackNow = app.getActiveTrackNow(_dateKey);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // ── Active Track Now Banner (if running) ─────────────
                if (activeTrackNow != null && activeTrackNow.startedAt != null)
                  GestureDetector(
                    onTap: _openTrackNow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              color: Color(0xFFEF4444), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tracking: ${activeTrackNow.label}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                          const Icon(Icons.open_in_full_rounded,
                              color: Color(0xFFEF4444), size: 16),
                        ],
                      ),
                    ),
                  ),

                // ── NestedScrollView for scrollable header ───────────
                Expanded(
                  child: NestedScrollView(
                    headerSliverBuilder: (context, _) => [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            // ── Date navigation & Track Now button ───
                            _DateHeader(
                              date: _selectedDate,
                              isToday: _isToday,
                              streakCount: streak,
                              onPrev: _prevDay,
                              onNext: _nextDay,
                              onDateTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime(2027),
                                );
                                if (picked != null) {
                                  _setStateIfMounted(
                                    () => _selectedDate = picked,
                                  );
                                }
                              },
                              onTrackNow: _openTrackNow,
                            ),

                            // ── Activity Selector (all dates) ─────────
                            ActivitySelector(dateKey: _dateKey),
                          ],
                        ),
                      ),
                      // ── Tab bar (Pinned) ────────────────────────────
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          Container(
                            color: Theme.of(context).colorScheme.surface,
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TabBar(
                                controller: _tabCtrl,
                                labelStyle: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700),
                                unselectedLabelStyle: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500),
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                indicator: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                tabs: const [
                                  Tab(text: 'All', height: 36),
                                  Tab(text: 'To-Do', height: 36),
                                  Tab(text: 'Buying', height: 36),
                                  Tab(text: 'Routines', height: 36),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    body: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        // ═ ALL TAB ═ (existing block timeline)
                        _AllTabContent(
                          plan: plan,
                          realBlocks: realBlocks,
                          displayBlocks: displayBlocks,
                          plannedMinutes: plannedMinutes,
                          availableMinutes: availableMinutes,
                          isToday: _isToday,
                          isOverflow: isOverflow,
                          dateKey: _dateKey,
                          onCompleteBlock: (b) => _completeBlock(app, plan!, b),
                          onStartBlock: (b) => _startBlock(app, plan!, b),
                          onSkipBlock: (b) => _skipBlock(app, plan!, b),
                        ),

                        // ═ TO-DO TAB ═
                        TodoTab(dateKey: _dateKey),

                        // ═ BUYING TAB ═
                        BuyingTab(dateKey: _dateKey),

                        // ═ ROUTINES TAB ═
                        RoutinesTab(dateKey: _dateKey),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Celebration overlay ──────────────────────────────────
            if (_completedBlockId != null)
              _CelebrationOverlay(
                onComplete: () {
                  _setStateIfMounted(() => _completedBlockId = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _startBlock(AppProvider app, DayPlan plan, Block block) {
    HapticsService.medium();
    final now = DateTime.now().toIso8601String();
    final blocks = List<Block>.from(plan.blocks ?? []);

    // Pause any active block
    for (int i = 0; i < blocks.length; i++) {
      if (blocks[i].status == BlockStatus.inProgress &&
          blocks[i].id != block.id) {
        blocks[i] = blocks[i].copyWith(status: BlockStatus.paused);
      }
    }

    // Start this block
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx >= 0) {
      blocks[idx] = blocks[idx].copyWith(
        status: BlockStatus.inProgress,
        actualStartTime: blocks[idx].actualStartTime ?? now,
      );
    }

    final updatedPlan = plan.copyWith(blocks: blocks);
    app.upsertDayPlan(updatedPlan);

    // Navigate to the session screen
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SessionScreen(block: block, plan: updatedPlan),
        ),
      );
    }
  }

  void _skipBlock(AppProvider app, DayPlan plan, Block block) {
    HapticsService.medium();
    final blocks = List<Block>.from(plan.blocks ?? []);
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx >= 0) {
      blocks[idx] = blocks[idx].copyWith(status: BlockStatus.skipped);
    }
    app.upsertDayPlan(plan.copyWith(blocks: blocks));
  }
}

// ══════════════════════════════════════════════════════════════════
// ALL TAB CONTENT — Flow-based with segmented views
// ══════════════════════════════════════════════════════════════════

class _AllTabContent extends StatefulWidget {
  final DayPlan? plan;
  final List<Block> realBlocks;
  final List<Block> displayBlocks;
  final int plannedMinutes;
  final int availableMinutes;
  final bool isToday;
  final bool isOverflow;
  final String dateKey;
  final ValueChanged<Block> onCompleteBlock;
  final ValueChanged<Block> onStartBlock;
  final ValueChanged<Block> onSkipBlock;

  const _AllTabContent({
    required this.plan,
    required this.realBlocks,
    required this.displayBlocks,
    required this.plannedMinutes,
    required this.availableMinutes,
    required this.isToday,
    required this.isOverflow,
    required this.dateKey,
    required this.onCompleteBlock,
    required this.onStartBlock,
    required this.onSkipBlock,
  });

  @override
  State<_AllTabContent> createState() => _AllTabContentState();
}

class _AllTabContentState extends State<_AllTabContent>
    with AutomaticKeepAliveClientMixin {
  int _segmentIndex = 0;
  static const _segments = ['Full Day Plan', 'Resume', 'Upcoming', 'Completed'];

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final flow = app.getDailyFlow(widget.dateKey);
    final allActivities = app.getFlowActivitiesForDate(widget.dateKey);
    final flowView = flow?.copyWith(activities: allActivities);
    final resumeActivities =
        allActivities.where((a) => a.isActive || a.isPaused).toList();
    final upcomingActivities =
        allActivities.where((a) => a.isNotStarted).toList();
    final completedActivities =
        allActivities.where((a) => a.isDone || a.isSkipped).toList();

    // Also gather to-dos and buying items for the full day plan
    final todos = app.getTodoItemsForDate(widget.dateKey);
    final buyingItems = app.getBuyingItemsForDate(widget.dateKey);

    return Column(
      children: [
        // ── Flow control bar ────────────────────────────────────
        FlowControlBar(
          dateKey: widget.dateKey,
          flow: flowView,
          onAddTask: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AddTaskSheet(dateKey: widget.dateKey),
            );
          },
        ),

        // ── Segment selector ────────────────────────────────────
        Container(
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _segments.length,
            itemBuilder: (ctx, i) {
              final selected = _segmentIndex == i;
              // Count badges
              int? badge;
              if (i == 1) badge = resumeActivities.length;
              if (i == 2) badge = upcomingActivities.length;
              if (i == 3) badge = completedActivities.length;

              return Padding(
                padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
                child: GestureDetector(
                  onTap: () => _setStateIfMounted(() => _segmentIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary.withValues(alpha: 0.12)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: selected
                          ? Border.all(color: cs.primary.withValues(alpha: 0.3))
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _segments[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        if (badge != null && badge > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: selected
                                  ? cs.primary.withValues(alpha: 0.15)
                                  : cs.onSurface.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$badge',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? cs.primary
                                    : cs.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // ── Segment content ─────────────────────────────────────
        Expanded(
          child: _buildSegmentContent(
            context,
            app,
            allActivities,
            resumeActivities,
            upcomingActivities,
            completedActivities,
            todos,
            buyingItems,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentContent(
    BuildContext context,
    AppProvider app,
    List<FlowActivity> allActivities,
    List<FlowActivity> resumeActivities,
    List<FlowActivity> upcomingActivities,
    List<FlowActivity> completedActivities,
    List<dynamic> todos,
    List<dynamic> buyingItems,
  ) {
    final cs = Theme.of(context).colorScheme;

    switch (_segmentIndex) {
      case 0: // Full Day Plan — everything
        return _buildFullDayPlan(
          context,
          app,
          allActivities,
          todos,
          buyingItems,
        );
      case 1: // Resume — grouped by time of day
        if (resumeActivities.isEmpty) {
          return _emptySegment(
              cs, 'No active items', Icons.play_circle_outline_rounded);
        }
        return _buildGroupedList(context, app, resumeActivities, allActivities,
            showComplete: true, showUndo: false);
      case 2: // Upcoming — grouped by time of day
        if (upcomingActivities.isEmpty) {
          return _emptySegment(cs, 'Nothing upcoming', Icons.upcoming_rounded);
        }
        return _buildGroupedList(
            context, app, upcomingActivities, allActivities,
            showComplete: false, showUndo: false);
      case 3: // Completed
        if (completedActivities.isEmpty) {
          return _emptySegment(
              cs, 'Nothing completed yet', Icons.check_circle_outline_rounded);
        }
        return _buildCompletedTab(
            context, app, completedActivities, allActivities);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Grouped list by time-of-day (for Resume / Upcoming) ──────
  Widget _buildGroupedList(
    BuildContext context,
    AppProvider app,
    List<FlowActivity> activities,
    List<FlowActivity> allActivities, {
    required bool showComplete,
    required bool showUndo,
  }) {
    final cs = Theme.of(context).colorScheme;
    final entries = _timeOfDayEntries(_groupByTimeOfDay(activities));
    final activityIndexes = _activityIndexes(allActivities);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry.isHeader) {
          return _buildFlowGroupHeader(entry.title!, entry.icon!, cs);
        }
        final activity = entry.activity!;
        return Dismissible(
          key: ValueKey('dismiss-${activity.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
          onDismissed: (_) => _deleteFlowActivity(app, activity),
          child: FlowActivityCard(
            activity: activity,
            index: activityIndexes[activity.id] ?? 0,
            onTap: () => _showFlowTaskActionsSheet(context, app, activity),
            onComplete: showComplete && (activity.isActive || activity.isPaused)
                ? () => app.completeFlowActivity(widget.dateKey, activity.id)
                : null,
            onUndo: showUndo && activity.isDone
                ? () => app.undoFlowActivity(widget.dateKey, activity.id)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildFlowGroupHeader(
    String title,
    IconData icon,
    ColorScheme cs,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _activityIndexes(List<FlowActivity> activities) {
    return {
      for (int i = 0; i < activities.length; i++) activities[i].id: i,
    };
  }

  List<_FlowActivityListEntry> _timeOfDayEntries(
    Map<String, List<FlowActivity>> groups,
  ) {
    final entries = <_FlowActivityListEntry>[];
    for (final section in _timeOfDaySections) {
      final activities = groups[section.key] ?? const <FlowActivity>[];
      if (activities.isEmpty) {
        continue;
      }
      entries.add(_FlowActivityListEntry.header(section.title, section.icon));
      for (final activity in activities) {
        entries.add(_FlowActivityListEntry.activity(activity));
      }
    }
    return entries;
  }

  Map<String, List<FlowActivity>> _groupByTimeOfDay(
      List<FlowActivity> activities) {
    final morning = <FlowActivity>[];
    final afternoon = <FlowActivity>[];
    final evening = <FlowActivity>[];
    final night = <FlowActivity>[];

    for (final a in activities) {
      final timeStr = a.startedAt ?? a.completedAt;
      if (timeStr == null) {
        morning.add(a); // default if no time data
        continue;
      }
      final dt = DateTime.tryParse(timeStr);
      if (dt == null) {
        morning.add(a);
        continue;
      }
      final hour = dt.hour;
      if (hour >= 5 && hour < 12) {
        morning.add(a);
      } else if (hour >= 12 && hour < 17) {
        afternoon.add(a);
      } else if (hour >= 17 && hour < 21) {
        evening.add(a);
      } else {
        night.add(a);
      }
    }
    return {
      'morning': morning,
      'afternoon': afternoon,
      'evening': evening,
      'night': night
    };
  }

  // ── Edit Task Bottom Sheet ──────────────────────────────────────
  String? _dayPlanBackedBlockId(AppProvider app, FlowActivity activity) {
    const taskPrefix = 'task-';
    if (activity.id.startsWith(taskPrefix)) {
      final blockId = activity.id.substring(taskPrefix.length);
      if (blockId.isNotEmpty) {
        return blockId;
      }
    }

    final plan = app.getDayPlan(widget.dateKey);
    final blockIds =
        (plan?.blocks ?? const <Block>[]).map((block) => block.id).toSet();
    for (final linkedId in activity.linkedTaskIds) {
      if (blockIds.contains(linkedId)) {
        return linkedId;
      }
    }

    return null;
  }

  Future<void> _deleteFlowActivity(
      AppProvider app, FlowActivity activity) async {
    final blockId = _dayPlanBackedBlockId(app, activity);
    await app.removeFlowActivity(widget.dateKey, activity.id);
    if (blockId != null) {
      await app.removeBlockFromDayPlan(blockId, widget.dateKey);
    }
    _setStateIfMounted(() {});
  }

  DateTime _dateFromKey(String dateKey) {
    return DateTime.tryParse(dateKey) ?? DateTime.now();
  }

  DateTime? _tryParseIso(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  TimeOfDay? _tryParseHm(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatHm(TimeOfDay value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  DateTime? _plannedDateTimeFromBlockTime(Block block, String hhmm) {
    final time = _tryParseHm(hhmm);
    if (time == null) {
      return null;
    }
    return _combineDateAndTime(_dateFromKey(block.date), time);
  }

  List<StudyTask> _plannedStudySessionTasks(Block block) {
    final notes = block.reflectionNotes;
    if (notes == null || notes.isEmpty) {
      return const <StudyTask>[];
    }
    try {
      final decoded = jsonDecode(notes);
      if (decoded is! Map<String, dynamic>) {
        return const <StudyTask>[];
      }
      if (decoded['kind'] != 'planned_study_session') {
        return const <StudyTask>[];
      }
      return StudyTask.fromJsonList(decoded['tasks']);
    } catch (_) {
      return const <StudyTask>[];
    }
  }

  int _plannedStudySessionMinutes(Block block) {
    final tasks = _plannedStudySessionTasks(block);
    if (tasks.isNotEmpty) {
      return StudyTask.estimateQueueDurationMinutes(tasks);
    }

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
        // Fall back to block duration.
      }
    }

    return block.plannedDurationMinutes;
  }

  String _plannedStudySessionTitle(
      List<StudyTask> tasks, String fallbackTitle) {
    if (tasks.isEmpty) {
      return fallbackTitle;
    }

    final parts = <String>[];
    final faPages = tasks
        .where((task) => task.type == 'FA')
        .expand((task) => task.pageNumbers)
        .toList()
      ..sort();
    if (faPages.isNotEmpty) {
      if (faPages.length == 1) {
        parts.add('FA p.${faPages.first}');
      } else {
        parts.add('FA pp.${faPages.first}-${faPages.last}');
      }
    }
    if (tasks.any((task) => task.type == 'UWORLD')) {
      parts.add('UWorld');
    }
    if (tasks.any(
      (task) => task.type == 'SKETCHY_MICRO' || task.type == 'SKETCHY_PHARM',
    )) {
      parts.add('Sketchy');
    }
    if (tasks.any((task) => task.type == 'PATHOMA')) {
      parts.add('Pathoma');
    }
    if (parts.isEmpty) {
      return fallbackTitle;
    }
    return 'Study Session - ${parts.join(' + ')}';
  }

  String? _updatedPlannedStudySessionNotes(Block block, int queueMinutes) {
    final notes = block.reflectionNotes;
    if (notes == null || notes.isEmpty) {
      return notes;
    }

    try {
      final decoded = jsonDecode(notes);
      if (decoded is! Map<String, dynamic>) {
        return notes;
      }
      if (decoded['kind'] != 'planned_study_session') {
        return notes;
      }
      final updated = Map<String, dynamic>.from(decoded)
        ..['estimatedDurationMinutes'] = queueMinutes;
      return jsonEncode(updated);
    } catch (_) {
      return notes;
    }
  }

  DayPlan _buildDayPlanWithBlocks(
    AppProvider app,
    String dateKey,
    List<Block> blocks,
  ) {
    final sortedBlocks = List<Block>.from(blocks)
      ..sort((a, b) {
        final startCompare = a.plannedStartTime.compareTo(b.plannedStartTime);
        if (startCompare != 0) {
          return startCompare;
        }
        return a.index.compareTo(b.index);
      });
    final reindexedBlocks = List<Block>.generate(
      sortedBlocks.length,
      (index) => sortedBlocks[index].copyWith(index: index, date: dateKey),
    );
    final existingPlan = app.getDayPlan(dateKey);
    final totalStudyMinutes = reindexedBlocks
        .where((entry) => entry.type != BlockType.breakBlock)
        .fold<int>(0, (sum, entry) => sum + entry.plannedDurationMinutes);
    final totalBreakMinutes = reindexedBlocks
        .where((entry) => entry.type == BlockType.breakBlock)
        .fold<int>(0, (sum, entry) => sum + entry.plannedDurationMinutes);

    return existingPlan?.copyWith(
          blocks: reindexedBlocks,
          totalStudyMinutesPlanned: totalStudyMinutes,
          totalBreakMinutes: totalBreakMinutes,
        ) ??
        DayPlan(
          date: dateKey,
          faPages: const [],
          faPagesCount: 0,
          videos: const [],
          notesFromUser: '',
          notesFromAI: '',
          attachments: const [],
          breaks: const [],
          blocks: reindexedBlocks,
          totalStudyMinutesPlanned: totalStudyMinutes,
          totalBreakMinutes: totalBreakMinutes,
        );
  }

  Future<void> _persistUpdatedBlock(
    AppProvider app,
    Block updatedBlock, {
    required String sourceDateKey,
    required String targetDateKey,
  }) async {
    if (sourceDateKey == targetDateKey) {
      final currentBlocks = List<Block>.from(
          app.getDayPlan(sourceDateKey)?.blocks ?? const <Block>[]);
      final index =
          currentBlocks.indexWhere((block) => block.id == updatedBlock.id);
      if (index < 0) {
        return;
      }
      currentBlocks[index] = updatedBlock.copyWith(date: targetDateKey);
      await app.upsertDayPlan(
        _buildDayPlanWithBlocks(app, targetDateKey, currentBlocks),
      );
      await app.syncFlowActivitiesFromDayPlan(targetDateKey);
      return;
    }

    final sourceBlocks = List<Block>.from(
        app.getDayPlan(sourceDateKey)?.blocks ?? const <Block>[]);
    sourceBlocks.removeWhere((block) => block.id == updatedBlock.id);
    await app.upsertDayPlan(
      _buildDayPlanWithBlocks(app, sourceDateKey, sourceBlocks),
    );

    final targetBlocks = List<Block>.from(
        app.getDayPlan(targetDateKey)?.blocks ?? const <Block>[])
      ..add(updatedBlock.copyWith(date: targetDateKey));
    await app.upsertDayPlan(
      _buildDayPlanWithBlocks(app, targetDateKey, targetBlocks),
    );

    await app.syncFlowActivitiesFromDayPlan(sourceDateKey);
    await app.syncFlowActivitiesFromDayPlan(targetDateKey);
  }

  DateTime _activityBaseDate(FlowActivity activity, Block? block) {
    if (block != null) {
      return _dateFromKey(block.date);
    }
    return _flowActivityDate(activity);
  }

  TimeOfDay? _activityStartTime(FlowActivity activity, Block? block) {
    if (block != null) {
      return _tryParseHm(block.plannedStartTime);
    }
    final start = _tryParseIso(activity.startedAt);
    if (start == null) {
      return null;
    }
    return TimeOfDay(hour: start.hour, minute: start.minute);
  }

  TimeOfDay? _activityEndTime(FlowActivity activity, Block? block) {
    if (block != null) {
      return _tryParseHm(block.plannedEndTime);
    }
    final end = _tryParseIso(activity.completedAt);
    if (end == null) {
      return null;
    }
    return TimeOfDay(hour: end.hour, minute: end.minute);
  }

  DateTime _flowActivityDate(FlowActivity activity) {
    final dt = _tryParseIso(activity.startedAt) ??
        _tryParseIso(activity.completedAt) ??
        _dateFromKey(widget.dateKey);
    return DateTime(dt.year, dt.month, dt.day);
  }

  String? _updatedActivityTimestamp(
    String? current,
    DateTime targetDate,
    TimeOfDay? pickedTime,
  ) {
    final parsed = _tryParseIso(current);
    if (parsed == null && pickedTime == null) return current;
    final time = pickedTime ??
        TimeOfDay(hour: parsed?.hour ?? 0, minute: parsed?.minute ?? 0);
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      time.hour,
      time.minute,
    ).toIso8601String();
  }

  Future<void> _moveOrUpdateFlowActivity(
    AppProvider app,
    FlowActivity activity, {
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    final targetDate = date ?? _flowActivityDate(activity);
    final targetDateKey = DateFormat('yyyy-MM-dd').format(targetDate);
    final updated = activity.copyWith(
      startedAt:
          _updatedActivityTimestamp(activity.startedAt, targetDate, startTime),
      completedAt:
          _updatedActivityTimestamp(activity.completedAt, targetDate, endTime),
    );

    if (targetDateKey == widget.dateKey) {
      await app.updateFlowActivity(widget.dateKey, updated);
      return;
    }

    await app.removeFlowActivity(widget.dateKey, activity.id);
    await app.addFlowActivity(targetDateKey, updated);
  }

  Future<void> _moveOrUpdateBlockBackedActivity(
    AppProvider app,
    FlowActivity activity,
    Block block, {
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    final sourceDateKey = block.date;
    final targetDate = date ?? _dateFromKey(block.date);
    final targetDateKey = DateFormat('yyyy-MM-dd').format(targetDate);
    final baseDate =
        DateTime(targetDate.year, targetDate.month, targetDate.day);
    final currentStart = _plannedDateTimeFromBlockTime(
          block,
          block.plannedStartTime,
        ) ??
        _combineDateAndTime(
          baseDate,
          const TimeOfDay(hour: 9, minute: 0),
        );
    final currentEnd = _plannedDateTimeFromBlockTime(
          block,
          block.plannedEndTime,
        ) ??
        currentStart.add(
          Duration(minutes: max(block.plannedDurationMinutes, 15)),
        );

    var nextStart = date != null
        ? _combineDateAndTime(
            baseDate,
            TimeOfDay(hour: currentStart.hour, minute: currentStart.minute),
          )
        : currentStart;
    var nextEnd = date != null
        ? _combineDateAndTime(
            baseDate,
            TimeOfDay(hour: currentEnd.hour, minute: currentEnd.minute),
          )
        : currentEnd;

    var nextDurationMinutes = block.plannedDurationMinutes;
    var nextTitle = block.title;
    var nextNotes = block.reflectionNotes;

    if (block.type == BlockType.studySession) {
      final queueMinutes = max(_plannedStudySessionMinutes(block), 5);
      if (startTime != null) {
        nextStart = _combineDateAndTime(baseDate, startTime);
        nextEnd = nextStart.add(Duration(minutes: queueMinutes));
      } else if (endTime != null) {
        nextEnd = _combineDateAndTime(baseDate, endTime);
        nextStart = nextEnd.subtract(Duration(minutes: queueMinutes));
      } else if (date != null) {
        nextStart = _combineDateAndTime(
          baseDate,
          TimeOfDay(hour: currentStart.hour, minute: currentStart.minute),
        );
        nextEnd = nextStart.add(Duration(minutes: queueMinutes));
      }
      nextDurationMinutes = queueMinutes;
      final tasks = _plannedStudySessionTasks(block);
      nextTitle = _plannedStudySessionTitle(tasks, block.title);
      nextNotes = _updatedPlannedStudySessionNotes(block, queueMinutes);
    } else {
      if (startTime != null) {
        nextStart = _combineDateAndTime(baseDate, startTime);
      }
      if (endTime != null) {
        nextEnd = _combineDateAndTime(baseDate, endTime);
      }
      nextDurationMinutes = max(
        nextEnd.difference(nextStart).inMinutes,
        block.plannedDurationMinutes,
      );
    }

    final updatedBlock = block.copyWith(
      date: targetDateKey,
      plannedStartTime: _formatHm(
        TimeOfDay(hour: nextStart.hour, minute: nextStart.minute),
      ),
      plannedEndTime: _formatHm(
        TimeOfDay(hour: nextEnd.hour, minute: nextEnd.minute),
      ),
      plannedDurationMinutes: nextDurationMinutes,
      title: nextTitle,
      reflectionNotes: nextNotes,
    );

    await _persistUpdatedBlock(
      app,
      updatedBlock,
      sourceDateKey: sourceDateKey,
      targetDateKey: targetDateKey,
    );
  }

  Block? _blockForActivity(FlowActivity activity) {
    final candidateIds = <String>{};
    const taskPrefix = 'task-';
    if (activity.id.startsWith(taskPrefix)) {
      final blockId = activity.id.substring(taskPrefix.length);
      if (blockId.isNotEmpty) {
        candidateIds.add(blockId);
      }
    }
    candidateIds.addAll(activity.linkedTaskIds);

    for (final block in widget.realBlocks) {
      if (candidateIds.contains(block.id)) {
        return block;
      }
    }
    return null;
  }

  bool _isMeaningfulHm(String? value) {
    if (value == null || value.isEmpty || value == '00:00') return false;
    final parts = value.split(':');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return false;
    return hour != 0 || minute != 0;
  }

  bool _isMeaningfulDateTime(DateTime? value) {
    return value != null && (value.hour != 0 || value.minute != 0);
  }

  String _formatDisplayTime(DateTime value) {
    return DateFormat('h:mm a').format(value);
  }

  String _formatHmDisplay(String value) {
    final parts = value.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return _formatDisplayTime(DateTime(2000, 1, 1, hour, minute));
  }

  String? _plannedSubtitleForBlock(Block block) {
    if (!_isMeaningfulHm(block.plannedStartTime) ||
        !_isMeaningfulHm(block.plannedEndTime) ||
        block.plannedDurationMinutes <= 0) {
      return null;
    }

    return '${_formatHmDisplay(block.plannedStartTime)} → ${_formatHmDisplay(block.plannedEndTime)} • ${block.plannedDurationMinutes} min';
  }

  String? _actualSubtitleForActivity(FlowActivity activity) {
    final start = _tryParseIso(activity.startedAt);
    final end = _tryParseIso(activity.completedAt);
    final durationMinutes =
        activity.durationSeconds != null ? activity.durationSeconds! ~/ 60 : 0;

    if (!_isMeaningfulDateTime(start) ||
        !_isMeaningfulDateTime(end) ||
        durationMinutes <= 0) {
      return null;
    }

    return '${_formatDisplayTime(start!)} → ${_formatDisplayTime(end!)} • $durationMinutes min';
  }

  String? _fullDaySubtitleForActivity(FlowActivity activity) {
    final block = _blockForActivity(activity);
    if (block != null) {
      return _plannedSubtitleForBlock(block);
    }
    return _actualSubtitleForActivity(activity);
  }

  Widget _dismissibleBackground() {
    return Container(
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
    );
  }

  Future<void> _showFlowTaskActionsSheet(
    BuildContext context,
    AppProvider app,
    FlowActivity activity,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final block = _blockForActivity(activity);
    final initialDate = _activityBaseDate(activity, block);
    final initialStartTime = _activityStartTime(activity, block);
    final initialEndTime = _activityEndTime(activity, block);
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit_calendar_rounded),
                title: const Text('Edit Date'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2027),
                  );
                  if (picked != null) {
                    if (block != null) {
                      await _moveOrUpdateBlockBackedActivity(
                        app,
                        activity,
                        block,
                        date: picked,
                      );
                    } else {
                      await _moveOrUpdateFlowActivity(
                        app,
                        activity,
                        date: picked,
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Edit Start Time'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        initialStartTime ?? const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (picked != null) {
                    if (block != null) {
                      await _moveOrUpdateBlockBackedActivity(
                        app,
                        activity,
                        block,
                        startTime: picked,
                      );
                    } else {
                      await _moveOrUpdateFlowActivity(
                        app,
                        activity,
                        startTime: picked,
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule_send_rounded),
                title: const Text('Edit End Time'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        initialEndTime ?? const TimeOfDay(hour: 10, minute: 0),
                  );
                  if (picked != null) {
                    if (block != null) {
                      await _moveOrUpdateBlockBackedActivity(
                        app,
                        activity,
                        block,
                        endTime: picked,
                      );
                    } else {
                      await _moveOrUpdateFlowActivity(
                        app,
                        activity,
                        endTime: picked,
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                title: Text('Delete', style: TextStyle(color: cs.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _deleteFlowActivity(app, activity);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedTab(
    BuildContext context,
    AppProvider app,
    List<FlowActivity> completed,
    List<FlowActivity> allActivities,
  ) {
    final cs = Theme.of(context).colorScheme;
    final activityIndexes = _activityIndexes(allActivities);
    final morning = <FlowActivity>[];
    final afternoon = <FlowActivity>[];
    final evening = <FlowActivity>[];
    final night = <FlowActivity>[];
    int totalSeconds = 0;
    final categorySeconds = <String, int>{};
    for (final a in completed) {
      if (a.durationSeconds != null) {
        totalSeconds += a.durationSeconds!;
        final cat = a.category ?? 'Other';
        categorySeconds[cat] = (categorySeconds[cat] ?? 0) + a.durationSeconds!;
      }
      if (a.completedAt == null) {
        morning.add(a);
        continue;
      }
      final date = DateTime.tryParse(a.completedAt!);
      if (date == null) {
        morning.add(a);
        continue;
      }
      final hour = date.hour;
      if (hour >= 5 && hour < 12) {
        morning.add(a);
      } else if (hour >= 12 && hour < 17) {
        afternoon.add(a);
      } else if (hour >= 17 && hour < 21) {
        evening.add(a);
      } else {
        night.add(a);
      }
    }
    String fmtHrMin(int totalSec) {
      final h = totalSec ~/ 3600;
      final m = (totalSec % 3600) ~/ 60;
      if (h > 0) return '${h}h ${m}m';
      return '${m}m';
    }

    final entries = _timeOfDayEntries({
      'morning': morning,
      'afternoon': afternoon,
      'evening': evening,
      'night': night,
    })
      ..add(
        _FlowActivityListEntry.summary(
          totalSeconds: totalSeconds,
          categorySeconds: categorySeconds,
        ),
      );
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry.isHeader) {
          return _buildFlowGroupHeader(entry.title!, entry.icon!, cs);
        }
        if (entry.isSummary) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _buildCompletedSummaryCard(
              cs,
              fmtHrMin(entry.totalSeconds!),
              entry.categorySeconds!,
              fmtHrMin,
            ),
          );
        }
        final activity = entry.activity!;
        return FlowActivityCard(
          activity: activity,
          index: activityIndexes[activity.id] ?? 0,
          onUndo: () => app.undoFlowActivity(widget.dateKey, activity.id),
        );
      },
    );
  }

  Widget _buildCompletedSummaryCard(
    ColorScheme cs,
    String totalLabel,
    Map<String, int> categorySeconds,
    String Function(int totalSeconds) formatDuration,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.insights_rounded, size: 16, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Text(
                'Total Hours Today',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                totalLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          if (categorySeconds.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categorySeconds.entries.map((entry) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatDuration(entry.value),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullDayPlan(
    BuildContext context,
    AppProvider app,
    List<FlowActivity> allActivities,
    List<dynamic> todos,
    List<dynamic> buyingItems,
  ) {
    final cs = Theme.of(context).colorScheme;

    if (allActivities.isEmpty &&
        todos.isEmpty &&
        buyingItems.isEmpty &&
        widget.displayBlocks.isEmpty) {
      return _EmptyState(
          hasNoPlan: widget.plan == null, dateKey: widget.dateKey);
    }

    final items = <_FullDayItem>[];
    final pending =
        allActivities.where((a) => !a.isDone && !a.isSkipped).toList();
    final done = allActivities.where((a) => a.isDone || a.isSkipped).toList();

    for (int i = 0; i < pending.length; i++) {
      items.add(_FullDayItem(
        type: 'flow',
        flowActivity: pending[i],
        index: allActivities.indexOf(pending[i]),
      ));
    }

    for (final t in todos) {
      items.add(
        _FullDayItem(type: 'todo', todoTitle: t.title, todoDone: t.done),
      );
    }

    for (final b in buyingItems) {
      items.add(
        _FullDayItem(
          type: 'buying',
          buyingTitle: b.name,
          buyingDone: b.bought,
        ),
      );
    }

    for (int i = 0; i < done.length; i++) {
      items.add(_FullDayItem(
        type: 'flow',
        flowActivity: done[i],
        index: allActivities.indexOf(done[i]),
      ));
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      onReorder: (oldIdx, newIdx) {
        if (oldIdx < allActivities.length && newIdx <= allActivities.length) {
          app.reorderFlowActivities(widget.dateKey, oldIdx, newIdx);
        }
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (ctx, child) => Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(14),
            color: Colors.transparent,
            child: child,
          ),
          child: child,
        );
      },
      itemBuilder: (ctx, i) {
        final item = items[i];

        if (item.type == 'flow') {
          final activity = item.flowActivity!;
          return KeyedSubtree(
            key: ValueKey('flow-${activity.id}'),
            child: Dismissible(
              key: ValueKey('dismiss-${activity.id}'),
              direction: DismissDirection.endToStart,
              background: _dismissibleBackground(),
              onDismissed: (_) => _deleteFlowActivity(app, activity),
              child: _FullDayFlowCard(
                activity: activity,
                index: item.index ?? i,
                subtitle: _fullDaySubtitleForActivity(activity),
                onTap: () => _showFlowTaskActionsSheet(context, app, activity),
                onComplete: activity.isActive || activity.isPaused
                    ? () =>
                        app.completeFlowActivity(widget.dateKey, activity.id)
                    : null,
                onUndo: activity.isDone
                    ? () => app.undoFlowActivity(widget.dateKey, activity.id)
                    : null,
              ),
            ),
          );
        }

        if (item.type == 'todo') {
          return KeyedSubtree(
            key: ValueKey('todo-$i'),
            child: Card(
              margin: const EdgeInsets.only(bottom: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              child: ListTile(
                dense: true,
                leading: Icon(
                  item.todoDone == true
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: item.todoDone == true
                      ? const Color(0xFF10B981)
                      : cs.onSurface.withValues(alpha: 0.3),
                ),
                title: Text(item.todoTitle ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      decoration: item.todoDone == true
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.todoDone == true
                          ? cs.onSurface.withValues(alpha: 0.4)
                          : cs.onSurface,
                    )),
              ),
            ),
          );
        }

        if (item.type == 'buying') {
          return KeyedSubtree(
            key: ValueKey('buying-$i'),
            child: Card(
              margin: const EdgeInsets.only(bottom: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.shopping_cart_outlined,
                    size: 18,
                    color: item.buyingDone == true
                        ? const Color(0xFF10B981)
                        : cs.onSurface.withValues(alpha: 0.3)),
                title: Text(item.buyingTitle ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      decoration: item.buyingDone == true
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.buyingDone == true
                          ? cs.onSurface.withValues(alpha: 0.4)
                          : cs.onSurface,
                    )),
              ),
            ),
          );
        }

        return SizedBox.shrink(key: ValueKey('unknown-$i'));
      },
    );
  }

  Widget _emptySegment(ColorScheme cs, String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: cs.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          Text(msg,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.4),
              )),
        ],
      ),
    );
  }
}

class _FullDayFlowCard extends StatelessWidget {
  final FlowActivity activity;
  final int index;
  final String? subtitle;
  final VoidCallback? onComplete;
  final VoidCallback? onUndo;
  final VoidCallback? onTap;

  const _FullDayFlowCard({
    required this.activity,
    required this.index,
    this.subtitle,
    this.onComplete,
    this.onUndo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (activity.status) {
      case 'DONE':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Done';
      case 'IN_PROGRESS':
        statusColor = const Color(0xFF3B82F6);
        statusIcon = Icons.play_circle_filled_rounded;
        statusLabel = 'Active';
      case 'PAUSED':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.pause_circle_filled_rounded;
        statusLabel = 'Paused';
      case 'SKIPPED':
        statusColor = cs.onSurface.withValues(alpha: 0.3);
        statusIcon = Icons.skip_next_rounded;
        statusLabel = 'Skipped';
      default:
        statusColor = cs.onSurface.withValues(alpha: 0.25);
        statusIcon = Icons.circle_outlined;
        statusLabel = '';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: activity.isActive
            ? BorderSide(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                width: 1.5,
              )
            : BorderSide.none,
      ),
      color: activity.isDone
          ? const Color(0xFF10B981).withValues(alpha: 0.06)
          : activity.isActive
              ? const Color(0xFF3B82F6).withValues(alpha: 0.06)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: activity.isNotStarted
                      ? Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        )
                      : Icon(statusIcon, size: 20, color: statusColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(activity.icon,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            activity.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: activity.isDone
                                  ? cs.onSurface.withValues(alpha: 0.5)
                                  : cs.onSurface,
                              decoration: activity.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (activity.linkedTaskIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          '${activity.linkedTaskIds.length} task${activity.linkedTaskIds.length == 1 ? '' : 's'} linked',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.primary.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    if (activity.notes != null && activity.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            Icon(Icons.sticky_note_2_outlined,
                                size: 12,
                                color: cs.onSurface.withValues(alpha: 0.3)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                activity.notes!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (statusLabel.isNotEmpty && !activity.isNotStarted)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (activity.isDone && onUndo != null)
                IconButton(
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  color: cs.onSurface.withValues(alpha: 0.4),
                  tooltip: 'Undo',
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              if ((activity.isActive || activity.isPaused) &&
                  onComplete != null)
                IconButton(
                  onPressed: onComplete,
                  icon:
                      const Icon(Icons.check_circle_outline_rounded, size: 22),
                  color: const Color(0xFF10B981),
                  tooltip: 'Complete',
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullDayItem {
  final String type; // 'flow' | 'todo' | 'buying'
  final FlowActivity? flowActivity;
  final String? todoTitle;
  final bool? todoDone;
  final String? buyingTitle;
  final bool? buyingDone;
  final int? index;

  const _FullDayItem({
    required this.type,
    this.flowActivity,
    this.todoTitle,
    this.todoDone,
    this.buyingTitle,
    this.buyingDone,
    this.index,
  });
}

class _TimeOfDaySection {
  final String key;
  final String title;
  final IconData icon;

  const _TimeOfDaySection(this.key, this.title, this.icon);
}

class _FlowActivityListEntry {
  final String? title;
  final IconData? icon;
  final FlowActivity? activity;
  final int? totalSeconds;
  final Map<String, int>? categorySeconds;

  const _FlowActivityListEntry.header(this.title, this.icon)
      : activity = null,
        totalSeconds = null,
        categorySeconds = null;

  const _FlowActivityListEntry.activity(this.activity)
      : title = null,
        icon = null,
        totalSeconds = null,
        categorySeconds = null;

  const _FlowActivityListEntry.summary({
    required this.totalSeconds,
    required this.categorySeconds,
  })  : title = null,
        icon = null,
        activity = null;

  bool get isHeader => title != null;
  bool get isSummary => totalSeconds != null;
}

const _timeOfDaySections = <_TimeOfDaySection>[
  _TimeOfDaySection(
    'morning',
    'Morning (5 AM - 12 PM)',
    Icons.wb_twilight_rounded,
  ),
  _TimeOfDaySection(
    'afternoon',
    'Afternoon (12 PM - 5 PM)',
    Icons.wb_sunny_rounded,
  ),
  _TimeOfDaySection(
    'evening',
    'Evening (5 PM - 9 PM)',
    Icons.nights_stay_rounded,
  ),
  _TimeOfDaySection(
    'night',
    'Night (9 PM - 5 AM)',
    Icons.bedtime_rounded,
  ),
];

// ══════════════════════════════════════════════════════════════════
// CELEBRATION OVERLAY — burst of confetti-like particles
// ══════════════════════════════════════════════════════════════════

class _CelebrationOverlay extends StatefulWidget {
  final VoidCallback? onComplete;
  const _CelebrationOverlay({this.onComplete});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _rng = Random();
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
    _ctrl.forward();

    _particles = List.generate(
        24,
        (_) => _Particle(
              x: _rng.nextDouble(),
              y: _rng.nextDouble() * 0.3,
              vx: (_rng.nextDouble() - 0.5) * 0.6,
              vy: -0.5 - _rng.nextDouble() * 0.5,
              size: 4 + _rng.nextDouble() * 6,
              color: [
                const Color(0xFF6366F1),
                const Color(0xFF10B981),
                const Color(0xFFF59E0B),
                const Color(0xFFEF4444),
                const Color(0xFF8B5CF6),
                const Color(0xFF3B82F6),
              ][_rng.nextInt(6)],
            ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;

        return IgnorePointer(
          child: Stack(
            children: [
              // Center badge
              Center(
                child: AnimatedOpacity(
                  opacity: t < 0.7 ? 1.0 : 1.0 - ((t - 0.7) / 0.3),
                  duration: Duration.zero,
                  child: AnimatedScale(
                    scale: t < 0.2 ? t / 0.2 : 1.0,
                    duration: Duration.zero,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text('Block Complete! 🎉',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Particles
              ..._particles.map((p) {
                final px = p.x + p.vx * t;
                final py = p.y + p.vy * t + 0.5 * t * t; // gravity
                final opacity = (1.0 - t).clamp(0.0, 1.0);

                return Positioned(
                  left: px * MediaQuery.of(context).size.width,
                  top: py * MediaQuery.of(context).size.height + 200,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: p.size,
                      height: p.size,
                      decoration: BoxDecoration(
                        color: p.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _Particle {
  final double x, y, vx, vy, size;
  final Color color;
  const _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
  });
}

// ── Sliver Persistent Header Delegate ─────────────────────────
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._child);
  final Widget _child;

  @override
  double get minExtent => 44.0;
  @override
  double get maxExtent => 44.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

// ── Date header ─────────────────────────────────────────────────
class _DateHeader extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final int streakCount;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onDateTap;
  final VoidCallback onTrackNow;

  const _DateHeader({
    required this.date,
    required this.isToday,
    required this.streakCount,
    required this.onPrev,
    required this.onNext,
    required this.onDateTap,
    required this.onTrackNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrev,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onDateTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isToday ? 'Today' : DateFormat('EEEE').format(date),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isToday ? cs.primary : cs.onSurface,
                        ),
                      ),
                      if (streakCount > 0) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.local_fire_department_rounded,
                            size: 14, color: Colors.deepOrange),
                        const SizedBox(width: 2),
                        Text(
                          '$streakCount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    DateFormat('d MMMM yyyy').format(date),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: onNext,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
          // ── Track Now Button ────────────────────────────
          FilledButton.icon(
            onPressed: onTrackNow,
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('Track Now'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasNoPlan;
  final String dateKey;

  const _EmptyState({required this.hasNoPlan, required this.dateKey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final app = context.read<AppProvider>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasNoPlan
                  ? Icons.calendar_today_rounded
                  : Icons.check_circle_outline_rounded,
              size: 48,
              color: cs.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              hasNoPlan ? 'No plan for this day' : 'No blocks yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasNoPlan
                  ? 'Plan from your template or add activities'
                  : 'Add blocks to your plan',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
            if (hasNoPlan && app.defaultActivities.isNotEmpty) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => app.planFlowFromTemplate(dateKey),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Plan from Template'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
