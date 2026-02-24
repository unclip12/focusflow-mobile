// =============================================================
// CalendarScreen — month view calendar with activity dots.
// Uses table_calendar package. Tap date → bottom sheet with
// that day's blocks, time logs, study plan deadlines.
// Month picker in header via showDatePicker.
// Android rules: resizeToAvoidBottomInset: true (AppScaffold),
//                enableDrag: false, useSafeArea: true on sheets.
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/time_log_entry.dart';
import 'package:focusflow_mobile/models/study_plan_item.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/screens/calendar/calendar_date_marker.dart';
import 'package:focusflow_mobile/screens/calendar/day_activities_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // ── Helpers: date → YYYY-MM-DD ────────────────────────────
  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // ── Data query helpers ────────────────────────────────────
  List<Block> _blocksForDate(AppProvider ap, DateTime day) {
    final key = _dateKey(day);
    final plan = ap.getDayPlan(key);
    return plan?.blocks ?? [];
  }

  List<TimeLogEntry> _timeLogsForDate(AppProvider ap, DateTime day) {
    final key = _dateKey(day);
    return ap.timeLogs.where((t) => t.date == key).toList();
  }

  List<StudyPlanItem> _studyItemsForDate(AppProvider ap, DateTime day) {
    final key = _dateKey(day);
    return ap.studyPlan.where((s) => s.date == key).toList();
  }

  // ── Collect marker types for a date ──────────────────────
  List<CalendarActivityType> _typesForDate(AppProvider ap, DateTime day) {
    final types = <CalendarActivityType>[];
    if (_blocksForDate(ap, day).isNotEmpty) {
      types.add(CalendarActivityType.block);
    }
    if (_timeLogsForDate(ap, day).isNotEmpty) {
      types.add(CalendarActivityType.study);
    }
    if (_studyItemsForDate(ap, day).isNotEmpty) {
      types.add(CalendarActivityType.deadline);
    }
    return types;
  }

  // ── Month picker ─────────────────────────────────────────
  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Select Month',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null && mounted) {
      setState(() {
        _focusedDay = DateTime(picked.year, picked.month, 1);
        _selectedDay = null;
      });
    }
  }

  // ── Show day activities bottom sheet ─────────────────────
  void _showDaySheet(BuildContext context, AppProvider ap, DateTime day) {
    final blocks = _blocksForDate(ap, day);
    final timeLogs = _timeLogsForDate(ap, day);
    final studyItems = _studyItemsForDate(ap, day);

    showModalBottomSheet<void>(
      context: context,
      enableDrag: false,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DayActivitiesSheet(
        date: day,
        blocks: blocks,
        timeLogs: timeLogs,
        studyItems: studyItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppScaffold(
      screenName: 'Calendar',
      body: Column(
        children: [
          // ── Month picker header ──────────────────────────
          _MonthPickerHeader(
            focusedDay: _focusedDay,
            onPickMonth: () => _pickMonth(context),
          ),

          // ── Calendar ────────────────────────────────────
          TableCalendar<Object>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2035),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                _selectedDay != null && isSameDay(day, _selectedDay),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              _showDaySheet(context, ap, selected);
            },
            onPageChanged: (focused) {
              setState(() => _focusedDay = focused);
            },
            headerVisible: false, // We use our own header
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              todayTextStyle: theme.textTheme.bodyMedium!.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
              selectedDecoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: theme.textTheme.bodyMedium!.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.w700,
              ),
              defaultTextStyle: theme.textTheme.bodyMedium!,
              weekendTextStyle: theme.textTheme.bodyMedium!.copyWith(
                color: cs.error.withValues(alpha: 0.75),
              ),
              outsideTextStyle: theme.textTheme.bodySmall!.copyWith(
                color: cs.onSurface.withValues(alpha: 0.25),
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              markersMaxCount: 0, // We handle markers ourselves
              cellMargin: const EdgeInsets.all(4),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: theme.textTheme.labelSmall!.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: theme.textTheme.labelSmall!.copyWith(
                color: cs.error.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              // Custom day cell with activity dots below number
              defaultBuilder: (ctx, day, focusedDay) =>
                  _DayCell(day: day, types: _typesForDate(ap, day)),
              todayBuilder: (ctx, day, focusedDay) =>
                  _DayCell(day: day, types: _typesForDate(ap, day), isToday: true, cs: cs),
              selectedBuilder: (ctx, day, focusedDay) =>
                  _DayCell(day: day, types: _typesForDate(ap, day), isSelected: true, cs: cs),
              outsideBuilder: (ctx, day, focusedDay) =>
                  _DayCell(day: day, types: const [], isOutside: true),
            ),
          ),

          // ── Selected day summary strip ───────────────────
          if (_selectedDay != null) ...[
            const Divider(height: 1),
            _SelectedDaySummary(
              day: _selectedDay!,
              blockCount: _blocksForDate(ap, _selectedDay!).length,
              timeLogCount: _timeLogsForDate(ap, _selectedDay!).length,
              studyCount: _studyItemsForDate(ap, _selectedDay!).length,
              onTap: () => _showDaySheet(context, ap, _selectedDay!),
            ),
          ],

          const Spacer(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MONTH PICKER HEADER
// ═══════════════════════════════════════════════════════════════

class _MonthPickerHeader extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onPickMonth;

  const _MonthPickerHeader({
    required this.focusedDay,
    required this.onPickMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final label = DateFormat('MMMM yyyy').format(focusedDay);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPickMonth,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: cs.primary,
                ),
              ],
            ),
          ),
          const Spacer(),
          // Today button
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.today_rounded, size: 16),
            label: const Text('Today'),
            style: TextButton.styleFrom(
              foregroundColor: cs.primary,
              textStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM DAY CELL
// ═══════════════════════════════════════════════════════════════

class _DayCell extends StatelessWidget {
  final DateTime day;
  final List<CalendarActivityType> types;
  final bool isToday;
  final bool isSelected;
  final bool isOutside;
  final ColorScheme? cs;

  const _DayCell({
    required this.day,
    required this.types,
    this.isToday = false,
    this.isSelected = false,
    this.isOutside = false,
    this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = cs ?? Theme.of(context).colorScheme;

    Color textColor;
    BoxDecoration? decoration;

    if (isSelected) {
      textColor = colorScheme.onPrimary;
      decoration = BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      );
    } else if (isToday) {
      textColor = colorScheme.primary;
      decoration = BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.13),
        shape: BoxShape.circle,
      );
    } else if (isOutside) {
      textColor = colorScheme.onSurface.withValues(alpha: 0.25);
      decoration = null;
    } else {
      textColor = colorScheme.onSurface;
      decoration = null;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: decoration,
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight:
                  (isToday || isSelected) ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 2),
        if (types.isNotEmpty && !isOutside)
          CalendarDateMarker(types: types)
        else
          const SizedBox(height: 5),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SELECTED DAY SUMMARY STRIP
// ═══════════════════════════════════════════════════════════════

class _SelectedDaySummary extends StatelessWidget {
  final DateTime day;
  final int blockCount;
  final int timeLogCount;
  final int studyCount;
  final VoidCallback onTap;

  const _SelectedDaySummary({
    required this.day,
    required this.blockCount,
    required this.timeLogCount,
    required this.studyCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = blockCount + timeLogCount + studyCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: cs.surface,
        child: Row(
          children: [
            Icon(Icons.event_note_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                DateFormat('EEE, d MMM').format(day),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (total == 0)
              Text(
                'No activities',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
              )
            else ...[
              if (blockCount > 0) _StatBadge(count: blockCount, label: 'blocks', color: Colors.blue.shade400),
              if (timeLogCount > 0) _StatBadge(count: timeLogCount, label: 'logs', color: Colors.green.shade400),
              if (studyCount > 0) _StatBadge(count: studyCount, label: 'study', color: Colors.amber.shade600),
            ],
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count $label',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
