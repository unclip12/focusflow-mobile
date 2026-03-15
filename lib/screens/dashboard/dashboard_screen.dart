import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/models/knowledge_base.dart';
import 'package:focusflow_mobile/models/revision_item.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/utils/date_utils.dart' as du;
import 'package:focusflow_mobile/widgets/animated_counter.dart';
import 'package:focusflow_mobile/widgets/animated_progress_bar.dart';
import 'package:focusflow_mobile/widgets/aurora_background.dart';
import 'package:focusflow_mobile/widgets/liquid_glass_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loaded = context.select<AppProvider, bool>((p) => p.loaded);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget content = loaded
        ? const _DashboardBody()
        : _DashboardLoadingScreen(isDark: isDark);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit FocusFlow?'),
            content: const Text('Are you sure you want to exit?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: content,
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final sp = context.watch<SettingsProvider>();
    final isDark = sp.isDarkMode;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayStartHour = sp.dayStartHour;
    final todayStr =
        du.AppDateUtils.effectiveDateKey(DateTime.now(), dayStartHour);
    final adjustedToday = du.AppDateUtils.effectiveDate(now, dayStartHour);

    final fmgeDate = DateTime.parse(sp.fmgeDate);
    final step1Date = DateTime.parse(sp.step1Date);
    final primaryExamDate = fmgeDate.isAfter(step1Date) ? fmgeDate : step1Date;
    final planWindow =
        _buildPlanWindow(sp.studyPlanStartDate, adjustedToday, primaryExamDate);

    final displayName = _displayName(app);
    final greeting = _greetingFor(now);
    final subtitle = _buildSubtitle(planWindow);

    final fmgeDaysRemaining = _daysRemaining(fmgeDate, today);
    final step1DaysRemaining = _daysRemaining(step1Date, today);
    final fmgeCountdownProgress =
        _countdownProgress(planWindow, fmgeDate, adjustedToday);
    final step1CountdownProgress =
        _countdownProgress(planWindow, step1Date, adjustedToday);

    final todayPagesRead = app.getTodayPagesRead(dayStartHour);
    final dailyGoal = sp.dailyFAGoal;
    final totalFAPages = app.faPages.isNotEmpty ? app.faPages.length : 676;
    final totalReadPages =
        app.faPages.where((page) => page.status != 'unread').length;
    final ankiDonePages =
        app.faPages.where((page) => page.status == 'anki_done').length;
    final unreadPages =
        app.faPages.where((page) => page.status == 'unread').length;
    final paceDayKeys = _readDayKeys(app, dayStartHour);
    final paceDays = planWindow?.elapsedDays ?? math.max(1, paceDayKeys.length);
    final pagesPerDay =
        totalReadPages == 0 ? 0.0 : totalReadPages / math.max(1, paceDays);
    final sparklinePoints =
        _pageSparklinePoints(app, adjustedToday, dayStartHour);
    final projectedCompletionDate =
        _projectCompletionDate(unreadPages, pagesPerDay, adjustedToday);
    final fmgeRequiredPace = _requiredPace(unreadPages, fmgeDaysRemaining);
    final step1RequiredPace = _requiredPace(unreadPages, step1DaysRemaining);
    final fmgeOnTrack = unreadPages == 0 ||
        fmgeDaysRemaining <= 0 ||
        pagesPerDay >= fmgeRequiredPace;
    final step1OnTrack = unreadPages == 0 ||
        step1DaysRemaining <= 0 ||
        pagesPerDay >= step1RequiredPace;

    final prayerMinutes = _todayMinutesForCategory(
      app,
      todayStr,
      TimeLogCategory.prayer,
    );
    final studyMinutes = _todayStudyMinutes(app, todayStr);
    final sleepMinutes = _sleepWindowMinutes(sp.sleepTime, sp.wakeTime);
    final freeMinutes =
        math.max(0, (24 * 60) - sleepMinutes - prayerMinutes - studyMinutes);

    final todayPlan = app.getDayPlan(todayStr);
    final todayBlocks = todayPlan?.blocks ?? const <Block>[];
    final dueRevisionItems = _dueRevisionItems(app, adjustedToday);
    final dueRevisionCount = dueRevisionItems.length;
    final goalRows = _buildGoalRows(
      context: context,
      todayPagesRead: todayPagesRead,
      dailyGoal: dailyGoal,
      todayPlan: todayPlan,
      todayBlocks: todayBlocks,
      app: app,
      todayStr: todayStr,
      dueRevisionCount: dueRevisionCount,
    );

    final quotePool =
        kFocusQuotes.where((quote) => quote.trim().isNotEmpty).toList();
    final weeklyStudyPoints = _buildWeeklyStudyPoints(app, adjustedToday);
    final weeklyStudyTotalMinutes = weeklyStudyPoints.fold<int>(
      0,
      (sum, point) => sum + point.minutes,
    );
    final weeklyStudyAverageMinutes = weeklyStudyPoints.isEmpty
        ? 0.0
        : weeklyStudyTotalMinutes / weeklyStudyPoints.length;
    final bestStudyDay = _bestStudyDay(weeklyStudyPoints);
    final subjectTotals = _buildSubjectMinutes(app);
    final topSubjects = subjectTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topSubjectEntries = topSubjects.take(4).toList();
    final maxSubjectMinutes =
        topSubjectEntries.isNotEmpty ? topSubjectEntries.first.value : 1;
    final faOverallAverage = _faOverallAverage(app.faPages, adjustedToday);
    final faWeeklyAverage = _faRollingAverage(
      app.faPages,
      adjustedToday,
      days: 7,
    );
    final faEta = _faEta(
      totalPages: totalFAPages,
      readPages: totalReadPages,
      pagesPerDay: faWeeklyAverage,
      today: adjustedToday,
    );

    return _DashboardShell(
      isDark: isDark,
      child: RefreshIndicator(
        color: DashboardColors.primary,
        backgroundColor: DashboardColors.glassFill(isDark),
        onRefresh: () => app.loadAll(),
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 24),
          children: <Widget>[
            _FadeSlideIn(
              delay: Duration.zero,
              beginOffset: const Offset(0, 20),
              child: _GreetingSection(
                greeting: greeting,
                displayName: displayName,
                subtitle: subtitle,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 14),
            // ── Quick Actions Row ─────────────────────────────
            _FadeSlideIn(
              delay: const Duration(milliseconds: 40),
              beginOffset: const Offset(0, 16),
              child: _QuickActionsRow(isDark: isDark),
            ),
            const SizedBox(height: 16),
            // ── Daily Progress Hero ───────────────────────────
            LiquidGlassCard(
              hero: true,
              delay: const Duration(milliseconds: 60),
              glowColor: DashboardColors.primary.withValues(alpha: 0.18),
              child: _DailyProgressHero(
                pagesRead: todayPagesRead,
                dailyGoal: dailyGoal,
                studyMinutes: studyMinutes,
                dueRevisions: dueRevisionCount,
                streak: app.streakData.currentStreak,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: LiquidGlassCard(
                    hero: true,
                    delay: const Duration(milliseconds: 100),
                    glowColor: DashboardColors.primary.withValues(alpha: 0.25),
                    child: _CountdownCard(
                      label: 'FMGE',
                      daysRemaining: fmgeDaysRemaining,
                      progress: fmgeCountdownProgress,
                      ringColor: DashboardColors.primary,
                      labelColor: DashboardColors.primaryLight,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LiquidGlassCard(
                    hero: true,
                    delay: const Duration(milliseconds: 140),
                    glowColor:
                        DashboardColors.primaryViolet.withValues(alpha: 0.25),
                    child: _CountdownCard(
                      label: 'USMLE STEP 1',
                      daysRemaining: step1DaysRemaining,
                      progress: step1CountdownProgress,
                      ringColor: DashboardColors.primaryViolet,
                      labelColor: DashboardColors.primaryLavender,
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LiquidGlassCard(
              delay: const Duration(milliseconds: 200),
              child: _PaceInsightCard(
                pace: pagesPerDay,
                projectedCompletionDate: projectedCompletionDate,
                sparklinePoints: sparklinePoints,
                fmgeOnTrack: fmgeOnTrack,
                step1OnTrack: step1OnTrack,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 16),
            LiquidGlassCard(
              delay: const Duration(milliseconds: 240),
              child: _TimeBudgetCard(
                sleepMinutes: sleepMinutes,
                studyMinutes: studyMinutes,
                freeMinutes: freeMinutes,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 16),
            LiquidGlassCard(
              delay: const Duration(milliseconds: 280),
              child: _GoalsCard(
                goals: goalRows,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 16),
            LiquidGlassCard(
              delay: const Duration(milliseconds: 320),
              child: _StreakCard(
                streak: app.streakData.currentStreak,
                quotes: quotePool.isEmpty
                    ? const <String>['Consistency beats intensity.']
                    : quotePool,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 16),
            LiquidGlassCard(
              delay: const Duration(milliseconds: 360),
              child: _AnalyticsCard(
                points: weeklyStudyPoints,
                totalMinutes: weeklyStudyTotalMinutes,
                averageMinutes: weeklyStudyAverageMinutes,
                bestDay: bestStudyDay,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 16),
            LiquidGlassCard(
              delay: const Duration(milliseconds: 400),
              child: _FATrackerCard(
                readPages: totalReadPages,
                ankiDone: ankiDonePages,
                unreadPages: unreadPages,
                totalPages: totalFAPages,
                overallAverage: faOverallAverage,
                weeklyAverage: faWeeklyAverage,
                eta: faEta,
                isDark: isDark,
                onOpen: () => context.go('/tracker'),
              ),
            ),
            const SizedBox(height: 16),
            LiquidGlassCard(
              delay: const Duration(milliseconds: 440),
              child: _RevisionQueueCard(
                dueCount: dueRevisionCount,
                dueItems: dueRevisionItems.take(3).toList(),
                onNavigate: () => context.go('/revision'),
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 16),
            LiquidGlassCard(
              delay: const Duration(milliseconds: 480),
              child: _ActivityDotsCard(
                points: weeklyStudyPoints,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 16),
            LiquidGlassCard(
              delay: const Duration(milliseconds: 520),
              child: _SubjectBreakdownCard(
                topSubjects: topSubjectEntries,
                maxMinutes: maxSubjectMinutes,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardLoadingScreen extends StatefulWidget {
  const _DashboardLoadingScreen({required this.isDark});

  final bool isDark;

  @override
  State<_DashboardLoadingScreen> createState() =>
      _DashboardLoadingScreenState();
}

class _DashboardLoadingScreenState extends State<_DashboardLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DashboardShell(
      isDark: widget.isDark,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: <Widget>[
          _shimmerBox(
            height: 56,
            borderRadius: 20,
            widthFactor: 0.78,
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _shimmerBox(height: 176, borderRadius: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _shimmerBox(height: 176, borderRadius: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _shimmerBox(height: 168, borderRadius: 24),
          const SizedBox(height: 16),
          _shimmerBox(height: 138, borderRadius: 24),
          const SizedBox(height: 16),
          _shimmerBox(height: 214, borderRadius: 24),
          const SizedBox(height: 16),
          _shimmerBox(height: 124, borderRadius: 24),
          const SizedBox(height: 16),
          _shimmerBox(height: 228, borderRadius: 24),
          const SizedBox(height: 16),
          _shimmerBox(height: 176, borderRadius: 24),
          const SizedBox(height: 16),
          _shimmerBox(height: 168, borderRadius: 24),
          const SizedBox(height: 16),
          _shimmerBox(height: 154, borderRadius: 24),
          const SizedBox(height: 16),
          _shimmerBox(height: 180, borderRadius: 24),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    required double height,
    required double borderRadius,
    double widthFactor = 1,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final alpha = 0.06 + (_controller.value * 0.06);
        return FractionallySizedBox(
          widthFactor: widthFactor,
          alignment: Alignment.centerLeft,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: alpha),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: widget.isDark
                    ? DashboardColors.glassBorderDark
                    : DashboardColors.glassBorderLight,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardShell extends StatelessWidget {
  const _DashboardShell({
    required this.isDark,
    required this.child,
  });

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: DashboardColors.background(isDark),
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: AuroraBackground(isDark: isDark),
            ),
            SafeArea(
              bottom: false,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({
    required this.greeting,
    required this.displayName,
    required this.subtitle,
    required this.isDark,
  });

  final String greeting;
  final String displayName;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final todayFormatted = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Date label with subtle dot separator
        Row(
          children: <Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: DashboardColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              todayFormatted.toUpperCase(),
              style: _inter(
                size: 11,
                weight: FontWeight.w600,
                color: DashboardColors.primary.withValues(alpha: 0.7),
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Greeting with gradient name
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$greeting, ',
                style: _inter(
                  size: 26,
                  weight: FontWeight.w500,
                  color: DashboardColors.textPrimary(isDark),
                ),
              ),
              TextSpan(
                text: displayName,
                style: _inter(
                  size: 26,
                  weight: FontWeight.w800,
                  color: DashboardColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _TypewriterText(
                  text: subtitle,
                  style: _inter(
                    size: 13,
                    weight: FontWeight.w400,
                    color: DashboardColors.textSecondary,
                  ),
                ),
              ),
              const _BlinkingCursor(),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Subtle gradient divider
        Container(
          height: 1.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: LinearGradient(
              colors: [
                DashboardColors.primary.withValues(alpha: 0.4),
                DashboardColors.primaryViolet.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// QUICK ACTIONS ROW — glass shortcut buttons
// ══════════════════════════════════════════════════════════════════

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _QuickActionButton(
          icon: Icons.menu_book_rounded,
          label: 'Study',
          color: DashboardColors.primary,
          isDark: isDark,
          onTap: () => context.go('/today'),
        ),
        const SizedBox(width: 10),
        _QuickActionButton(
          icon: Icons.timer_rounded,
          label: 'Track Now',
          color: DashboardColors.primaryViolet,
          isDark: isDark,
          onTap: () => context.go('/time'),
        ),
        const SizedBox(width: 10),
        _QuickActionButton(
          icon: Icons.replay_rounded,
          label: 'Revisions',
          color: const Color(0xFFF59E0B),
          isDark: isDark,
          onTap: () => context.go('/revision'),
        ),
        const SizedBox(width: 10),
        _QuickActionButton(
          icon: Icons.insights_rounded,
          label: 'Analytics',
          color: DashboardColors.primaryLight,
          isDark: isDark,
          onTap: () => context.go('/analytics'),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? color.withValues(alpha: 0.08)
                    : color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? color.withValues(alpha: 0.15)
                      : color.withValues(alpha: 0.12),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, size: 22, color: color),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: _inter(
                      size: 10,
                      weight: FontWeight.w600,
                      color: DashboardColors.textPrimary(isDark),
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
}

// ══════════════════════════════════════════════════════════════════
// DAILY PROGRESS HERO — today's summary with circular progress
// ══════════════════════════════════════════════════════════════════

class _DailyProgressHero extends StatelessWidget {
  const _DailyProgressHero({
    required this.pagesRead,
    required this.dailyGoal,
    required this.studyMinutes,
    required this.dueRevisions,
    required this.streak,
    required this.isDark,
  });

  final int pagesRead;
  final int dailyGoal;
  final int studyMinutes;
  final int dueRevisions;
  final int streak;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final progress = dailyGoal > 0
        ? (pagesRead / dailyGoal).clamp(0.0, 1.0)
        : 0.0;
    final studyH = studyMinutes ~/ 60;
    final studyM = studyMinutes % 60;

    return Row(
      children: <Widget>[
        // Circular progress ring
        SizedBox(
          width: 90,
          height: 90,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CustomPaint(
                painter: _CircularProgressPainter(
                  progress: value,
                  color: DashboardColors.primary,
                  trackColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : DashboardColors.primary.withValues(alpha: 0.08),
                  strokeWidth: 7,
                ),
                child: child,
              );
            },
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedCounter(
                    value: pagesRead.toDouble(),
                    style: _inter(
                      size: 22,
                      weight: FontWeight.w800,
                      color: DashboardColors.textPrimary(isDark),
                    ),
                  ),
                  Text(
                    '/ $dailyGoal',
                    style: _inter(
                      size: 11,
                      weight: FontWeight.w500,
                      color: DashboardColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        // Stats column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "Today's Progress",
                style: _inter(
                  size: 15,
                  weight: FontWeight.w600,
                  color: DashboardColors.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  _MiniStat(
                    icon: Icons.schedule_rounded,
                    value: studyH > 0 ? '${studyH}h ${studyM}m' : '${studyM}m',
                    label: 'studied',
                    color: DashboardColors.primary,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 14),
                  _MiniStat(
                    icon: Icons.replay_rounded,
                    value: '$dueRevisions',
                    label: 'due',
                    color: dueRevisions > 0
                        ? DashboardColors.warning
                        : DashboardColors.success,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 14),
                  _MiniStat(
                    icon: Icons.local_fire_department_rounded,
                    value: '$streak',
                    label: 'streak',
                    color: const Color(0xFFF97316),
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: _inter(
            size: 14,
            weight: FontWeight.w700,
            color: DashboardColors.textPrimary(isDark),
          ),
        ),
        Text(
          label,
          style: _inter(
            size: 10,
            weight: FontWeight.w400,
            color: DashboardColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  const _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [
            color,
            color.withValues(alpha: 0.6),
            color,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );

      // Glow dot at end of arc
      final angle = -math.pi / 2 + 2 * math.pi * progress;
      final dotCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(dotCenter, strokeWidth / 2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      progress != old.progress ||
      color != old.color ||
      trackColor != old.trackColor;
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({
    required this.label,
    required this.daysRemaining,
    required this.progress,
    required this.ringColor,
    required this.labelColor,
    required this.isDark,
  });

  final String label;
  final int daysRemaining;
  final double progress;
  final Color ringColor;
  final Color labelColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _CountdownRing(
          progress: progress,
          color: ringColor,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: _inter(
            size: 12,
            weight: FontWeight.w700,
            color: labelColor,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedCounter(
          value: daysRemaining.toDouble(),
          style: _inter(
            size: 28,
            weight: FontWeight.w800,
            color: DashboardColors.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'days remaining',
          style: _inter(
            size: 11,
            weight: FontWeight.w400,
            color: DashboardColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PaceInsightCard extends StatelessWidget {
  const _PaceInsightCard({
    required this.pace,
    required this.projectedCompletionDate,
    required this.sparklinePoints,
    required this.fmgeOnTrack,
    required this.step1OnTrack,
    required this.isDark,
  });

  final double pace;
  final DateTime? projectedCompletionDate;
  final List<int> sparklinePoints;
  final bool fmgeOnTrack;
  final bool step1OnTrack;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final chipTextStyle = _inter(
      size: 11,
      weight: FontWeight.w500,
      color: DashboardColors.textPrimary(isDark),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 4,
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: DashboardColors.verticalAccentGradient(),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: 1),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: 0.6 + (math.sin(value * math.pi * 2) * 0.2),
                child: child,
              );
            },
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Your Pace',
                      style: _inter(
                        size: 15,
                        weight: FontWeight.w600,
                        color: DashboardColors.textPrimary(isDark),
                      ),
                    ),
                  ),
                  _SparklineChart(
                    points: sparklinePoints,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedCounter(
                value: pace,
                decimals: 1,
                suffix: ' pages/day',
                style: _inter(
                  size: 32,
                  weight: FontWeight.w800,
                  color: DashboardColors.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _StatusChip(
                    label:
                        fmgeOnTrack ? 'On track for FMGE' : 'Behind for FMGE',
                    color: fmgeOnTrack
                        ? DashboardColors.success
                        : DashboardColors.warning,
                    style: chipTextStyle,
                    isDark: isDark,
                  ),
                  _StatusChip(
                    label: step1OnTrack
                        ? 'On track for Step 1'
                        : 'Push harder for Step 1',
                    color: step1OnTrack
                        ? DashboardColors.success
                        : DashboardColors.warning,
                    style: chipTextStyle,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'FA done: ${_formatProjectionDate(projectedCompletionDate)}',
                style: _inter(
                  size: 12,
                  weight: FontWeight.w400,
                  color: DashboardColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeBudgetCard extends StatelessWidget {
  const _TimeBudgetCard({
    required this.sleepMinutes,
    required this.studyMinutes,
    required this.freeMinutes,
    required this.isDark,
  });

  final int sleepMinutes;
  final int studyMinutes;
  final int freeMinutes;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final segments = <_BudgetSegmentData>[
      _BudgetSegmentData(
        label: 'Sleep',
        minutes: sleepMinutes,
        color: DashboardColors.budgetSleep,
        delay: Duration.zero,
      ),
      _BudgetSegmentData(
        label: 'Study',
        minutes: studyMinutes,
        color: DashboardColors.primary,
        delay: const Duration(milliseconds: 180),
      ),
      _BudgetSegmentData(
        label: 'Free',
        minutes: freeMinutes,
        color: DashboardColors.primary.withValues(alpha: 0.15),
        delay: const Duration(milliseconds: 360),
      ),
    ];

    final hours = freeMinutes ~/ 60;
    final minutes = freeMinutes % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Today's Time Budget",
          style: _inter(
            size: 15,
            weight: FontWeight.w600,
            color: DashboardColors.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 12),
        _TimeBudgetBar(
          segments: segments,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            AnimatedCounter(
              value: hours.toDouble(),
              suffix: 'h ',
              style: _inter(
                size: 26,
                weight: FontWeight.w800,
                color: DashboardColors.textPrimary(isDark),
              ),
            ),
            AnimatedCounter(
              value: minutes.toDouble(),
              suffix: 'min',
              style: _inter(
                size: 26,
                weight: FontWeight.w800,
                color: DashboardColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'FREE',
                style: _inter(
                  size: 13,
                  weight: FontWeight.w400,
                  color: DashboardColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({
    required this.goals,
    required this.isDark,
  });

  final List<_GoalProgressData> goals;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Today's Goals",
          style: _inter(
            size: 15,
            weight: FontWeight.w600,
            color: DashboardColors.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < goals.length; index++) ...<Widget>[
          _FadeSlideIn(
            delay: Duration(milliseconds: 400 + (index * 60)),
            beginOffset: const Offset(-20, 0),
            child: _GoalRow(
              data: goals[index],
              isDark: isDark,
            ),
          ),
          if (index != goals.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.streak,
    required this.quotes,
    required this.isDark,
  });

  final int streak;
  final List<String> quotes;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: 1),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                final scale = 1 + (math.sin(value * math.pi * 2) * 0.08);
                return Transform.scale(scale: scale, child: child);
              },
              child: Icon(
                Icons.local_fire_department_rounded,
                color: DashboardColors.warning,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Day $streak streak',
              style: _inter(
                size: 18,
                weight: FontWeight.w700,
                color: DashboardColors.textPrimary(isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RotatingQuoteCard(
          quotes: quotes,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.points,
    required this.totalMinutes,
    required this.averageMinutes,
    required this.bestDay,
    required this.isDark,
  });

  final List<_WeeklyStudyPoint> points;
  final int totalMinutes;
  final double averageMinutes;
  final _WeeklyStudyPoint? bestDay;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Analytics',
          style: _inter(
            size: 15,
            weight: FontWeight.w600,
            color: DashboardColors.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _DashboardMetricPanel(
                label: 'This week',
                value: _formatHM(totalMinutes),
                accent: DashboardColors.primary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DashboardMetricPanel(
                label: 'Avg / day',
                value: _formatHM(averageMinutes.round()),
                accent: DashboardColors.primaryLight,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DashboardMetricPanel(
                label: 'Best day',
                value: bestDay == null
                    ? '--'
                    : DateFormat('EEE').format(bestDay!.date),
                accent: DashboardColors.primaryViolet,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _WeeklyStudyBars(
          points: points,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        Text(
          totalMinutes == 0 || bestDay == null
              ? 'Start logging study sessions to unlock your 7-day trend.'
              : '${DateFormat('EEEE').format(bestDay!.date)} led the week with '
                  '${_formatHM(bestDay!.minutes)} logged.',
          style: _inter(
            size: 12,
            weight: FontWeight.w400,
            color: DashboardColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DashboardMetricPanel extends StatelessWidget {
  const _DashboardMetricPanel({
    required this.label,
    required this.value,
    required this.accent,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.12 : 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: _inter(
              size: 11,
              weight: FontWeight.w500,
              color: DashboardColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _inter(
              size: 16,
              weight: FontWeight.w700,
              color: DashboardColors.textPrimary(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyStudyBars extends StatelessWidget {
  const _WeeklyStudyBars({
    required this.points,
    required this.isDark,
  });

  final List<_WeeklyStudyPoint> points;
  final bool isDark;

  static const List<Color> _barColors = <Color>[
    DashboardColors.primaryLight,
    DashboardColors.primary,
    DashboardColors.primaryViolet,
    DashboardColors.primaryLight,
    DashboardColors.primary,
    DashboardColors.primaryViolet,
    DashboardColors.primary,
  ];

  @override
  Widget build(BuildContext context) {
    final maxMinutes = points.fold<int>(
      0,
      (max, point) => math.max(max, point.minutes),
    );
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : DashboardColors.primary.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : DashboardColors.primary.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(points.length, (index) {
          final point = points[index];
          final barColor = _barColors[index % _barColors.length];
          final targetHeight = point.minutes == 0
              ? 10.0
              : math.max(18.0, (point.minutes / math.max(1, maxMinutes)) * 86);

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == points.length - 1 ? 0 : 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    height: 110,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: targetHeight),
                        duration: Duration(milliseconds: 500 + (index * 70)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Container(
                            width: 16,
                            height: value,
                            decoration: BoxDecoration(
                              color: point.minutes == 0
                                  ? trackColor
                                  : null,
                              gradient: point.minutes == 0
                                  ? null
                                  : DashboardColors.progressGradient(barColor),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: point.minutes == 0
                                  ? const <BoxShadow>[]
                                  : <BoxShadow>[
                                      BoxShadow(
                                        color: barColor.withValues(alpha: 0.30),
                                        blurRadius: 10,
                                      ),
                                    ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('E').format(point.date),
                    style: _inter(
                      size: 10,
                      weight: FontWeight.w600,
                      color: DashboardColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatShortHM(point.minutes),
                    style: _inter(
                      size: 10,
                      weight: FontWeight.w500,
                      color: DashboardColors.textPrimary(isDark),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FATrackerCard extends StatelessWidget {
  const _FATrackerCard({
    required this.readPages,
    required this.ankiDone,
    required this.unreadPages,
    required this.totalPages,
    required this.overallAverage,
    required this.weeklyAverage,
    required this.eta,
    required this.isDark,
    required this.onOpen,
  });

  final int readPages;
  final int ankiDone;
  final int unreadPages;
  final int totalPages;
  final double overallAverage;
  final double weeklyAverage;
  final DateTime? eta;
  final bool isDark;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final chipStyle = _inter(
      size: 11,
      weight: FontWeight.w500,
      color: DashboardColors.textPrimary(isDark),
    );
    final progress = totalPages == 0 ? 0.0 : (readPages / totalPages) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'FA Tracker',
                style: _inter(
                  size: 15,
                  weight: FontWeight.w600,
                  color: DashboardColors.textPrimary(isDark),
                ),
              ),
            ),
            TextButton(
              onPressed: onOpen,
              child: Text(
                'Open',
                style: _inter(
                  size: 12,
                  weight: FontWeight.w600,
                  color: DashboardColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedProgressBar(
          progress: progress,
          color: DashboardColors.primary,
          delay: const Duration(milliseconds: 120),
          height: 8,
        ),
        const SizedBox(height: 10),
        Text(
          '$readPages / $totalPages pages read',
          style: _inter(
            size: 14,
            weight: FontWeight.w600,
            color: DashboardColors.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _StatusChip(
              label: '$ankiDone Anki done',
              color: DashboardColors.success,
              style: chipStyle,
              isDark: isDark,
            ),
            _StatusChip(
              label: '$unreadPages unread',
              color: DashboardColors.warning,
              style: chipStyle,
              isDark: isDark,
            ),
            _StatusChip(
              label: '${progress.toStringAsFixed(0)}% complete',
              color: DashboardColors.primaryLight,
              style: chipStyle,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: _DashboardMetricPanel(
                label: 'Overall avg',
                value: '${overallAverage.toStringAsFixed(1)} pg/day',
                accent: DashboardColors.primary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DashboardMetricPanel(
                label: '7-day avg',
                value: '${weeklyAverage.toStringAsFixed(1)} pg/day',
                accent: DashboardColors.primaryViolet,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DashboardMetricPanel(
                label: 'ETA',
                value: eta == null ? '--' : _formatProjectionDate(eta),
                accent: DashboardColors.primaryLight,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RevisionQueueCard extends StatelessWidget {
  const _RevisionQueueCard({
    required this.dueCount,
    required this.dueItems,
    required this.onNavigate,
    required this.isDark,
  });

  final int dueCount;
  final List<RevisionItem> dueItems;
  final VoidCallback onNavigate;
  final bool isDark;

  void _showRevisionSheet(BuildContext context) {
    final app = context.read<AppProvider>();
    final hubItems = _buildRevisionQueueSheetItems(app);
    final doNow = hubItems.where((item) => item.status == 'Do Now').toList();
    final upcoming =
        hubItems.where((item) => item.status == 'Upcoming').toList();
    final visibleItems = doNow.isNotEmpty ? doNow : upcoming;
    final title = doNow.isNotEmpty ? 'Do Now' : 'Upcoming';
    final sheetIsDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.56,
          minChildSize: 0.34,
          maxChildSize: 0.90,
          expand: false,
          builder: (ctx, scrollCtrl) {
            return Container(
              decoration: BoxDecoration(
                color: sheetIsDark ? const Color(0xFF161629) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 10),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '$title (${visibleItems.length})',
                            style: _inter(
                              size: 18,
                              weight: FontWeight.w700,
                              color: DashboardColors.textPrimary(sheetIsDark),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            onNavigate();
                          },
                          child: Text(
                            'View All',
                            style: _inter(
                              size: 12,
                              weight: FontWeight.w600,
                              color: DashboardColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (visibleItems.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'No revisions queued right now.',
                          style: _inter(
                            size: 14,
                            weight: FontWeight.w500,
                            color: DashboardColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: visibleItems.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.grey.withValues(alpha: 0.18),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final item = visibleItems[index];
                          final urgent = item.status == 'Do Now';
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: urgent
                                  ? DashboardColors.warning.withValues(
                                      alpha: 0.16,
                                    )
                                  : DashboardColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                              child: Icon(
                                urgent
                                    ? Icons.priority_high_rounded
                                    : Icons.schedule_rounded,
                                color: urgent
                                    ? DashboardColors.warning
                                    : DashboardColors.primary,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              _revisionDisplayTitle(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _inter(
                                size: 14,
                                weight: FontWeight.w600,
                                color:
                                    DashboardColors.textPrimary(sheetIsDark),
                              ),
                            ),
                            subtitle: Text(
                              _revisionDisplaySubtitle(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _inter(
                                size: 12,
                                weight: FontWeight.w400,
                                color: DashboardColors.textSecondary,
                              ),
                            ),
                            trailing: Text(
                              item.status,
                              style: _inter(
                                size: 11,
                                weight: FontWeight.w600,
                                color: urgent
                                    ? DashboardColors.warning
                                    : DashboardColors.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Revision Queue',
                style: _inter(
                  size: 15,
                  weight: FontWeight.w600,
                  color: DashboardColors.textPrimary(isDark),
                ),
              ),
            ),
            TextButton(
              onPressed: () => _showRevisionSheet(context),
              child: Text(
                'Open',
                style: _inter(
                  size: 12,
                  weight: FontWeight.w600,
                  color: DashboardColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          dueCount == 0 ? 'All caught up' : '$dueCount items due today',
          style: _inter(
            size: 22,
            weight: FontWeight.w800,
            color: dueCount == 0
                ? DashboardColors.success
                : DashboardColors.warning,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dueCount == 0
              ? 'Nothing urgent is waiting in your revision stack.'
              : 'Review the next items before the queue stacks up.',
          style: _inter(
            size: 12,
            weight: FontWeight.w400,
            color: DashboardColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        if (dueItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DashboardColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DashboardColors.success.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              'No revisions due today.',
              style: _inter(
                size: 13,
                weight: FontWeight.w500,
                color: DashboardColors.textPrimary(isDark),
              ),
            ),
          )
        else
          ...dueItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.18),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.replay_circle_filled_rounded,
                        color: DashboardColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _revisionDisplayTitle(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _inter(
                                size: 13,
                                weight: FontWeight.w600,
                                color: DashboardColors.textPrimary(isDark),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _revisionDisplaySubtitle(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _inter(
                                size: 11,
                                weight: FontWeight.w400,
                                color: DashboardColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}

class _ActivityDotsCard extends StatelessWidget {
  const _ActivityDotsCard({
    required this.points,
    required this.isDark,
  });

  final List<_WeeklyStudyPoint> points;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final maxMinutes = points.fold<int>(
      0,
      (max, point) => math.max(max, point.minutes),
    );
    final activeDays = points.where((point) => point.minutes > 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Last 7 Days',
          style: _inter(
            size: 15,
            weight: FontWeight.w600,
            color: DashboardColors.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$activeDays of 7 days active',
          style: _inter(
            size: 12,
            weight: FontWeight.w400,
            color: DashboardColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(points.length, (index) {
            final point = points[index];
            final isToday = index == points.length - 1;
            final intensity = maxMinutes == 0
                ? 0.0
                : point.minutes / math.max(1, maxMinutes);
            final outerColor = point.minutes == 0
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : DashboardColors.primary.withValues(alpha: 0.06))
                : DashboardColors.primary.withValues(
                    alpha: isDark ? 0.12 + (intensity * 0.18) : 0.10,
                  );
            final innerSize =
                point.minutes == 0 ? 8.0 : 10 + (intensity * 6);

            return Expanded(
              child: Column(
                children: <Widget>[
                  Text(
                    DateFormat('E').format(point.date).substring(0, 1),
                    style: _inter(
                      size: 11,
                      weight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday
                          ? DashboardColors.primary
                          : DashboardColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: outerColor,
                      border: isToday
                          ? Border.all(
                              color: DashboardColors.primary,
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Container(
                        width: innerSize,
                        height: innerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: point.minutes == 0
                              ? Colors.white.withValues(
                                  alpha: isDark ? 0.15 : 0.35,
                                )
                              : DashboardColors.primaryLight.withValues(
                                  alpha: 0.85,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatShortHM(point.minutes),
                    style: _inter(
                      size: 10,
                      weight: FontWeight.w500,
                      color: DashboardColors.textPrimary(isDark),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SubjectBreakdownCard extends StatelessWidget {
  const _SubjectBreakdownCard({
    required this.topSubjects,
    required this.maxMinutes,
    required this.isDark,
  });

  final List<MapEntry<String, int>> topSubjects;
  final int maxMinutes;
  final bool isDark;

  static const List<Color> _subjectColors = <Color>[
    DashboardColors.primary,
    DashboardColors.primaryViolet,
    DashboardColors.primaryLight,
    DashboardColors.success,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Time by Subject',
          style: _inter(
            size: 15,
            weight: FontWeight.w600,
            color: DashboardColors.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 12),
        if (topSubjects.isEmpty)
          Text(
            'Start logging study sessions to see your subject split.',
            style: _inter(
              size: 13,
              weight: FontWeight.w400,
              color: DashboardColors.textSecondary,
            ),
          )
        else
          ...List<Widget>.generate(topSubjects.length, (index) {
            final entry = topSubjects[index];
            final color = _subjectColors[index % _subjectColors.length];
            final progress = (entry.value / math.max(1, maxMinutes)) * 100;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == topSubjects.length - 1 ? 0 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _inter(
                            size: 13,
                            weight: FontWeight.w600,
                            color: DashboardColors.textPrimary(isDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatHM(entry.value),
                        style: _inter(
                          size: 12,
                          weight: FontWeight.w500,
                          color: DashboardColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedProgressBar(
                    progress: progress,
                    color: color,
                    delay: Duration(milliseconds: 150 + (index * 70)),
                    height: 6,
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _GoalRow extends StatefulWidget {
  const _GoalRow({
    required this.data,
    required this.isDark,
  });

  final _GoalProgressData data;
  final bool isDark;

  @override
  State<_GoalRow> createState() => _GoalRowState();
}

class _GoalRowState extends State<_GoalRow> {
  bool _pressed = false;

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.data.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final iconColor = data.done ? DashboardColors.success : data.color;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: _handleTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(top: 2),
              child: Icon(
                data.done ? Icons.check_circle_rounded : data.icon,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          data.label,
                          style: _inter(
                            size: 13,
                            weight: FontWeight.w500,
                            color: DashboardColors.textPrimary(widget.isDark),
                          ),
                        ),
                      ),
                      Text(
                        data.statusText,
                        style: _inter(
                          size: 12,
                          weight: FontWeight.w600,
                          color: data.done
                              ? DashboardColors.success
                              : DashboardColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedProgressBar(
                    progress: data.progress,
                    color: data.done ? DashboardColors.success : data.color,
                    delay: data.progressDelay,
                    height: 4,
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

class _RotatingQuoteCard extends StatefulWidget {
  const _RotatingQuoteCard({
    required this.quotes,
    required this.isDark,
  });

  final List<String> quotes;
  final bool isDark;

  @override
  State<_RotatingQuoteCard> createState() => _RotatingQuoteCardState();
}

class _RotatingQuoteCardState extends State<_RotatingQuoteCard> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _RotatingQuoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quotes.length != widget.quotes.length) {
      _index = 0;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.quotes.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % widget.quotes.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DashboardColors.quoteCardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardColors.quoteCardBorder),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: Text(
          widget.quotes[_index],
          key: ValueKey<int>(_index),
          style: _inter(
            size: 13,
            weight: FontWeight.w400,
            color: DashboardColors.primaryLight,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.style,
    required this.isDark,
  });

  final String label;
  final Color color;
  final TextStyle style;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: style.copyWith(color: color),
      ),
    );
  }
}

class _TimeBudgetBar extends StatelessWidget {
  const _TimeBudgetBar({
    required this.segments,
    required this.isDark,
  });

  final List<_BudgetSegmentData> segments;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = segments.fold<int>(
      0,
      (sum, segment) => sum + segment.minutes,
    );

    return Container(
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : DashboardColors.primary.withValues(alpha: 0.06),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: segments.map((segment) {
              final widthFactor = totalMinutes == 0
                  ? 0.0
                  : segment.minutes / math.max(1, totalMinutes);
              return _BudgetSegment(
                width: constraints.maxWidth * widthFactor,
                label: segment.label,
                color: segment.color,
                delay: segment.delay,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _BudgetSegment extends StatefulWidget {
  const _BudgetSegment({
    required this.width,
    required this.label,
    required this.color,
    required this.delay,
  });

  final double width;
  final String label;
  final Color color;
  final Duration delay;

  @override
  State<_BudgetSegment> createState() => _BudgetSegmentState();
}

class _BudgetSegmentState extends State<_BudgetSegment> {
  Timer? _timer;
  double _targetWidth = 0;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant _BudgetSegment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width || oldWidget.delay != widget.delay) {
      _schedule();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    if (widget.delay == Duration.zero) {
      _targetWidth = widget.width;
      return;
    }
    _timer = Timer(widget.delay, () {
      if (!mounted) return;
      setState(() {
        _targetWidth = widget.width;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _targetWidth),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return SizedBox(
          width: value,
          child: Container(
            color: widget.color,
            alignment: Alignment.center,
            child: value > 44
                ? Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: _inter(
                      size: 8,
                      weight: FontWeight.w600,
                      color: DashboardColors.darkTextPrimary,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  final double progress;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: progress.clamp(0, 100) / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return CustomPaint(
          size: const Size.square(76),
          painter: _CountdownRingPainter(
            progress: value,
            color: color,
            trackColor: DashboardColors.countdownTrack(isDark),
          ),
        );
      },
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 4.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      progress * math.pi * 2,
      false,
      glowPaint,
    );

    final progressPaint = Paint()
      ..shader = ui.Gradient.sweep(
        center,
        <Color>[
          color.withValues(alpha: 0.75),
          color,
        ],
      )
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      progress * math.pi * 2,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

class _SparklineChart extends StatelessWidget {
  const _SparklineChart({
    required this.points,
    required this.isDark,
  });

  final List<int> points;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return CustomPaint(
          size: const Size(80, 28),
          painter: _SparklinePainter(
            values: points,
            progress: value,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.progress,
    required this.isDark,
  });

  final List<int> values;
  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue = math.max<double>(
      12,
      values.fold<double>(0, (max, value) => math.max(max, value.toDouble())),
    );

    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final dx = (index / math.max(1, values.length - 1)) * size.width;
      final dy = size.height - ((values[index] / maxValue) * size.height);
      if (index == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    final metric = path.computeMetrics().first;
    final drawPath = metric.extractPath(0, metric.length * progress);
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, 0),
        const <Color>[
          DashboardColors.primary,
          DashboardColors.primaryLight,
        ],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = DashboardColors.primary.withValues(
        alpha: isDark ? 0.30 : 0.18,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(drawPath, glowPaint);
    canvas.drawPath(drawPath, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark;
  }
}



class _TypewriterText extends StatefulWidget {
  const _TypewriterText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  Timer? _timer;
  String _displayed = '';

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant _TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startTyping();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _timer?.cancel();
    setState(() {
      _displayed = '';
    });
    var index = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (index > widget.text.length) {
        timer.cancel();
        return;
      }
      setState(() {
        _displayed = widget.text.substring(0, index);
      });
      index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayed,
      style: widget.style,
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text(
        '|',
        style: _inter(
          size: 14,
          weight: FontWeight.w400,
          color: DashboardColors.primary,
        ),
      ),
    );
  }
}

class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({
    required this.child,
    required this.delay,
    required this.beginOffset,
  });

  final Widget child;
  final Duration delay;
  final Offset beginOffset;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _visible = true;
    } else {
      _timer = Timer(widget.delay, () {
        if (!mounted) return;
        setState(() {
          _visible = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _visible ? 1 : 0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final dx = ui.lerpDouble(widget.beginOffset.dx, 0, value) ?? 0;
        final dy = ui.lerpDouble(widget.beginOffset.dy, 0, value) ?? 0;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _PlanWindow {
  const _PlanWindow({
    required this.startDate,
    required this.elapsedDays,
    required this.totalDays,
  });

  final DateTime startDate;
  final int elapsedDays;
  final int totalDays;
}

class _GoalProgressData {
  const _GoalProgressData({
    required this.icon,
    required this.label,
    required this.color,
    required this.progress,
    required this.statusText,
    required this.done,
    required this.progressDelay,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double progress;
  final String statusText;
  final bool done;
  final Duration progressDelay;
  final VoidCallback? onTap;
}

class _BudgetSegmentData {
  const _BudgetSegmentData({
    required this.label,
    required this.minutes,
    required this.color,
    required this.delay,
  });

  final String label;
  final int minutes;
  final Color color;
  final Duration delay;
}

class _WeeklyStudyPoint {
  const _WeeklyStudyPoint({
    required this.date,
    required this.minutes,
  });

  final DateTime date;
  final int minutes;
}

class _RevisionQueueSheetItem {
  const _RevisionQueueSheetItem({
    required this.id,
    required this.source,
    required this.title,
    required this.parentTitle,
    required this.pageNumber,
    required this.nextRevisionAt,
    required this.currentRevisionIndex,
    required this.status,
  });

  final String id;
  final String source;
  final String title;
  final String parentTitle;
  final String pageNumber;
  final String nextRevisionAt;
  final int currentRevisionIndex;
  final String status;

  factory _RevisionQueueSheetItem.fromRevisionItem(RevisionItem item) {
    return _RevisionQueueSheetItem(
      id: item.id,
      source: item.source,
      title: item.title,
      parentTitle: item.parentTitle,
      pageNumber: item.pageNumber,
      nextRevisionAt: item.nextRevisionAt,
      currentRevisionIndex: item.currentRevisionIndex,
      status: '',
    );
  }

  factory _RevisionQueueSheetItem.fromKnowledgeBaseEntry(
    KnowledgeBaseEntry item,
  ) {
    return _RevisionQueueSheetItem(
      id: 'kb-${item.pageNumber}',
      source: 'KB',
      title: item.title,
      parentTitle: item.subject,
      pageNumber: item.pageNumber,
      nextRevisionAt: item.nextRevisionAt ?? '',
      currentRevisionIndex: item.currentRevisionIndex,
      status: '',
    );
  }

  _RevisionQueueSheetItem copyWith({String? status}) {
    return _RevisionQueueSheetItem(
      id: id,
      source: source,
      title: title,
      parentTitle: parentTitle,
      pageNumber: pageNumber,
      nextRevisionAt: nextRevisionAt,
      currentRevisionIndex: currentRevisionIndex,
      status: status ?? this.status,
    );
  }
}

String _displayName(AppProvider app) {
  final name = app.userProfile?.displayName?.trim();
  if (name == null || name.isEmpty) {
    return 'Arsh';
  }
  return name;
}

String _greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String _buildSubtitle(_PlanWindow? planWindow) {
  if (planWindow == null) {
    return 'Every page matters.';
  }
  return 'Day ${planWindow.elapsedDays} of ${planWindow.totalDays}. '
      'Every page matters.';
}

_PlanWindow? _buildPlanWindow(
  String? studyPlanStartDate,
  DateTime adjustedToday,
  DateTime examDate,
) {
  final startDate = du.AppDateUtils.parseDate(studyPlanStartDate);
  if (startDate == null) {
    return null;
  }
  final elapsedDays =
      math.max(1, adjustedToday.difference(startDate).inDays + 1);
  final totalDays =
      math.max(elapsedDays, examDate.difference(startDate).inDays + 1);
  return _PlanWindow(
    startDate: startDate,
    elapsedDays: elapsedDays,
    totalDays: totalDays,
  );
}

int _daysRemaining(DateTime targetDate, DateTime today) {
  final normalizedTarget =
      DateTime(targetDate.year, targetDate.month, targetDate.day);
  final normalizedToday = DateTime(today.year, today.month, today.day);
  return math.max(0, normalizedTarget.difference(normalizedToday).inDays);
}

double _countdownProgress(
  _PlanWindow? planWindow,
  DateTime examDate,
  DateTime adjustedToday,
) {
  if (planWindow == null) return 0;
  final totalDays = examDate.difference(planWindow.startDate).inDays;
  if (totalDays <= 0) return 100;
  final elapsedDays =
      adjustedToday.difference(planWindow.startDate).inDays.clamp(0, totalDays);
  return (elapsedDays / totalDays) * 100;
}

Set<String> _readDayKeys(AppProvider app, int dayStartHour) {
  final days = <String>{};
  for (final page in app.faPages) {
    final firstReadAt = page.firstReadAt;
    if (firstReadAt == null || firstReadAt.isEmpty) continue;
    final date = DateTime.tryParse(firstReadAt);
    if (date == null) continue;
    days.add(du.AppDateUtils.effectiveDateKey(date, dayStartHour));
  }
  for (final subtopic in app.faSubtopics) {
    final firstReadAt = subtopic.firstReadAt;
    if (firstReadAt == null || firstReadAt.isEmpty) continue;
    final date = DateTime.tryParse(firstReadAt);
    if (date == null) continue;
    days.add(du.AppDateUtils.effectiveDateKey(date, dayStartHour));
  }
  return days;
}

List<int> _pageSparklinePoints(
  AppProvider app,
  DateTime adjustedToday,
  int dayStartHour,
) {
  return List<int>.generate(7, (index) {
    final date = adjustedToday.subtract(Duration(days: 6 - index));
    final key = du.AppDateUtils.formatDate(date);
    return app.getPagesReadOnDate(key, dayStartHour);
  });
}

DateTime? _projectCompletionDate(
  int unreadPages,
  double pagesPerDay,
  DateTime today,
) {
  if (unreadPages <= 0) return today;
  if (pagesPerDay <= 0) return null;
  final daysToFinish = (unreadPages / pagesPerDay).ceil();
  return today.add(Duration(days: daysToFinish));
}

double _requiredPace(int unreadPages, int daysRemaining) {
  if (unreadPages <= 0) return 0;
  if (daysRemaining <= 0) return unreadPages.toDouble();
  return unreadPages / daysRemaining;
}

int _todayMinutesForCategory(
  AppProvider app,
  String todayStr,
  TimeLogCategory category,
) {
  var total = 0;
  for (final log in app.timeLogs) {
    if (log.date == todayStr && log.category == category) {
      total += log.durationMinutes;
    }
  }
  return total;
}

int _todayStudyMinutes(AppProvider app, String todayStr) {
  const studyCategories = <TimeLogCategory>{
    TimeLogCategory.study,
    TimeLogCategory.revision,
    TimeLogCategory.qbank,
    TimeLogCategory.anki,
    TimeLogCategory.video,
    TimeLogCategory.noteTaking,
  };

  var total = 0;
  for (final log in app.timeLogs) {
    if (log.date == todayStr && studyCategories.contains(log.category)) {
      total += log.durationMinutes;
    }
  }
  for (final entry in app.studyEntries) {
    if (entry.date == todayStr) {
      total += entry.durationMinutes ?? 0;
    }
  }
  return total;
}

int _sleepWindowMinutes(String sleepTime, String wakeTime) {
  final sleep = _clockMinutes(sleepTime);
  final wake = _clockMinutes(wakeTime);
  if (sleep == -1 || wake == -1) return 0;
  return wake > sleep ? wake - sleep : (24 * 60) - sleep + wake;
}

int _clockMinutes(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return -1;
  final hours = int.tryParse(parts[0]);
  final minutes = int.tryParse(parts[1]);
  if (hours == null || minutes == null) return -1;
  return (hours * 60) + minutes;
}

List<_WeeklyStudyPoint> _buildWeeklyStudyPoints(
  AppProvider app,
  DateTime adjustedToday,
) {
  const studyCategories = <TimeLogCategory>{
    TimeLogCategory.study,
    TimeLogCategory.revision,
    TimeLogCategory.qbank,
    TimeLogCategory.anki,
    TimeLogCategory.video,
    TimeLogCategory.noteTaking,
  };

  final totals = <String, int>{};
  for (final log in app.timeLogs) {
    if (!studyCategories.contains(log.category)) continue;
    totals[log.date] = (totals[log.date] ?? 0) + log.durationMinutes;
  }
  for (final entry in app.studyEntries) {
    totals[entry.date] = (totals[entry.date] ?? 0) + (entry.durationMinutes ?? 0);
  }

  final normalizedToday = DateTime(
    adjustedToday.year,
    adjustedToday.month,
    adjustedToday.day,
  );
  return List<_WeeklyStudyPoint>.generate(7, (index) {
    final date = normalizedToday.subtract(Duration(days: 6 - index));
    return _WeeklyStudyPoint(
      date: date,
      minutes: totals[du.AppDateUtils.formatDate(date)] ?? 0,
    );
  });
}

_WeeklyStudyPoint? _bestStudyDay(List<_WeeklyStudyPoint> points) {
  if (points.isEmpty) return null;
  _WeeklyStudyPoint? best;
  for (final point in points) {
    if (best == null || point.minutes > best.minutes) {
      best = point;
    }
  }
  if (best == null || best.minutes == 0) return null;
  return best;
}

Map<String, int> _buildSubjectMinutes(AppProvider app) {
  const studyCategories = <TimeLogCategory>{
    TimeLogCategory.study,
    TimeLogCategory.revision,
    TimeLogCategory.qbank,
    TimeLogCategory.anki,
    TimeLogCategory.video,
    TimeLogCategory.noteTaking,
  };

  final subjectMinutes = <String, int>{};
  for (final log in app.timeLogs) {
    if (!studyCategories.contains(log.category)) continue;
    final key = log.activity.trim().isNotEmpty ? log.activity.trim() : 'Other';
    subjectMinutes[key] = (subjectMinutes[key] ?? 0) + log.durationMinutes;
  }
  for (final entry in app.studyEntries) {
    final key = entry.taskName.trim().isNotEmpty ? entry.taskName.trim() : 'Other';
    subjectMinutes[key] =
        (subjectMinutes[key] ?? 0) + (entry.durationMinutes ?? 0);
  }
  return subjectMinutes;
}

double _faOverallAverage(List<FAPage> faPages, DateTime today) {
  final readPages = faPages.where((page) => page.status != 'unread').length;
  if (readPages == 0) return 0;

  final readDates = faPages
      .map((page) => page.firstReadAt)
      .whereType<String>()
      .map(DateTime.tryParse)
      .whereType<DateTime>()
      .toList()
    ..sort();
  if (readDates.isEmpty) return 0;

  final firstReadDay = DateTime(
    readDates.first.year,
    readDates.first.month,
    readDates.first.day,
  );
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final totalDays =
      math.max(1, normalizedToday.difference(firstReadDay).inDays + 1);
  return readPages / totalDays;
}

double _faRollingAverage(
  List<FAPage> faPages,
  DateTime today, {
  required int days,
}) {
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final windowStart = normalizedToday.subtract(Duration(days: days - 1));
  var pagesRead = 0;

  for (final page in faPages) {
    final firstReadAt = page.firstReadAt;
    final parsed = firstReadAt == null ? null : DateTime.tryParse(firstReadAt);
    if (parsed == null) continue;
    final normalized = DateTime(parsed.year, parsed.month, parsed.day);
    if (!normalized.isBefore(windowStart) && !normalized.isAfter(normalizedToday)) {
      pagesRead++;
    }
  }

  return pagesRead / days;
}

DateTime? _faEta({
  required int totalPages,
  required int readPages,
  required double pagesPerDay,
  required DateTime today,
}) {
  final remainingPages = math.max(0, totalPages - readPages);
  if (remainingPages == 0) return today;
  if (pagesPerDay <= 0) return null;
  return today.add(Duration(days: (remainingPages / pagesPerDay).ceil()));
}

List<RevisionItem> _dueRevisionItems(AppProvider app, DateTime adjustedToday) {
  final dayEnd = DateTime(
    adjustedToday.year,
    adjustedToday.month,
    adjustedToday.day,
    23,
    59,
    59,
  );
  final dueItems = app.revisionItems.where((item) {
    final due = DateTime.tryParse(item.nextRevisionAt);
    return due != null && !due.isAfter(dayEnd);
  }).toList()
    ..sort((a, b) => a.nextRevisionAt.compareTo(b.nextRevisionAt));
  return dueItems;
}

List<_RevisionQueueSheetItem> _buildRevisionQueueSheetItems(AppProvider app) {
  final items = <_RevisionQueueSheetItem>[
    for (final revision in app.revisionItems)
      _RevisionQueueSheetItem.fromRevisionItem(revision),
  ];

  for (final kb in app.knowledgeBase) {
    if (kb.nextRevisionAt == null || kb.nextRevisionAt!.isEmpty) {
      continue;
    }
    final alreadyTracked = app.revisionItems.any(
      (revision) => revision.id == 'kb-${kb.pageNumber}',
    );
    if (!alreadyTracked) {
      items.add(_RevisionQueueSheetItem.fromKnowledgeBaseEntry(kb));
    }
  }

  return items
      .map((item) => item.copyWith(status: _revisionQueueStatus(item)))
      .where((item) => item.status.isNotEmpty)
      .toList()
    ..sort((a, b) => a.nextRevisionAt.compareTo(b.nextRevisionAt));
}

String _revisionQueueStatus(_RevisionQueueSheetItem item) {
  if (SrsService.isDueNow(nextRevisionAt: item.nextRevisionAt)) {
    return 'Do Now';
  }
  if (SrsService.isDueWithinDays(
    nextRevisionAt: item.nextRevisionAt,
    days: 7,
  )) {
    return 'Upcoming';
  }
  return '';
}

String _revisionDisplayTitle(Object item) {
  if (item is RevisionItem) {
    if (item.source == 'FA' && item.pageNumber.isNotEmpty) {
      return 'FA Page ${item.pageNumber}';
    }
    return item.title.trim().isNotEmpty ? item.title : 'Revision item';
  }
  if (item is _RevisionQueueSheetItem) {
    if (item.source == 'FA' && item.pageNumber.isNotEmpty) {
      return 'FA Page ${item.pageNumber}';
    }
    return item.title.trim().isNotEmpty ? item.title : 'Revision item';
  }
  return 'Revision item';
}

String _revisionDisplaySubtitle(Object item) {
  if (item is RevisionItem) {
    if (item.parentTitle.trim().isNotEmpty) {
      return '${item.parentTitle} • Rev ${item.currentRevisionIndex}';
    }
    return 'Rev ${item.currentRevisionIndex}';
  }
  if (item is _RevisionQueueSheetItem) {
    if (item.parentTitle.trim().isNotEmpty) {
      return '${item.parentTitle} • Rev ${item.currentRevisionIndex}';
    }
    return 'Rev ${item.currentRevisionIndex}';
  }
  return '';
}

List<_GoalProgressData> _buildGoalRows({
  required BuildContext context,
  required int todayPagesRead,
  required int dailyGoal,
  required DayPlan? todayPlan,
  required List<Block> todayBlocks,
  required AppProvider app,
  required String todayStr,
  required int dueRevisionCount,
}) {
  final hasAnkiLog = app.timeLogs.any(
    (log) => log.date == todayStr && log.category == TimeLogCategory.anki,
  );
  final doneAnkiBlock = todayBlocks.any(
    (block) => block.type == BlockType.anki && block.status == BlockStatus.done,
  );
  final currentAnki = (hasAnkiLog || doneAnkiBlock) ? 1 : 0;

  final plannedVideoBlocks =
      todayBlocks.where((block) => block.type == BlockType.video).length;
  final completedVideoBlocks = todayBlocks
      .where((block) =>
          block.type == BlockType.video && block.status == BlockStatus.done)
      .length;
  final videoTarget = plannedVideoBlocks > 0
      ? plannedVideoBlocks
      : (todayPlan?.videos.length ?? 0);

  final plannedRevisionBlocks = todayBlocks
      .where((block) =>
          block.type == BlockType.revisionFa ||
          block.type == BlockType.fmgeRevision)
      .length;
  final completedRevisionBlocks = todayBlocks
      .where((block) =>
          (block.type == BlockType.revisionFa ||
              block.type == BlockType.fmgeRevision) &&
          block.status == BlockStatus.done)
      .length;

  final goals = <_GoalProgressData>[
    _goalData(
      label: 'FA Pages',
      icon: Icons.menu_book_rounded,
      current: todayPagesRead,
      target: dailyGoal,
      color: DashboardColors.primary,
      progressDelay: const Duration(milliseconds: 660),
      onTap: () => context.go('/tracker'),
    ),
    _goalData(
      label: 'Anki',
      icon: Icons.psychology_alt_rounded,
      current: currentAnki,
      target: 1,
      color: DashboardColors.success,
      progressDelay: const Duration(milliseconds: 720),
      onTap: () => context.go('/todays-plan'),
    ),
    _goalData(
      label: 'Sketchy Micro',
      icon: Icons.science_rounded,
      current: completedVideoBlocks,
      target: videoTarget,
      color: DashboardColors.primaryLight,
      progressDelay: const Duration(milliseconds: 780),
      onTap: () => context.go('/todays-plan'),
    ),
    _goalData(
      label: 'Revision',
      icon: Icons.replay_rounded,
      current: plannedRevisionBlocks > 0 ? completedRevisionBlocks : 0,
      target: plannedRevisionBlocks > 0
          ? plannedRevisionBlocks
          : dueRevisionCount,
      color: DashboardColors.warning,
      progressDelay: const Duration(milliseconds: 840),
      onTap: () => context.go('/revision'),
    ),
  ];

  return goals;
}

_GoalProgressData _goalData({
  required String label,
  required IconData icon,
  required int current,
  required int target,
  required Color color,
  required Duration progressDelay,
  VoidCallback? onTap,
}) {
  final done = target > 0 && current >= target;
  final progress =
      target <= 0 ? 0.0 : ((current / target) * 100).clamp(0, 100).toDouble();
  final statusText = target <= 0
      ? 'Not planned'
      : done
          ? 'Done'
          : '$current/$target';

  return _GoalProgressData(
    icon: icon,
    label: label,
    color: color,
    progress: progress,
    statusText: statusText,
    done: done,
    progressDelay: progressDelay,
    onTap: onTap,
  );
}

String _formatHM(int minutes) {
  if (minutes <= 0) return '0m';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (hours == 0) return '${remainingMinutes}m';
  if (remainingMinutes == 0) return '${hours}h';
  return '${hours}h ${remainingMinutes}m';
}

String _formatShortHM(int minutes) {
  if (minutes <= 0) return '0m';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (hours > 0) return '${hours}h';
  return '${remainingMinutes}m';
}

String _formatProjectionDate(DateTime? date) {
  if (date == null) return '--';
  return DateFormat('MMM d').format(date);
}

TextStyle _inter({
  required double size,
  required FontWeight weight,
  required Color color,
  double? letterSpacing,
  FontStyle? fontStyle,
}) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
  );
}
