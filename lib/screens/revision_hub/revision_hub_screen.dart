// =============================================================
// RevisionHubScreen — unified revision hub showing ALL resources
// Data source: RevisionItem list + KnowledgeBase entries
// Tabs: Due Now | Upcoming (7 days) | All
// Filter chips: All / FA / Sketchy / Pathoma / UWorld / KB
// Sorted by soonest due date first
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/revision_item.dart';
import 'package:focusflow_mobile/models/knowledge_base.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'revision_card.dart';

class RevisionHubScreen extends StatefulWidget {
  const RevisionHubScreen({super.key});

  @override
  State<RevisionHubScreen> createState() => _RevisionHubScreenState();
}

class _RevisionHubScreenState extends State<RevisionHubScreen> {
  String _sourceFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    // ── Build unified list from RevisionItems + KB entries ─────
    final List<RevisionDisplayItem> allItems = [];

    // 1. RevisionItems (FA pages/subtopics, Sketchy, Pathoma, UWorld)
    for (final ri in app.revisionItems) {
      allItems.add(RevisionDisplayItem.fromRevisionItem(ri));
    }

    // 2. KnowledgeBase entries with nextRevisionAt
    for (final kb in app.knowledgeBase) {
      if (kb.nextRevisionAt != null && kb.nextRevisionAt!.isNotEmpty) {
        // Skip if a matching revision item already exists
        final alreadyTracked = app.revisionItems.any(
          (r) => r.id == 'kb-${kb.pageNumber}',
        );
        if (!alreadyTracked) {
          allItems.add(RevisionDisplayItem.fromKBEntry(kb));
        }
      }
    }

    // Apply source filter
    final filtered = _sourceFilter == 'ALL'
        ? allItems
        : allItems.where((i) => i.source == _sourceFilter).toList();

    // Partition into due and upcoming
    final dueItems = <RevisionDisplayItem>[];
    final upcomingItems = <RevisionDisplayItem>[];
    final allSorted = <RevisionDisplayItem>[];

    for (final item in filtered) {
      if (SrsService.isDueNow(nextRevisionAt: item.nextRevisionAt)) {
        dueItems.add(item);
      } else if (SrsService.isDueWithinDays(
          nextRevisionAt: item.nextRevisionAt, days: 7)) {
        upcomingItems.add(item);
      }
      allSorted.add(item);
    }

    // Sort: soonest first
    int sortByDate(RevisionDisplayItem a, RevisionDisplayItem b) {
      final aDate = a.nextRevisionAt;
      final bDate = b.nextRevisionAt;
      return aDate.compareTo(bDate);
    }

    dueItems.sort(sortByDate);
    upcomingItems.sort(sortByDate);
    allSorted.sort(sortByDate);

    final totalDue = dueItems.length;

    return AppScaffold(
      screenName: 'Revision Hub',
      streakCount: 0,
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // ── Due count banner ───────────────────────────────
            if (totalDue > 0)
              _DueCountBanner(count: totalDue),

            // ── Source filter chips ────────────────────────────
            _SourceFilterBar(
              selected: _sourceFilter,
              counts: _countBySources(allItems),
              onSelect: (s) => setState(() => _sourceFilter = s),
            ),

            // ── Tab bar ───────────────────────────────────────
            _StyledTabBar(
              dueCount: dueItems.length,
              upcomingCount: upcomingItems.length,
              allCount: allSorted.length,
            ),

            // ── Tab views ─────────────────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  // DUE tab
                  _buildList(dueItems, 'All caught up!', 'No revisions due right now',
                      Icons.check_circle_outline_rounded),

                  // UPCOMING tab
                  _buildList(upcomingItems, 'Nothing upcoming',
                      'No revisions due in the next 7 days', Icons.calendar_today_rounded),

                  // ALL tab
                  _buildList(allSorted, 'No revisions yet',
                      'Study some content to create revision items', Icons.library_books_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<RevisionDisplayItem> items, String emptyTitle,
      String emptySubtitle, IconData emptyIcon) {
    if (items.isEmpty) {
      return _EmptyTab(icon: emptyIcon, title: emptyTitle, subtitle: emptySubtitle);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) => UnifiedRevisionCard(item: items[i]),
    );
  }

  Map<String, int> _countBySources(List<RevisionDisplayItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.source] = (counts[item.source] ?? 0) + 1;
    }
    return counts;
  }
}

// ── RevisionDisplayItem — unified display model ──────────────────
class RevisionDisplayItem {
  final String id;
  final String type; // PAGE, SUBTOPIC, VIDEO, CHAPTER, UWORLD_Q
  final String source; // FA, SKETCHY_MICRO, SKETCHY_PHARM, PATHOMA, UWORLD, KB
  final String title;
  final String parentTitle;
  final String pageNumber;
  final String nextRevisionAt;
  final int currentRevisionIndex;
  final int totalSteps;
  final String? lastStudiedAt;
  final bool isKBEntry; // true if from KB, false if from RevisionItem

  const RevisionDisplayItem({
    required this.id,
    required this.type,
    required this.source,
    required this.title,
    required this.parentTitle,
    required this.pageNumber,
    required this.nextRevisionAt,
    required this.currentRevisionIndex,
    required this.totalSteps,
    this.lastStudiedAt,
    this.isKBEntry = false,
  });

  factory RevisionDisplayItem.fromRevisionItem(RevisionItem ri) =>
      RevisionDisplayItem(
        id: ri.id,
        type: ri.type,
        source: ri.source,
        title: ri.title,
        parentTitle: ri.parentTitle,
        pageNumber: ri.pageNumber,
        nextRevisionAt: ri.nextRevisionAt,
        currentRevisionIndex: ri.currentRevisionIndex,
        totalSteps: ri.totalSteps,
        lastStudiedAt: ri.lastStudiedAt,
      );

  factory RevisionDisplayItem.fromKBEntry(KnowledgeBaseEntry kb) =>
      RevisionDisplayItem(
        id: 'kb-${kb.pageNumber}',
        type: 'PAGE',
        source: 'KB',
        title: kb.title,
        parentTitle: kb.subject,
        pageNumber: kb.pageNumber,
        nextRevisionAt: kb.nextRevisionAt ?? '',
        currentRevisionIndex: kb.currentRevisionIndex,
        totalSteps: 12,
        lastStudiedAt: kb.lastStudiedAt,
        isKBEntry: true,
      );

  /// Human-readable source label
  String get sourceLabel {
    switch (source) {
      case 'FA': return 'First Aid';
      case 'SKETCHY_MICRO': return 'Sketchy Micro';
      case 'SKETCHY_PHARM': return 'Sketchy Pharm';
      case 'PATHOMA': return 'Pathoma';
      case 'UWORLD': return 'UWorld';
      case 'KB': return 'Knowledge Base';
      default: return source;
    }
  }

  /// Source icon
  IconData get sourceIcon {
    switch (source) {
      case 'FA': return Icons.menu_book_rounded;
      case 'SKETCHY_MICRO': return Icons.biotech_rounded;
      case 'SKETCHY_PHARM': return Icons.medication_rounded;
      case 'PATHOMA': return Icons.science_rounded;
      case 'UWORLD': return Icons.quiz_rounded;
      case 'KB': return Icons.library_books_rounded;
      default: return Icons.book_rounded;
    }
  }

  /// Display title: FA shows page number, others show subtopic/title
  String get displayTitle {
    if (source == 'FA') {
      // Always show page number for FA
      if (pageNumber.isNotEmpty) {
        return 'Pg $pageNumber — $title';
      }
      return title;
    }
    // For Sketchy, Pathoma, UWorld — show the item title (subtopic)
    if (pageNumber.isNotEmpty && pageNumber != title) {
      return '$pageNumber — $title';
    }
    return title;
  }

  /// Source color
  Color get sourceColor {
    switch (source) {
      case 'FA': return const Color(0xFF3B82F6); // blue
      case 'SKETCHY_MICRO': return const Color(0xFF10B981); // green
      case 'SKETCHY_PHARM': return const Color(0xFF8B5CF6); // purple
      case 'PATHOMA': return const Color(0xFFEC4899); // pink
      case 'UWORLD': return const Color(0xFFF59E0B); // amber
      case 'KB': return const Color(0xFF14B8A6); // teal
      default: return const Color(0xFF6B7280);
    }
  }

  /// Due status info
  ({Color color, String label, String timeDetail}) get dueInfo {
    final nextRev = DateTime.tryParse(nextRevisionAt);
    if (nextRev == null) {
      return (color: const Color(0xFF6B7280), label: 'Unknown', timeDetail: '');
    }
    final now = DateTime.now();
    final diff = nextRev.difference(now);

    if (diff.isNegative) {
      final overdue = -diff;
      String label;
      if (overdue.inDays > 0) {
        label = '${overdue.inDays}d overdue';
      } else if (overdue.inHours > 0) {
        label = '${overdue.inHours}h overdue';
      } else {
        label = '${overdue.inMinutes}m overdue';
      }
      return (
        color: const Color(0xFFEF4444),
        label: label,
        timeDetail: DateFormat('MMM d, h:mm a').format(nextRev),
      );
    } else if (diff.inHours < 24) {
      String label;
      if (diff.inHours > 0) {
        label = 'In ${diff.inHours}h';
      } else {
        label = 'In ${diff.inMinutes}m';
      }
      return (
        color: const Color(0xFFF59E0B),
        label: diff.inMinutes < 1 ? 'Due now' : label,
        timeDetail: 'Today at ${DateFormat('h:mm a').format(nextRev)}',
      );
    } else {
      return (
        color: const Color(0xFF10B981),
        label: 'In ${diff.inDays}d',
        timeDetail: DateFormat('MMM d, h:mm a').format(nextRev),
      );
    }
  }
}

// ── Source filter bar ─────────────────────────────────────────────
class _SourceFilterBar extends StatelessWidget {
  final String selected;
  final Map<String, int> counts;
  final ValueChanged<String> onSelect;

  const _SourceFilterBar({
    required this.selected,
    required this.counts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalCount = counts.values.fold(0, (a, b) => a + b);

    final filters = <_FilterDef>[
      _FilterDef('ALL', 'All', totalCount, cs.primary),
      _FilterDef('FA', 'FA', counts['FA'] ?? 0, const Color(0xFF3B82F6)),
      _FilterDef('SKETCHY_MICRO', 'Sketchy M', counts['SKETCHY_MICRO'] ?? 0, const Color(0xFF10B981)),
      _FilterDef('SKETCHY_PHARM', 'Sketchy P', counts['SKETCHY_PHARM'] ?? 0, const Color(0xFF8B5CF6)),
      _FilterDef('PATHOMA', 'Pathoma', counts['PATHOMA'] ?? 0, const Color(0xFFEC4899)),
      _FilterDef('UWORLD', 'UWorld', counts['UWORLD'] ?? 0, const Color(0xFFF59E0B)),
      _FilterDef('KB', 'KB', counts['KB'] ?? 0, const Color(0xFF14B8A6)),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final f = filters[i];
          final isSelected = selected == f.key;
          return GestureDetector(
            onTap: () => onSelect(f.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? f.color.withValues(alpha: 0.15)
                    : cs.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? f.color.withValues(alpha: 0.4)
                      : cs.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? f.color : cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  if (f.count > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? f.color.withValues(alpha: 0.2) : cs.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${f.count}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? f.color : cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterDef {
  final String key;
  final String label;
  final int count;
  final Color color;
  const _FilterDef(this.key, this.label, this.count, this.color);
}

// ── Due count banner ────────────────────────────────────────────
class _DueCountBanner extends StatelessWidget {
  final int count;
  const _DueCountBanner({required this.count});

  @override
  Widget build(BuildContext context) {
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
  final int allCount;

  const _StyledTabBar({required this.dueCount, required this.upcomingCount, required this.allCount});

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
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: [
          _tabWithBadge('Due', dueCount, const Color(0xFFEF4444)),
          _tabWithBadge('Upcoming', upcomingCount, cs.primary),
          _tabWithBadge('All', allCount, cs.onSurface.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _tabWithBadge(String label, int count, Color badgeColor) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: label == 'Due' ? 1.0 : 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: label == 'Due' ? Colors.white : badgeColor,
                ),
              ),
            ),
          ],
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
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.35),
              )),
        ],
      ),
    );
  }
}
