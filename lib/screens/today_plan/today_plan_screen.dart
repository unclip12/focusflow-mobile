import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/routine.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/screens/session/session_screen.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'package:focusflow_mobile/services/notification_service.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/utils/date_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'add_task_sheet.dart';
import 'buying_tab.dart';
import 'day_session_screen.dart';
import 'routine_editor_sheet.dart';
import 'routines_tab.dart';
import 'study_flow_screen.dart';
import 'todo_tab.dart';
import 'track_now_screen.dart';
import 'wakeup_snooze_overlay.dart';
import 'package:focusflow_mobile/screens/today_plan/timeline_view.dart';

const Color _kTodayPlanBackground = Color(0xFF0D0D0D);
const Color _kTodayPlanSurface = Color(0xFF1C1C1E);
const Color _kTodayPlanAccent = Color(0xFFE8837A);
const Color _kTodayPlanMuted = Color(0xFF8E8E93);
const Color _kTodayPlanDivider = Color(0xFF3A3A3C);
const Color _kTodayPlanNightDot = Color(0xFF6CA6FF);

class TodayPlanScreen extends StatefulWidget {
  const TodayPlanScreen({super.key});

  @override
  State<TodayPlanScreen> createState() => _TodayPlanScreenState();
}

class _TodayPlanScreenState extends State<TodayPlanScreen>
    with SingleTickerProviderStateMixin {
  static const int _routinesTabIndex = 1;

  late DateTime _selectedDate;
  String? _completedBlockId;
  late TabController _tabCtrl;
  bool _didProcessExpiredRoutineQueue = false;

  // Live clock
  late final ValueNotifier<DateTime> _clockNotifier =
      ValueNotifier<DateTime>(DateTime.now());
  late final StreamSubscription<DateTime> _clockTimer;

  static const _prayers = [
    ('Fajr', 5, 35, 6, 5, 5, 45),
    ('Zuhr', 13, 20, 13, 50, 13, 30),
    ('Asr', 16, 50, 17, 20, 17, 0),
    ('Maghrib', 18, 20, 18, 50, 18, 30),
    ('Isha', 20, 5, 20, 35, 20, 15),
  ];

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  List<Block> _buildPrayerBlocks() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _prayers.map((p) {
      final startH = p.$2;
      final startM = p.$3;
      final endH = p.$4;
      final endM = p.$5;
      final duration = (endH * 60 + endM) - (startH * 60 + startM);

      return Block(
        id: 'prayer_${p.$1.toLowerCase()}',
        index: 0,
        date: dateStr,
        plannedStartTime:
            '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}',
        plannedEndTime:
            '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}',
        type: BlockType.other,
        title: '${p.$1} 🕌',
        plannedDurationMinutes: duration,
        isEvent: true,
        status: BlockStatus.done,
        isVirtual: true,
      );
    }).toList();
  }

  void _schedulePrayerNotifications() {
    if (!_isToday) return;

    for (int i = 0; i < _prayers.length; i++) {
      NotificationService.instance.cancel(1000 + i);
    }

    final now = DateTime.now();
    for (int i = 0; i < _prayers.length; i++) {
      final p = _prayers[i];
      final notifTime = DateTime(now.year, now.month, now.day, p.$2, p.$3);
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

  Future<void> _showRoutineEditorSheet(Routine routine) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RoutineEditorSheet(existing: routine),
    );
  }

  Future<void> _showExpiredRoutineDialogs() async {
    if (_didProcessExpiredRoutineQueue || !mounted) return;
    _didProcessExpiredRoutineQueue = true;
    await _processNextExpiredRoutineDialog(context.read<AppProvider>());
  }

  Future<void> _processNextExpiredRoutineDialog(AppProvider app) async {
    if (!mounted || !app.hasPendingExpiredRoutinePrompts) return;

    final routine = app.takeNextExpiredRoutinePrompt();
    if (routine == null) return;

    final endDate = DateTime.tryParse(routine.recurrenceEndDate ?? '');
    final formattedDate = endDate == null
        ? (routine.recurrenceEndDate ?? 'the selected date')
        : DateFormat('dd MMM yyyy').format(endDate);

    final shouldUpdate = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Routine schedule expired'),
            content: Text(
              '${routine.name} was scheduled until $formattedDate. Update it?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Dismiss'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Update'),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) return;

    if (shouldUpdate) {
      _tabCtrl.animateTo(_routinesTabIndex);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      await _showRoutineEditorSheet(routine);
      if (!mounted) return;
    }

    await _processNextExpiredRoutineDialog(app);
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = AppDateUtils.getAdjustedDate();
    _tabCtrl = TabController(length: 3, vsync: this);
    // Tick clock every minute
    _clockTimer =
        Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now())
            .listen((dt) => _clockNotifier.value = dt);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _schedulePrayerNotifications();
      _showExpiredRoutineDialogs();
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _clockNotifier.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  String get _dateKey => AppDateUtils.formatDate(_selectedDate);
  bool get _isToday =>
      AppDateUtils.isSameDay(_selectedDate, AppDateUtils.getAdjustedDate());

  void _prevDay() => _setStateIfMounted(
      () => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));

  void _nextDay() => _setStateIfMounted(
      () => _selectedDate = _selectedDate.add(const Duration(days: 1)));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
    );
    if (picked != null) _setStateIfMounted(() => _selectedDate = picked);
  }

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

  void _openStudyFlow() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyFlowScreen(dateKey: _dateKey),
      ),
    );
  }

  void _openAddTaskSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        dateKey: _dateKey,
        prefillCategory: null,
      ),
    );
  }

  void _showStartDayOverlay() {
    final app = context.read<AppProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WakeupSnoozeOverlay(
          dateKey: _dateKey,
          onStartDay: () {
            final navigator = Navigator.of(context);
            navigator.pop();
            app.startDaySession(_dateKey);
            app.rescheduleFromNow(_dateKey);
            final newSession = app.getActiveDaySession(_dateKey);
            if (newSession != null && mounted) {
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => DaySessionScreen(
                    dateKey: _dateKey,
                    session: newSession,
                  ),
                ),
              );
            }
          },
          onDismiss: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  // ignore: unused_element
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
    final tasks = block.tasks ?? [];
    for (final task in tasks) {
      app.completeStudyTask(task);
    }
    if (tasks.isEmpty && block.type == BlockType.revisionFa) {
      for (final page in block.relatedFaPages ?? []) {
        app.updateFAPageStatus(page, 'read');
      }
    }
    _setStateIfMounted(() => _completedBlockId = block.id);
  }

  // ignore: unused_element
  void _startBlock(AppProvider app, DayPlan plan, Block block) {
    HapticsService.medium();
    final now = DateTime.now().toIso8601String();
    final blocks = List<Block>.from(plan.blocks ?? []);
    for (int i = 0; i < blocks.length; i++) {
      if (blocks[i].status == BlockStatus.inProgress &&
          blocks[i].id != block.id) {
        blocks[i] = blocks[i].copyWith(status: BlockStatus.paused);
      }
    }
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx >= 0) {
      blocks[idx] = blocks[idx].copyWith(
        status: BlockStatus.inProgress,
        actualStartTime: blocks[idx].actualStartTime ?? now,
      );
    }
    final updatedPlan = plan.copyWith(blocks: blocks);
    app.upsertDayPlan(updatedPlan);
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SessionScreen(block: block, plan: updatedPlan),
        ),
      );
    }
  }

  // ignore: unused_element
  void _skipBlock(AppProvider app, DayPlan plan, Block block) {
    HapticsService.medium();
    final blocks = List<Block>.from(plan.blocks ?? []);
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx >= 0) {
      blocks[idx] = blocks[idx].copyWith(status: BlockStatus.skipped);
    }
    app.upsertDayPlan(plan.copyWith(blocks: blocks));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final plan = app.getDayPlan(DateFormat('yyyy-MM-dd').format(_selectedDate));
    final realBlocks = List<Block>.from(plan?.blocks ?? []);
    final totalBlocks = realBlocks.length;
    final completedBlocks =
        realBlocks.where((block) => block.status == BlockStatus.done).length;

    final List<Block> displayBlocks;
    if (_isToday) {
      displayBlocks = [...realBlocks, ..._buildPrayerBlocks()];
    } else {
      displayBlocks = List<Block>.from(realBlocks);
    }
    displayBlocks
        .sort((a, b) => a.plannedStartTime.compareTo(b.plannedStartTime));

    return Scaffold(
      extendBody: true,
      backgroundColor: _kTodayPlanBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                    // ── Compact Header ─────────────────────────
                    // ── Tab Bar ────────────────────────────────
                    _ThreeTabBar(controller: _tabCtrl),
                    // ── Tab Views ──────────────────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [
                          _TodayTimelineTab(
                            date: _selectedDate,
                            isToday: _isToday,
                            totalBlocks: totalBlocks,
                            completedBlocks: completedBlocks,
                            onPrev: _prevDay,
                            onNext: _nextDay,
                            onDateTap: _pickDate,
                            onStartDay: _showStartDayOverlay,
                            onStudySession: _openStudyFlow,
                            onTrackNow: _openTrackNow,
                            onAddTask: _openAddTaskSheet,
                            onSelectDate: (selected) =>
                                _setStateIfMounted(
                                  () => _selectedDate = selected,
                                ),
                            dateKey: _dateKey,
                            blocks: displayBlocks,
                          ),
                          RoutinesTab(dateKey: _dateKey),
                          _MoreTabView(dateKey: _dateKey),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_completedBlockId != null)
                  _CelebrationOverlay(
                    onComplete: () =>
                        _setStateIfMounted(() => _completedBlockId = null),
                  ),
          ],
        ),
      ),
    );
  }
}

// ── More Tab: inline Todo + Buying sub-tabs ────────────────────
class _TodayTimelineTab extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final int totalBlocks;
  final int completedBlocks;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onDateTap;
  final VoidCallback onStartDay;
  final VoidCallback onStudySession;
  final VoidCallback onTrackNow;
  final VoidCallback onAddTask;
  final ValueChanged<DateTime> onSelectDate;
  final String dateKey;
  final List<Block> blocks;

  const _TodayTimelineTab({
    required this.date,
    required this.isToday,
    required this.totalBlocks,
    required this.completedBlocks,
    required this.onPrev,
    required this.onNext,
    required this.onDateTap,
    required this.onStartDay,
    required this.onStudySession,
    required this.onTrackNow,
    required this.onAddTask,
    required this.onSelectDate,
    required this.dateKey,
    required this.blocks,
  });

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: _CompactHeader(
              date: date,
              isToday: isToday,
              totalBlocks: totalBlocks,
              completedBlocks: completedBlocks,
              onPrev: onPrev,
              onNext: onNext,
              onDateTap: onDateTap,
              onSelectDate: onSelectDate,
            ),
          ),
        ];
      },
      body: TimelineView(
        dateKey: dateKey,
        blocks: blocks,
        onAddTask: onAddTask,
      ),
    );
  }
}

class _MoreTabView extends StatefulWidget {
  final String dateKey;
  const _MoreTabView({required this.dateKey});

  @override
  State<_MoreTabView> createState() => _MoreTabViewState();
}

class _MoreTabViewState extends State<_MoreTabView>
    with SingleTickerProviderStateMixin {
  late TabController _subTabCtrl;

  @override
  void initState() {
    super.initState();
    _subTabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Sub-tab bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? DashboardColors.glassBorderDark
                    : DashboardColors.glassBorderLight,
                width: 0.5,
              ),
            ),
            child: TabBar(
              controller: _subTabCtrl,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              indicator: BoxDecoration(
                color: DashboardColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              tabs: const [
                Tab(text: 'To-Do'),
                Tab(text: 'Buying'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabCtrl,
            children: [
              TodoTab(dateKey: widget.dateKey),
              BuyingTab(dateKey: widget.dateKey),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Celebration Overlay ────────────────────────────────────────
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
      if (status == AnimationStatus.completed) widget.onComplete?.call();
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
                          )
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
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ..._particles.map((p) {
                final px = p.x + p.vx * t;
                final py = p.y + p.vy * t + 0.5 * t * t;
                final opacity = (1.0 - t).clamp(0.0, 1.0);
                return Positioned(
                  left: px * MediaQuery.of(context).size.width,
                  top: py * MediaQuery.of(context).size.height + 200,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: p.size,
                      height: p.size,
                      decoration:
                          BoxDecoration(color: p.color, shape: BoxShape.circle),
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
  const _Particle(
      {required this.x,
      required this.y,
      required this.vx,
      required this.vy,
      required this.size,
      required this.color});
}

// ── Compact Header ─────────────────────────────────────────────
class _CompactHeader extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final int totalBlocks;
  final int completedBlocks;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onDateTap;
  final ValueChanged<DateTime> onSelectDate;

  const _CompactHeader({
    required this.date,
    required this.isToday,
    required this.totalBlocks,
    required this.completedBlocks,
    required this.onPrev,
    required this.onNext,
    required this.onDateTap,
    required this.onSelectDate,
  });

  List<DateTime> _buildWeekDates() {
    final startOfWeek = date.subtract(Duration(days: date.weekday % 7));
    return List<DateTime>.generate(
      7,
      (index) => DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + index,
      ),
    );
  }

  bool _isNightRoutine(Block block) {
    final title = block.title.toLowerCase();
    return title.contains('night') ||
        title.contains('sleep') ||
        title.contains('wind down') ||
        title.contains('bed');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final weekDates = _buildWeekDates();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onDateTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1,
                        ),
                        children: [
                          TextSpan(
                            text: DateFormat('d MMMM ').format(date),
                            style: const TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: DateFormat('yyyy').format(date),
                            style: const TextStyle(color: _kTodayPlanAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 30,
                    color: _kTodayPlanAccent,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (final weekDate in weekDates)
                Expanded(
                  child: _WeekDayColumn(
                    date: weekDate,
                    isSelected: AppDateUtils.isSameDay(weekDate, date),
                    hasBlocks: (app.getDayPlan(
                                  DateFormat('yyyy-MM-dd').format(weekDate),
                                )?.blocks ??
                                const <Block>[])
                            .isNotEmpty,
                    hasNightRoutine: (app.getDayPlan(
                                  DateFormat('yyyy-MM-dd').format(weekDate),
                                )?.blocks ??
                                const <Block>[])
                            .any(_isNightRoutine),
                    onTap: () => onSelectDate(weekDate),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDayColumn extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool hasBlocks;
  final bool hasNightRoutine;
  final VoidCallback onTap;

  const _WeekDayColumn({
    required this.date,
    required this.isSelected,
    required this.hasBlocks,
    required this.hasNightRoutine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('EEE').format(date),
              style: const TextStyle(
                color: _kTodayPlanMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
              ),
              child: Text(
                DateFormat('d').format(date),
                style: TextStyle(
                  color: isSelected ? _kTodayPlanBackground : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasBlocks) const _WeekIndicatorDot(color: _kTodayPlanAccent),
                  if (hasBlocks && hasNightRoutine) const SizedBox(width: 4),
                  if (hasNightRoutine)
                    const _WeekIndicatorDot(color: _kTodayPlanNightDot),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekIndicatorDot extends StatelessWidget {
  final Color color;

  const _WeekIndicatorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _ThreeTabBar extends StatelessWidget {
  final TabController controller;
  const _ThreeTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: _kTodayPlanSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _kTodayPlanDivider,
            width: 1,
          ),
        ),
        child: TabBar(
          controller: controller,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: _kTodayPlanMuted,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          indicator: BoxDecoration(
            color: _kTodayPlanAccent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _kTodayPlanAccent.withValues(alpha: 0.28),
            ),
          ),
          tabs: const [
            Tab(text: 'Timeline'),
            Tab(text: 'Routines'),
            Tab(text: 'More'),
          ],
        ),
      ),
    );
  }
}


