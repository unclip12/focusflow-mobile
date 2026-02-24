// =============================================================
// RevisionHubScreen — shows KB entries due for revision
// 2 tabs: DUE (overdue now) and UPCOMING (due within 7 days)
// Header shows total due count badge
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/knowledge_base.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'revision_card.dart';

class RevisionHubScreen extends StatelessWidget {
  const RevisionHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final now = DateTime.now();

    // Partition KB entries into due and upcoming
    final allEntries = app.knowledgeBase;
    final dueEntries = <KnowledgeBaseEntry>[];
    final upcomingEntries = <KnowledgeBaseEntry>[];

    for (final entry in allEntries) {
      if (SrsService.isDueNow(nextRevisionAt: entry.nextRevisionAt)) {
        dueEntries.add(entry);
      } else if (SrsService.isDueWithinDays(
          nextRevisionAt: entry.nextRevisionAt, days: 7)) {
        upcomingEntries.add(entry);
      }
    }

    // Sort due: most overdue first
    dueEntries.sort((a, b) {
      final aDate = a.nextRevisionAt ?? '';
      final bDate = b.nextRevisionAt ?? '';
      return aDate.compareTo(bDate);
    });

    // Sort upcoming: soonest first
    upcomingEntries.sort((a, b) {
      final aDate = a.nextRevisionAt ?? '';
      final bDate = b.nextRevisionAt ?? '';
      return aDate.compareTo(bDate);
    });

    final totalDue = dueEntries.length;

    return AppScaffold(
      screenName: 'Revision Hub',
      streakCount: 0,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // ── Due count header ──────────────────────────────────
            if (totalDue > 0)
              _DueCountBanner(count: totalDue),

            // ── Tab bar ───────────────────────────────────────────
            _StyledTabBar(
              dueCount: dueEntries.length,
              upcomingCount: upcomingEntries.length,
            ),

            // ── Tab views ─────────────────────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  // DUE tab
                  dueEntries.isEmpty
                      ? _EmptyTab(
                          icon: Icons.check_circle_outline_rounded,
                          title: 'All caught up!',
                          subtitle: 'No revisions due right now',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: dueEntries.length,
                          itemBuilder: (_, i) =>
                              RevisionCard(entry: dueEntries[i]),
                        ),

                  // UPCOMING tab
                  upcomingEntries.isEmpty
                      ? _EmptyTab(
                          icon: Icons.calendar_today_rounded,
                          title: 'Nothing upcoming',
                          subtitle: 'No revisions due in the next 7 days',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: upcomingEntries.length,
                          itemBuilder: (_, i) =>
                              RevisionCard(entry: upcomingEntries[i]),
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

// ── Due count banner ────────────────────────────────────────────
class _DueCountBanner extends StatelessWidget {
  final int count;
  const _DueCountBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count revision${count == 1 ? '' : 's'} due now',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Styled tab bar ──────────────────────────────────────────────
class _StyledTabBar extends StatelessWidget {
  final int dueCount;
  final int upcomingCount;

  const _StyledTabBar({required this.dueCount, required this.upcomingCount});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurface.withValues(alpha: 0.45),
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Due'),
                if (dueCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$dueCount',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Upcoming'),
                if (upcomingCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$upcomingCount',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cs.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty tab state ─────────────────────────────────────────────
class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: cs.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              )),
          const SizedBox(height: 8),
          Text(subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.35),
              )),
        ],
      ),
    );
  }
}
