// =============================================================
// TimeLogScreen — shows time logs grouped by date
// Total hours per day header, FAB to add new entry
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/time_log_entry.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/services/haptics_service.dart';
import 'time_log_entry_card.dart';
import 'add_time_log_sheet.dart';

class TimeLogScreen extends StatelessWidget {
  const TimeLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final app = context.watch<AppProvider>();

    // Sort logs by date desc, then startTime desc
    final logs = List<TimeLogEntry>.from(app.timeLogs);
    logs.sort((a, b) {
      final dc = b.date.compareTo(a.date);
      if (dc != 0) return dc;
      return b.startTime.compareTo(a.startTime);
    });

    // Group by date
    final grouped = <String, List<TimeLogEntry>>{};
    for (final log in logs) {
      grouped.putIfAbsent(log.date, () => []).add(log);
    }
    final dates = grouped.keys.toList(); // already sorted desc

    // Streak for scaffold
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final d = now.subtract(Duration(days: i));
      final ds = DateFormat('yyyy-MM-dd').format(d);
      if (logs.any((l) => l.date == ds && l.durationMinutes > 0)) {
        streak++;
      } else {
        if (i == 0) continue;
        break;
      }
    }

    return AppScaffold(
      screenName: 'Time Logger',
      streakCount: streak,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        child: const Icon(Icons.add_rounded),
      ),
      body: logs.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 72 + 24,
              ),
              itemCount: dates.length,
              itemBuilder: (context, i) {
                final date = dates[i];
                final entries = grouped[date]!;
                final totalMins =
                    entries.fold<int>(0, (s, e) => s + e.durationMinutes);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Date header ─────────────────────────────────
                    _DateGroupHeader(dateStr: date, totalMinutes: totalMins),
                    // ── Entries ──────────────────────────────────────
                    ...entries.map((entry) => TimeLogEntryCard(
                          entry: entry,
                          onDelete: () {
                            HapticsService.medium();
                            app.deleteTimeLog(entry.id);
                          },
                        )),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTimeLogSheet(),
    );
  }
}

// ── Date group header ───────────────────────────────────────────
class _DateGroupHeader extends StatelessWidget {
  final String dateStr;
  final int totalMinutes;

  const _DateGroupHeader({required this.dateStr, required this.totalMinutes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final parsed = DateTime.tryParse(dateStr);
    final displayDate =
        parsed != null ? DateFormat('EEE, d MMM').format(parsed) : dateStr;
    final hours = totalMinutes / 60.0;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          Text(
            displayDate,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${hours.toStringAsFixed(1)}h',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cs.primary,
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded,
              size: 48, color: cs.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No time logs yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              )),
          const SizedBox(height: 8),
          Text('Tap + to log your first session',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.35),
              )),
        ],
      ),
    );
  }
}
