// =============================================================
// TodayPlanScreen — shows today's blocks in timeline
// Date header with prev/next day arrows, block list, generate plan
// Swipe-to-complete on block cards, completion celebration.
// =============================================================

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

  // ── Prayer times — Vijayawada (block = leave 10 min before prayer → +20 min)
  // Format: (name, blockStartH, blockStartM, blockEndH, blockEndM, prayerH, prayerM)
  static const _prayers = [
    ('Fajr',     5, 35,  6,  5,  5, 45),
    ('Zuhr',    13, 20, 13, 50, 13, 30),
    ('Asr',     16, 50, 17, 20, 17,  0),
    ('Maghrib', 18, 20, 18, 50, 18, 30),
    ('Isha',    20,  5, 20, 35, 20, 15),
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
      final start = '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}';
      final end = '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
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
        now.year, now.month, now.day, p.$2, p.$3,
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
  bool get _isToday => AppDateUtils.isSameDay(_selectedDate, AppDateUtils.getAdjustedDate());

  void _prevDay() => setState(() {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      });

  void _nextDay() => setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      });

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
    setState(() => _completedBlockId = block.id);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final sp = context.watch<SettingsProvider>();
    final DayPlan? plan = app.getDayPlan(DateFormat('yyyy-MM-dd').format(_selectedDate));
    final realBlocks = List<Block>.from(plan?.blocks ?? []);

    // Merge prayer blocks for today
    final List<Block> displayBlocks;
    if (_isToday) {
      displayBlocks = [...realBlocks, ..._buildPrayerBlocks()];
    } else {
      displayBlocks = List<Block>.from(realBlocks);
    }
    displayBlocks.sort((a, b) => a.plannedStartTime.compareTo(b.plannedStartTime));

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
      0, (sum, b) => sum + b.plannedDurationMinutes,
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
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TrackNowScreen(
                            dateKey: _dateKey,
                            existingActivityId: activeTrackNow.id,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Color(0xFFEF4444), size: 18),
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
                          const Icon(Icons.open_in_full_rounded, color: Color(0xFFEF4444), size: 16),
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
                                if (picked != null) setState(() => _selectedDate = picked);
                              },
                              onTrackNow: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TrackNowScreen(dateKey: _dateKey),
                                  ),
                                );
                              },
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
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TabBar(
                                controller: _tabCtrl,
                                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                indicator: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
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
                  if (mounted) setState(() => _completedBlockId = null);
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

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final flow = app.getDailyFlow(widget.dateKey);

    final allActivities = flow?.activities ?? [];
    final resumeActivities = allActivities
        .where((a) => a.isActive || a.isPaused)
        .toList();
    final upcomingActivities = allActivities
        .where((a) => a.isNotStarted)
        .toList();
    final completedActivities = allActivities
        .where((a) => a.isDone || a.isSkipped)
        .toList();

    // Also gather to-dos and buying items for the full day plan
    final todos = app.getTodoItemsForDate(widget.dateKey);
    final buyingItems = app.getBuyingItemsForDate(widget.dateKey);

    return Column(
      children: [
        // ── Flow control bar ────────────────────────────────────
        FlowControlBar(
          dateKey: widget.dateKey,
          flow: flow,
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
                  onTap: () => setState(() => _segmentIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary.withValues(alpha: 0.12)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: selected
                          ? Border.all(
                              color: cs.primary.withValues(alpha: 0.3))
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
            context, app, flow, allActivities,
            resumeActivities, upcomingActivities, completedActivities,
            todos, buyingItems,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentContent(
    BuildContext context,
    AppProvider app,
    DailyFlow? flow,
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
          context, app, flow, allActivities, todos, buyingItems,
        );
      case 1: // Resume — grouped by time of day
        if (resumeActivities.isEmpty) {
          return _emptySegment(cs, 'No active items', Icons.play_circle_outline_rounded);
        }
        return _buildGroupedList(context, app, resumeActivities, allActivities,
          showComplete: true, showUndo: false);
      case 2: // Upcoming — grouped by time of day
        if (upcomingActivities.isEmpty) {
          return _emptySegment(cs, 'Nothing upcoming', Icons.upcoming_rounded);
        }
        return _buildGroupedList(context, app, upcomingActivities, allActivities,
          showComplete: false, showUndo: false);
      case 3: // Completed
        if (completedActivities.isEmpty) {
          return _emptySegment(cs, 'Nothing completed yet', Icons.check_circle_outline_rounded);
        }
        return _buildCompletedTab(context, app, completedActivities, allActivities);
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
    final groups = _groupByTimeOfDay(activities);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _timeGroup('Morning (5 AM – 12 PM)', Icons.wb_twilight_rounded,
            groups['morning']!, allActivities, app, cs, showComplete, showUndo),
        _timeGroup('Afternoon (12 PM – 5 PM)', Icons.wb_sunny_rounded,
            groups['afternoon']!, allActivities, app, cs, showComplete, showUndo),
        _timeGroup('Evening (5 PM – 9 PM)', Icons.nights_stay_rounded,
            groups['evening']!, allActivities, app, cs, showComplete, showUndo),
        _timeGroup('Night (9 PM – 5 AM)', Icons.bedtime_rounded,
            groups['night']!, allActivities, app, cs, showComplete, showUndo),
      ],
    );
  }

  Widget _timeGroup(
    String title,
    IconData icon,
    List<FlowActivity> activities,
    List<FlowActivity> allActivities,
    AppProvider app,
    ColorScheme cs,
    bool showComplete,
    bool showUndo,
  ) {
    if (activities.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
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
        ),
        ...activities.map((a) => Dismissible(
          key: ValueKey('dismiss-${a.id}'),
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
          onDismissed: (_) => app.removeFlowActivity(widget.dateKey, a.id),
          child: FlowActivityCard(
            activity: a,
            index: allActivities.indexOf(a),
            onTap: () => _showEditTaskSheet(context, app, a),
            onComplete: showComplete && (a.isActive || a.isPaused)
                ? () => app.completeFlowActivity(widget.dateKey, a.id)
                : null,
            onUndo: showUndo && a.isDone
                ? () => app.undoFlowActivity(widget.dateKey, a.id)
                : null,
          ),
        )),
      ],
    );
  }

  Map<String, List<FlowActivity>> _groupByTimeOfDay(List<FlowActivity> activities) {
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
    return {'morning': morning, 'afternoon': afternoon, 'evening': evening, 'night': night};
  }

  // ── Edit Task Bottom Sheet ──────────────────────────────────────
  void _showEditTaskSheet(BuildContext context, AppProvider app, FlowActivity activity) {
    final nameCtrl = TextEditingController(text: activity.label);
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Edit Task', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 16),

              // Name field
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  prefixIcon: const Icon(Icons.edit_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Status info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Status: ${activity.status} • '
                        'Type: ${activity.activityType}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  // Delete button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        app.removeFlowActivity(widget.dateKey, activity.id);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                        side: BorderSide(color: cs.error.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Save button
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final newName = nameCtrl.text.trim();
                        if (newName.isNotEmpty && newName != activity.label) {
                          app.updateFlowActivity(
                            widget.dateKey,
                            activity.copyWith(label: newName),
                          );
                        }
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Save'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Completed Tab (Grouped by Time of Day) ──────────────────────────
  Widget _buildCompletedTab(
    BuildContext context,
    AppProvider app,
    List<FlowActivity> completed,
    List<FlowActivity> allActivities,
  ) {
    final cs = Theme.of(context).colorScheme;

    // Groups
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
        morning.add(a); // fallback
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

    Widget buildGroup(String title, IconData icon, List<FlowActivity> activities) {
      if (activities.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
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
          ),
          ...activities.map((a) => FlowActivityCard(
            activity: a,
            index: allActivities.indexOf(a),
            onUndo: () => app.undoFlowActivity(widget.dateKey, a.id),
          )),
        ],
      );
    }

    String fmtHrMin(int totalSec) {
      final h = totalSec ~/ 3600;
      final m = (totalSec % 3600) ~/ 60;
      if (h > 0) return '${h}h ${m}m';
      return '${m}m';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        buildGroup('Morning (5 AM - 12 PM)', Icons.wb_twilight_rounded, morning),
        buildGroup('Afternoon (12 PM - 5 PM)', Icons.wb_sunny_rounded, afternoon),
        buildGroup('Evening (5 PM - 9 PM)', Icons.nights_stay_rounded, evening),
        buildGroup('Night (9 PM - 5 AM)', Icons.bedtime_rounded, night),

        const SizedBox(height: 24),
        // Total Summary Card
        Container(
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
                    child: Icon(Icons.insights_rounded, size: 16, color: cs.primary),
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
                    fmtHrMin(totalSeconds),
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
                  children: categorySeconds.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            fmtHrMin(e.value),
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
        ),
      ],
    );
  }

  Widget _buildFullDayPlan(
    BuildContext context,
    AppProvider app,
    DailyFlow? flow,
    List<FlowActivity> allActivities,
    List<dynamic> todos,
    List<dynamic> buyingItems,
  ) {
    final cs = Theme.of(context).colorScheme;

    if (allActivities.isEmpty && todos.isEmpty && buyingItems.isEmpty &&
        widget.displayBlocks.isEmpty) {
      return _EmptyState(hasNoPlan: widget.plan == null, dateKey: widget.dateKey);
    }

    // Build unified list items — pending first, completed at bottom
    final items = <_FullDayItem>[];
    final pending = allActivities.where((a) => !a.isDone && !a.isSkipped).toList();
    final done = allActivities.where((a) => a.isDone || a.isSkipped).toList();

    // Pending flow activities first
    for (int i = 0; i < pending.length; i++) {
      items.add(_FullDayItem(type: 'flow', flowActivity: pending[i], index: allActivities.indexOf(pending[i])));
    }

    // Add activity button (only if flow exists)
    if (allActivities.isNotEmpty) {
      items.add(const _FullDayItem(type: 'addButton'));
    }

    // Study blocks (non-flow, existing blocks)
    for (final b in widget.realBlocks) {
      items.add(_FullDayItem(type: 'block', block: b));
    }

    // To-dos
    for (final t in todos) {
      items.add(_FullDayItem(type: 'todo', todoTitle: t.title, todoDone: t.done));
    }

    // Buying items
    for (final b in buyingItems) {
      items.add(_FullDayItem(type: 'buying', buyingTitle: b.name, buyingDone: b.bought));
    }

    // Completed flow activities at the bottom
    for (int i = 0; i < done.length; i++) {
      items.add(_FullDayItem(type: 'flow', flowActivity: done[i], index: allActivities.indexOf(done[i])));
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      onReorder: (oldIdx, newIdx) {
        // Only reorder flow activities
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
          return KeyedSubtree(
            key: ValueKey('flow-${item.flowActivity!.id}'),
            child: Dismissible(
              key: ValueKey('dismiss-${item.flowActivity!.id}'),
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
              onDismissed: (_) => app.removeFlowActivity(widget.dateKey, item.flowActivity!.id),
              child: FlowActivityCard(
                activity: item.flowActivity!,
                index: item.index ?? i,
                onComplete: item.flowActivity!.isActive || item.flowActivity!.isPaused
                    ? () => app.completeFlowActivity(widget.dateKey, item.flowActivity!.id)
                    : null,
                onUndo: item.flowActivity!.isDone
                    ? () => app.undoFlowActivity(widget.dateKey, item.flowActivity!.id)
                    : null,
              ),
            ),
          );
        }

        if (item.type == 'block') {
          final b = item.block!;
          return KeyedSubtree(
            key: ValueKey('block-${b.id}'),
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.book_rounded, size: 20,
                    color: cs.primary.withValues(alpha: 0.6)),
                title: Text(b.title.isNotEmpty ? b.title : 'Study Block',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${b.plannedStartTime} – ${b.plannedEndTime} • ${b.plannedDurationMinutes}m',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
                trailing: b.status == BlockStatus.done
                    ? const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF10B981))
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              child: ListTile(
                dense: true,
                leading: Icon(
                  item.todoDone == true ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: item.todoDone == true ? const Color(0xFF10B981) : cs.onSurface.withValues(alpha: 0.3),
                ),
                title: Text(item.todoTitle ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      decoration: item.todoDone == true ? TextDecoration.lineThrough : null,
                      color: item.todoDone == true ? cs.onSurface.withValues(alpha: 0.4) : cs.onSurface,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.shopping_cart_outlined, size: 18,
                    color: item.buyingDone == true ? const Color(0xFF10B981) : cs.onSurface.withValues(alpha: 0.3)),
                title: Text(item.buyingTitle ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      decoration: item.buyingDone == true ? TextDecoration.lineThrough : null,
                      color: item.buyingDone == true ? cs.onSurface.withValues(alpha: 0.4) : cs.onSurface,
                    )),
              ),
            ),
          );
        }

        if (item.type == 'addButton') {
          return KeyedSubtree(
            key: const ValueKey('add-activity-btn'),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => _showAddActivityDialog(context, app),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 18, color: cs.primary.withValues(alpha: 0.5)),
                        const SizedBox(width: 6),
                        Text(
                          'Add Activity',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.primary.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return SizedBox.shrink(key: ValueKey('unknown-$i'));
      },
    );
  }

  void _showAddActivityDialog(BuildContext context, AppProvider app) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Activity'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Activity name...',
            filled: true,
            fillColor: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              app.addFlowActivity(
                widget.dateKey,
                FlowActivity(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  label: name,
                  icon: '⚡',
                  activityType: 'CUSTOM',
                  sortOrder: 999,
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
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

class _FullDayItem {
  final String type; // 'flow' | 'block' | 'todo' | 'buying' | 'addButton'
  final FlowActivity? flowActivity;
  final Block? block;
  final String? todoTitle;
  final bool? todoDone;
  final String? buyingTitle;
  final bool? buyingDone;
  final int? index;

  const _FullDayItem({
    required this.type,
    this.flowActivity,
    this.block,
    this.todoTitle,
    this.todoDone,
    this.buyingTitle,
    this.buyingDone,
    this.index,
  });
}

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

    _particles = List.generate(24, (_) => _Particle(
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
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.size, required this.color,
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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
                        isToday
                            ? 'Today'
                            : DateFormat('EEEE').format(date),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isToday ? cs.primary : cs.onSurface,
                        ),
                      ),
                      if (streakCount > 0) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.deepOrange),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
