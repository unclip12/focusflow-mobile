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
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'block_card.dart';
import 'add_task_sheet.dart';
import 'quick_study_sheet.dart';
import 'package:focusflow_mobile/screens/session/session_screen.dart';

class TodayPlanScreen extends StatefulWidget {
  const TodayPlanScreen({super.key});

  @override
  State<TodayPlanScreen> createState() => _TodayPlanScreenState();
}

class _TodayPlanScreenState extends State<TodayPlanScreen> {
  late DateTime _selectedDate;
  String? _completedBlockId; // triggers celebration

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
    // Schedule prayer notifications for today on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _schedulePrayerNotifications();
    });
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

    return AppScaffold(
      screenName: "Today's Plan",
      streakCount: streak,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddTaskSheet(dateKey: _dateKey),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Date navigation ─────────────────────────────────────
              _DateHeader(
                date: _selectedDate,
                isToday: _isToday,
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
              ),

              // ── Plan summary bar ────────────────────────────────────
              if (plan != null)
                _PlanSummaryBar(plan: plan, blocks: realBlocks),

              // ── Available time banner (today only) ──────────────────
              if (_isToday)
                _AvailableTimeBanner(
                  plannedMinutes: plannedMinutes,
                  availableMinutes: availableMinutes,
                ),

              // ── Overflow warning ────────────────────────────────────
              if (isOverflow)
                _OverflowWarning(
                  overflowMinutes: plannedMinutes - availableMinutes,
                ),

              // ── Quick Study button (today only) ────────────────────
              if (_isToday)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20)),
                          ),
                          builder: (_) => const QuickStudySheet(),
                        );
                      },
                      icon: const Icon(Icons.timer_rounded, size: 18),
                      label: const Text('Start Studying'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),

              // ── Block list or empty ─────────────────────────────────
              Expanded(
                child: displayBlocks.isEmpty
                    ? _EmptyState(
                        hasNoPlan: plan == null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: displayBlocks.length,
                        itemBuilder: (context, i) {
                          final b = displayBlocks[i];

                          // Prayer blocks → distinct card
                          if (b.isVirtual == true && b.id.startsWith('prayer_')) {
                            return _PrayerBlockCard(block: b);
                          }

                          final canSwipe =
                              b.status != BlockStatus.done &&
                              b.status != BlockStatus.skipped;

                          final card = BlockCard(
                            block: b,
                            dayPlan: plan!,
                            onStart: () => _startBlock(app, plan, b),
                            onSkip: () => _skipBlock(app, plan, b),
                          );

                          if (!canSwipe) return card;

                          return Dismissible(
                            key: ValueKey('dismiss-${b.id}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              _completeBlock(app, plan, b);
                              return false; // don't actually remove
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 22),
                                  SizedBox(width: 6),
                                  Text('Complete',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      )),
                                ],
                              ),
                            ),
                            child: card,
                          );
                        },
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

// ── Date header ─────────────────────────────────────────────────
class _DateHeader extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onDateTap;

  const _DateHeader({
    required this.date,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onDateTap,
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
        ],
      ),
    );
  }
}

// ── Plan summary bar ────────────────────────────────────────────
class _PlanSummaryBar extends StatelessWidget {
  final DayPlan plan;
  final List<Block> blocks;

  const _PlanSummaryBar({required this.plan, required this.blocks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final done = blocks.where((b) => b.status == BlockStatus.done).length;
    final total = blocks.length;
    final studyMins = plan.totalStudyMinutesPlanned;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryChip(
            icon: Icons.view_agenda_rounded,
            label: '$done/$total blocks',
            color: cs.primary,
          ),
          _SummaryChip(
            icon: Icons.schedule_rounded,
            label: '${(studyMins / 60).toStringAsFixed(1)}h planned',
            color: const Color(0xFF10B981),
          ),
          if (plan.faPagesCount > 0)
            _SummaryChip(
              icon: Icons.menu_book_rounded,
              label: '${plan.faPagesCount} pages',
              color: const Color(0xFF8B5CF6),
            ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasNoPlan;

  const _EmptyState({required this.hasNoPlan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                  ? 'Generate a plan to get started'
                  : 'Add blocks to your plan',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Prayer block card ───────────────────────────────────────────
class _PrayerBlockCard extends StatelessWidget {
  final Block block;
  const _PrayerBlockCard({required this.block});

  /// Format "HH:mm" → "h:mm AM/PM"
  static String _fmt24to12(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:${m.toString().padLeft(2, '0')} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final startStr = block.plannedStartTime;
    final endStr = block.plannedEndTime;
    final timeRange = endStr.isNotEmpty
        ? '${_fmt24to12(startStr)} – ${_fmt24to12(endStr)}'
        : _fmt24to12(startStr);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.nightlight_round, size: 22, color: cs.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeRange,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSecondaryContainer.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${block.plannedDurationMinutes} min',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSecondaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Available time banner ───────────────────────────────────────
class _AvailableTimeBanner extends StatelessWidget {
  final int plannedMinutes;
  final int availableMinutes;
  const _AvailableTimeBanner({
    required this.plannedMinutes,
    required this.availableMinutes,
  });

  String _fmt(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final available = availableMinutes;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 14,
              color: cs.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 6),
          Text(
            'Available today: ',
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          Text(
            _fmt(available),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurface),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('|',
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.25))),
          ),
          Text(
            'Planned: ',
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          Text(
            _fmt(plannedMinutes),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.primary),
          ),
        ],
      ),
    );
  }
}

// ── Overflow warning ────────────────────────────────────────────
class _OverflowWarning extends StatelessWidget {
  final int overflowMinutes;
  const _OverflowWarning({required this.overflowMinutes});

  String _fmt(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.12),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: Colors.deepOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Plan exceeds available time by ${_fmt(overflowMinutes)}. '
              'Consider removing some blocks.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
