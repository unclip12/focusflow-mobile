// =============================================================
// RevisionHubScreen — Premium Revision Command Center
// Liquid glass UI with stats header, search, sort, grouping
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/revision_item.dart';
import 'package:focusflow_mobile/models/knowledge_base.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'revision_card.dart';

class RevisionHubScreen extends StatefulWidget {
  const RevisionHubScreen({super.key});

  @override
  State<RevisionHubScreen> createState() => _RevisionHubScreenState();
}

class _RevisionHubScreenState extends State<RevisionHubScreen>
    with TickerProviderStateMixin {
  String _sourceFilter = 'ALL';
  String _sortBy = 'due_date'; // due_date, source, progress, last_studied
  String _searchQuery = '';
  bool _showSearch = false;
  late final TextEditingController _searchController;
  late final AnimationController _searchAnimController;
  late final Animation<double> _searchAnim;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchAnim = CurvedAnimation(
      parent: _searchAnimController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (_showSearch) {
        _searchAnimController.forward();
      } else {
        _searchAnimController.reverse();
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Build unified list from RevisionItems + KB entries ─────
    final List<RevisionDisplayItem> allItems = [];

    for (final ri in app.revisionItems) {
      allItems.add(RevisionDisplayItem.fromRevisionItem(ri));
    }

    for (final kb in app.knowledgeBase) {
      if (kb.nextRevisionAt != null && kb.nextRevisionAt!.isNotEmpty) {
        final alreadyTracked = app.revisionItems.any(
          (r) => r.id == 'kb-${kb.pageNumber}',
        );
        if (!alreadyTracked) {
          allItems.add(RevisionDisplayItem.fromKBEntry(kb));
        }
      }
    }

    // Apply source filter
    final sourceFiltered = _sourceFilter == 'ALL'
        ? allItems
        : allItems.where((i) => i.source == _sourceFilter).toList();

    // Apply search filter
    final filtered = _searchQuery.isEmpty
        ? sourceFiltered
        : sourceFiltered.where((i) {
            final q = _searchQuery.toLowerCase();
            return i.title.toLowerCase().contains(q) ||
                i.parentTitle.toLowerCase().contains(q) ||
                i.displayTitle.toLowerCase().contains(q);
          }).toList();

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

    // Sort
    final sorter = _getSorter();
    dueItems.sort(sorter);
    upcomingItems.sort(sorter);
    allSorted.sort(sorter);

    // Stats
    final totalDue = allItems
        .where(
            (i) => SrsService.isDueNow(nextRevisionAt: i.nextRevisionAt))
        .length;
    final totalItems = allItems.length;
    final masteryPercent = totalItems > 0
        ? (allItems.fold<int>(0, (s, i) => s + i.currentRevisionIndex) /
                (totalItems * 12) *
                100)
            .round()
        : 0;

    return AppScaffold(
      screenName: '',
      showHeader: false,
      streakCount: 0,
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // ── Safe area top padding ──────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.top + 8),
            ),

            // ── Stats + Controls Row ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3 stat cards
                    Expanded(
                      child: _StatsHeader(
                        totalDue: totalDue,
                        totalItems: totalItems,
                        masteryPercent: masteryPercent,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Vertical search & sort
                    Column(
                      children: [
                        _GlassIconButton(
                          icon: _showSearch
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          onTap: _toggleSearch,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 6),
                        _SortMenuButton(
                          currentSort: _sortBy,
                          isDark: isDark,
                          onChanged: (s) => setState(() => _sortBy = s),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Search Bar (animated) ───────────────────────────
            SliverToBoxAdapter(
              child: SizeTransition(
                sizeFactor: _searchAnim,
                axisAlignment: -1,
                child: _GlassSearchBar(
                  controller: _searchController,
                  isDark: isDark,
                  onChanged: (q) => setState(() => _searchQuery = q),
                ),
              ),
            ),

            // ── Source filter chips ─────────────────────────────
            SliverToBoxAdapter(
              child: _SourceFilterBar(
                selected: _sourceFilter,
                counts: _countBySources(allItems),
                isDark: isDark,
                onSelect: (s) => setState(() => _sourceFilter = s),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 4)),

            // ── Tab bar (pinned so tabs stay visible) ───────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                child: _GlassTabBar(
                  dueCount: dueItems.length,
                  upcomingCount: upcomingItems.length,
                  allCount: allSorted.length,
                  isDark: isDark,
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildList(dueItems, 'All caught up!',
                  'No revisions due right now', Icons.check_circle_outline_rounded, isDark),
              _buildList(upcomingItems, 'Nothing upcoming',
                  'No revisions due in the next 7 days', Icons.event_available_rounded, isDark),
              _buildList(allSorted, 'No revisions yet',
                  'Study some content to create revision items', Icons.library_books_rounded, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Comparator<RevisionDisplayItem> _getSorter() {
    switch (_sortBy) {
      case 'source':
        return (a, b) {
          final cmp = a.source.compareTo(b.source);
          if (cmp != 0) return cmp;
          return a.nextRevisionAt.compareTo(b.nextRevisionAt);
        };
      case 'progress':
        return (a, b) {
          final aP = a.totalSteps > 0
              ? a.currentRevisionIndex / a.totalSteps
              : 0.0;
          final bP = b.totalSteps > 0
              ? b.currentRevisionIndex / b.totalSteps
              : 0.0;
          return bP.compareTo(aP); // highest progress first
        };
      case 'last_studied':
        return (a, b) {
          final aLs = a.lastStudiedAt ?? '';
          final bLs = b.lastStudiedAt ?? '';
          return bLs.compareTo(aLs); // most recently studied first
        };
      default: // due_date
        return (a, b) => a.nextRevisionAt.compareTo(b.nextRevisionAt);
    }
  }

  Widget _buildList(List<RevisionDisplayItem> items, String emptyTitle,
      String emptySubtitle, IconData emptyIcon, bool isDark) {
    if (items.isEmpty) {
      return _EmptyTab(icon: emptyIcon, title: emptyTitle, subtitle: emptySubtitle, isDark: isDark);
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
      itemCount: items.length,
      itemBuilder: (_, i) => UnifiedRevisionCard(
        item: items[i],
        delay: Duration(milliseconds: 40 * i.clamp(0, 10)),
      ),
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
  final String type;
  final String source;
  final String title;
  final String parentTitle;
  final String pageNumber;
  final String nextRevisionAt;
  final int currentRevisionIndex;
  final int totalSteps;
  final String? lastStudiedAt;
  final bool isKBEntry;
  final int hardCount;
  final int effectiveSrsStep;
  final bool easyFlag;
  final int retentionScore;
  final List<RevisionLogEntry> revisionLog;

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
    this.hardCount = 0,
    this.effectiveSrsStep = 0,
    this.easyFlag = true,
    this.retentionScore = 0,
    this.revisionLog = const [],
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
        hardCount: ri.hardCount,
        effectiveSrsStep: ri.effectiveSrsStep,
        easyFlag: ri.easyFlag,
        retentionScore: ri.retentionScore,
        revisionLog: ri.revisionLog,
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
        hardCount: kb.hardCount,
        effectiveSrsStep: kb.effectiveSrsStep,
        easyFlag: kb.easyFlag,
        retentionScore: kb.retentionScore,
        revisionLog: kb.revisionLog,
      );

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

  String get displayTitle {
    if (source == 'FA') {
      if (pageNumber.isNotEmpty) {
        return 'Pg $pageNumber — $title';
      }
      return title;
    }
    if (pageNumber.isNotEmpty && pageNumber != title) {
      return '$pageNumber — $title';
    }
    return title;
  }

  Color get sourceColor {
    switch (source) {
      case 'FA': return const Color(0xFF3B82F6);
      case 'SKETCHY_MICRO': return const Color(0xFF10B981);
      case 'SKETCHY_PHARM': return const Color(0xFF8B5CF6);
      case 'PATHOMA': return const Color(0xFFEC4899);
      case 'UWORLD': return const Color(0xFFF59E0B);
      case 'KB': return const Color(0xFF14B8A6);
      default: return const Color(0xFF6B7280);
    }
  }

  double get progressPercent =>
      totalSteps > 0 ? currentRevisionIndex / totalSteps : 0.0;

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

// ══════════════════════════════════════════════════════════════════
// SLIVER TAB BAR DELEGATE — for pinned tab bar in NestedScrollView
// ══════════════════════════════════════════════════════════════════

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _SliverTabBarDelegate({required this.child});

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) =>
      child != oldDelegate.child;
}

// ══════════════════════════════════════════════════════════════════
// STATS HEADER — three glass stat cards
// ══════════════════════════════════════════════════════════════════

class _StatsHeader extends StatelessWidget {
  final int totalDue;
  final int totalItems;
  final int masteryPercent;
  final bool isDark;

  const _StatsHeader({
    required this.totalDue,
    required this.totalItems,
    required this.masteryPercent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
          Expanded(
            child: _StatCard(
              icon: Icons.warning_amber_rounded,
              iconColor: totalDue > 0
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              label: 'Due Now',
              value: '$totalDue',
              isDark: isDark,
              pulse: totalDue > 0,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.layers_rounded,
              iconColor: DashboardColors.primary,
              label: 'Total',
              value: '$totalItems',
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFF8B5CF6),
              label: 'Mastery',
              value: '$masteryPercent%',
              isDark: isDark,
            ),
          ),
        ],
    );
  }
}

class _StatCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;
  final bool pulse;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
    this.pulse = false,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.pulse) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_StatCard old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.pulse && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glassBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.65);
    final borderCol = widget.isDark
        ? DashboardColors.glassBorderDark
        : DashboardColors.glassBorderLight;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowAlpha = widget.pulse
            ? 0.08 + (_pulseController.value * 0.15)
            : 0.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: glassBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol, width: 0.5),
                boxShadow: widget.pulse
                    ? [
                        BoxShadow(
                          color: widget.iconColor
                              .withValues(alpha: glowAlpha),
                          blurRadius: 16,
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              child: child,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 20, color: widget.iconColor),
          const SizedBox(height: 6),
          Text(
            widget.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary(widget.isDark),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: DashboardColors.textPrimary(widget.isDark)
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// GLASS SEARCH BAR
// ══════════════════════════════════════════════════════════════════

class _GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _GlassSearchBar({
    required this.controller,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final glassBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.65);
    final borderCol = isDark
        ? DashboardColors.glassBorderDark
        : DashboardColors.glassBorderLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: glassBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCol, width: 0.5),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 13,
                color: DashboardColors.textPrimary(isDark),
              ),
              decoration: InputDecoration(
                hintText: 'Search revisions...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: DashboardColors.textPrimary(isDark)
                      .withValues(alpha: 0.35),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: DashboardColors.primary.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// GLASS ICON BUTTON
// ══════════════════════════════════════════════════════════════════

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? DashboardColors.glassBorderDark
                : DashboardColors.glassBorderLight,
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: DashboardColors.primary,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SORT MENU BUTTON
// ══════════════════════════════════════════════════════════════════

class _SortMenuButton extends StatelessWidget {
  final String currentSort;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _SortMenuButton({
    required this.currentSort,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? const Color(0xFF1C1C2E) : const Color(0xFFF5F3FF),
      itemBuilder: (_) => [
        _buildItem('due_date', 'Due Date', Icons.schedule_rounded),
        _buildItem('source', 'Source', Icons.category_rounded),
        _buildItem('progress', 'Progress', Icons.trending_up_rounded),
        _buildItem('last_studied', 'Last Studied', Icons.history_rounded),
      ],
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? DashboardColors.glassBorderDark
                : DashboardColors.glassBorderLight,
            width: 0.5,
          ),
        ),
        child: Icon(
          Icons.sort_rounded,
          size: 16,
          color: DashboardColors.primary,
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildItem(
      String value, String label, IconData icon) {
    final isSelected = currentSort == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: isSelected
                  ? DashboardColors.primary
                  : DashboardColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? DashboardColors.primary
                  : DashboardColors.textSecondary,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check_rounded,
                size: 14, color: DashboardColors.primary),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SOURCE FILTER BAR — liquid glass chips
// ══════════════════════════════════════════════════════════════════

class _SourceFilterBar extends StatelessWidget {
  final String selected;
  final Map<String, int> counts;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const _SourceFilterBar({
    required this.selected,
    required this.counts,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = counts.values.fold(0, (a, b) => a + b);

    final filters = <_FilterDef>[
      _FilterDef('ALL', 'All', totalCount, DashboardColors.primary, Icons.dashboard_rounded),
      _FilterDef('FA', 'FA', counts['FA'] ?? 0, const Color(0xFF3B82F6), Icons.menu_book_rounded),
      _FilterDef('SKETCHY_MICRO', 'Sketchy M', counts['SKETCHY_MICRO'] ?? 0, const Color(0xFF10B981), Icons.biotech_rounded),
      _FilterDef('SKETCHY_PHARM', 'Sketchy P', counts['SKETCHY_PHARM'] ?? 0, const Color(0xFF8B5CF6), Icons.medication_rounded),
      _FilterDef('PATHOMA', 'Pathoma', counts['PATHOMA'] ?? 0, const Color(0xFFEC4899), Icons.science_rounded),
      _FilterDef('UWORLD', 'UWorld', counts['UWORLD'] ?? 0, const Color(0xFFF59E0B), Icons.quiz_rounded),
      _FilterDef('KB', 'KB', counts['KB'] ?? 0, const Color(0xFF14B8A6), Icons.library_books_rounded),
    ];

    return SizedBox(
      height: 38,
      child: ShaderMask(
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: const [0, 0.02, 0.95, 1],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
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
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? f.color.withValues(alpha: isDark ? 0.18 : 0.12)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? f.color.withValues(alpha: 0.45)
                        : isDark
                            ? DashboardColors.glassBorderDark.withValues(alpha: 0.3)
                            : DashboardColors.glassBorderLight.withValues(alpha: 0.4),
                    width: isSelected ? 1 : 0.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: f.color.withValues(alpha: 0.15),
                            blurRadius: 10,
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Colored dot
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 6 : 4,
                      height: isSelected ? 6 : 4,
                      decoration: BoxDecoration(
                        color: f.color,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: f.color.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      f.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? f.color
                            : DashboardColors.textPrimary(isDark)
                                .withValues(alpha: 0.5),
                      ),
                    ),
                    if (f.count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? f.color.withValues(alpha: 0.2)
                              : DashboardColors.textPrimary(isDark)
                                  .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${f.count}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? f.color
                                : DashboardColors.textPrimary(isDark)
                                    .withValues(alpha: 0.4),
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
      ),
    );
  }
}

class _FilterDef {
  final String key;
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _FilterDef(this.key, this.label, this.count, this.color, this.icon);
}

// ══════════════════════════════════════════════════════════════════
// GLASS TAB BAR — frosted glass with gradient indicator
// ══════════════════════════════════════════════════════════════════

class _GlassTabBar extends StatelessWidget {
  final int dueCount;
  final int upcomingCount;
  final int allCount;
  final bool isDark;

  const _GlassTabBar({
    required this.dueCount,
    required this.upcomingCount,
    required this.allCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? DashboardColors.glassBorderDark.withValues(alpha: 0.3)
                    : DashboardColors.glassBorderLight.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DashboardColors.primary.withValues(alpha: isDark ? 0.2 : 0.15),
                    DashboardColors.primaryViolet.withValues(alpha: isDark ? 0.15 : 0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DashboardColors.primary.withValues(alpha: 0.25),
                  width: 0.5,
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: DashboardColors.primary,
              unselectedLabelColor: DashboardColors.textPrimary(isDark)
                  .withValues(alpha: 0.4),
              labelStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
              splashBorderRadius: BorderRadius.circular(12),
              tabs: [
                _tabWithBadge('Due', dueCount, const Color(0xFFEF4444)),
                _tabWithBadge(
                    'Upcoming', upcomingCount, DashboardColors.primary),
                _tabWithBadge('All', allCount,
                    DashboardColors.textPrimary(isDark).withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabWithBadge(String label, int count, Color badgeColor) {
    return Tab(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: badgeColor != const Color(0xFFEF4444)
                    ? badgeColor.withValues(alpha: 0.25)
                    : badgeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: badgeColor == const Color(0xFFEF4444)
                      ? Colors.white
                      : badgeColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// EMPTY TAB STATE — premium animated empty state
// ══════════════════════════════════════════════════════════════════

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glowing icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  DashboardColors.primary.withValues(alpha: isDark ? 0.15 : 0.10),
                  Colors.transparent,
                ],
                radius: 0.8,
              ),
            ),
            child: Icon(
              icon,
              size: 48,
              color: DashboardColors.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: DashboardColors.textPrimary(isDark).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: DashboardColors.textPrimary(isDark).withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
