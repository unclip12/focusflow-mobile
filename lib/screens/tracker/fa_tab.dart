// =============================================================
// FA Tab — Premium redesigned First Aid 2025 tab
// Pages grid | Topics list | Cards view
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/models/fa_subtopic.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/screens/library/fa_item_detail_sheet.dart';
import 'package:focusflow_mobile/screens/revision_hub/revision_confidence_sheet.dart';
import 'package:focusflow_mobile/screens/tracker/tracker_sheets.dart';

class FATab extends StatefulWidget {
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;
  final String searchQuery;
  final String statusFilter;
  final String sortBy;

  const FATab({
    super.key,
    required this.selectionMode,
    required this.selectedItems,
    required this.onToggleSelect,
    this.searchQuery = '',
    this.statusFilter = 'all',
    this.sortBy = 'page_order',
  });

  @override
  State<FATab> createState() => _FATabState();
}

class _FATabState extends State<FATab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        if (app.faPages.isEmpty) {
          return _EmptyState(
            icon: Icons.menu_book_rounded,
            title: 'No FA pages loaded',
            subtitle: 'Import your First Aid 2025 data to get started',
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Sort by orderIndex for FA book order
        var sorted = List<FAPage>.from(app.faPages)
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

        // Apply search filter
        if (widget.searchQuery.isNotEmpty) {
          final q = widget.searchQuery.toLowerCase();
          sorted = sorted.where((p) {
            return p.pageNum.toString().contains(q) ||
                p.title.toLowerCase().contains(q) ||
                p.subject.toLowerCase().contains(q) ||
                p.system.toLowerCase().contains(q);
          }).toList();
        }

        // Apply status filter
        if (widget.statusFilter != 'all') {
          switch (widget.statusFilter) {
            case 'unread':
              sorted = sorted.where((p) => p.status == 'unread').toList();
              break;
            case 'read':
              sorted = sorted.where((p) => p.status == 'read').toList();
              break;
            case 'anki_done':
              sorted = sorted.where((p) => p.status == 'anki_done').toList();
              break;
            case 'has_revision':
              sorted = sorted.where((p) => p.revisionCount > 0).toList();
              break;
          }
        }

        // Apply sort
        switch (widget.sortBy) {
          case 'status':
            sorted.sort((a, b) {
              const order = {'unread': 0, 'read': 1, 'anki_done': 2};
              return (order[a.status] ?? 0).compareTo(order[b.status] ?? 0);
            });
            break;
          case 'subject':
            sorted.sort((a, b) => a.subject.compareTo(b.subject));
            break;
          case 'last_revised':
            sorted.sort((a, b) =>
                (b.lastRevisedAt ?? '').compareTo(a.lastRevisedAt ?? ''));
            break;
          case 'revision_count':
            sorted.sort((a, b) => b.revisionCount.compareTo(a.revisionCount));
            break;
        }

        final readCount = app.faPages.where((p) => p.status != 'unread').length;
        final totalPages = app.faPages.length;
        final ankiCount =
            app.faPages.where((p) => p.status == 'anki_done').length;

        return Column(
          children: [
            // ── Progress + view toggle ─────────────────────
            _FAProgressHeader(
              readCount: readCount,
              ankiCount: ankiCount,
              totalPages: totalPages,
              faViewMode: app.faViewMode,
              onModeChanged: (m) => app.saveFAViewMode(m),
              isDark: isDark,
            ),

            // ── Content ────────────────────────────────────
            Expanded(
              child: app.faViewMode == 'topics'
                  ? _SubtopicListView(
                      app: app,
                      searchQuery: widget.searchQuery,
                      isDark: isDark,
                    )
                  : app.faViewMode == 'cards'
                      ? _FACardView(
                          app: app,
                          sorted: sorted,
                          selectionMode: widget.selectionMode,
                          selectedItems: widget.selectedItems,
                          onToggleSelect: widget.onToggleSelect,
                          isDark: isDark,
                        )
                      : _PageGridView(
                          app: app,
                          sorted: sorted,
                          selectionMode: widget.selectionMode,
                          selectedItems: widget.selectedItems,
                          onToggleSelect: widget.onToggleSelect,
                          isDark: isDark,
                        ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FA Progress Header — glass card with progress ring + view toggle
// ═══════════════════════════════════════════════════════════════

class _FAProgressHeader extends StatelessWidget {
  final int readCount;
  final int ankiCount;
  final int totalPages;
  final String faViewMode;
  final ValueChanged<String> onModeChanged;
  final bool isDark;

  const _FAProgressHeader({
    required this.readCount,
    required this.ankiCount,
    required this.totalPages,
    required this.faViewMode,
    required this.onModeChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalPages > 0 ? readCount / totalPages : 0.0;
    final textColor = DashboardColors.textPrimary(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DashboardColors.glassBorder(isDark),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // Progress ring
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          strokeCap: StrokeCap.round,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : DashboardColors.primary.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            DashboardColors.success,
                          ),
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$readCount / $totalPages pages',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$ankiCount Anki done • ${totalPages - readCount} remaining',
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // View mode toggle
                _GlassViewToggle(
                  mode: faViewMode,
                  onChanged: onModeChanged,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glass View Mode Toggle ────────────────────────────────────

class _GlassViewToggle extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _GlassViewToggle({
    required this.mode,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DashboardColors.glassBorder(isDark),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _viewBtn(Icons.grid_view_rounded, 'pages', 'Pages'),
          _viewBtn(Icons.list_rounded, 'topics', 'Topics'),
          _viewBtn(Icons.view_agenda_rounded, 'cards', 'Cards'),
        ],
      ),
    );
  }

  Widget _viewBtn(IconData icon, String value, String tooltip) {
    final isActive = mode == value;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? DashboardColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive
                ? DashboardColors.primary
                : DashboardColors.textPrimary(isDark).withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Page Grid View — premium liquid-fill page boxes
// ═══════════════════════════════════════════════════════════════

class _PageGridView extends StatelessWidget {
  final AppProvider app;
  final List<FAPage> sorted;
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;
  final bool isDark;

  const _PageGridView({
    required this.app,
    required this.sorted,
    required this.selectionMode,
    required this.selectedItems,
    required this.onToggleSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Group by subject
    final groupOrder = <String>[];
    final grouped = <String, List<FAPage>>{};
    for (final p in sorted) {
      if (!grouped.containsKey(p.subject)) {
        groupOrder.add(p.subject);
        grouped[p.subject] = [];
      }
      grouped[p.subject]!.add(p);
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 72 + 24,
      ),
      itemCount: groupOrder.length,
      itemBuilder: (context, i) {
        final subject = groupOrder[i];
        final pages = grouped[subject]!;
        final readCount = pages.where((p) => p.status != 'unread').length;
        final subProgress = pages.isNotEmpty ? readCount / pages.length : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject header — glass card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? DashboardColors.primary.withValues(alpha: 0.08)
                          : DashboardColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            DashboardColors.primary.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: DashboardColors.verticalAccentGradient(),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            subject,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: DashboardColors.textPrimary(isDark),
                            ),
                          ),
                        ),
                        // Mini progress
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            value: subProgress,
                            strokeWidth: 3,
                            strokeCap: StrokeCap.round,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : DashboardColors.primary
                                    .withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              readCount == pages.length
                                  ? DashboardColors.success
                                  : DashboardColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$readCount/${pages.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DashboardColors.textPrimary(isDark)
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Page boxes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: pages.map((page) {
                  return RepaintBoundary(
                    child: _LiquidFillPageBox(
                      page: page,
                      app: app,
                      selectionMode: selectionMode,
                      isSelected:
                          selectedItems.contains('fa:${page.pageNum}'),
                      onToggleSelect: () =>
                          onToggleSelect('fa:${page.pageNum}'),
                      isDark: isDark,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Liquid Fill Page Box ──────────────────────────────────────

class _LiquidFillPageBox extends StatelessWidget {
  final FAPage page;
  final AppProvider app;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final bool isDark;

  const _LiquidFillPageBox({
    required this.page,
    required this.app,
    required this.selectionMode,
    required this.isSelected,
    required this.onToggleSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final percent = app.getPageCompletionPercent(page.pageNum);
    final isFullyRead = page.status != 'unread';
    final isAnkiDone = page.status == 'anki_done';

    // Premium color palette
    Color accentColor;
    Color textColor;
    Color boxBg;

    if (isAnkiDone) {
      accentColor = DashboardColors.primaryViolet;
      textColor = Colors.white;
      boxBg = DashboardColors.primaryViolet;
    } else if (percent >= 1.0 || isFullyRead) {
      accentColor = DashboardColors.success;
      textColor = Colors.white;
      boxBg = DashboardColors.success;
    } else if (percent > 0) {
      accentColor = DashboardColors.success;
      textColor = DashboardColors.textPrimary(isDark);
      boxBg = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.7);
    } else {
      accentColor = DashboardColors.danger;
      textColor = isDark ? Colors.white : DashboardColors.danger;
      boxBg = isDark
          ? DashboardColors.danger.withValues(alpha: 0.15)
          : DashboardColors.danger.withValues(alpha: 0.08);
    }

    const boxSize = 56.0;

    return GestureDetector(
      onTap:
          selectionMode ? onToggleSelect : () => _showSubtopicPicker(context),
      onLongPress: selectionMode ? null : () => _showFADetailSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: boxSize,
        height: boxSize,
        child: Stack(
          children: [
            // Background box with glass effect
            Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: percent > 0 && percent < 1.0 ? boxBg : boxBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: percent >= 1.0 || isFullyRead
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.25),
                          blurRadius: 10,
                          spreadRadius: -1,
                        ),
                      ]
                    : null,
              ),
            ),

            // Liquid fill animation (bottom-to-top)
            if (percent > 0 && percent < 1.0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    height: boxSize * percent,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          DashboardColors.success,
                          DashboardColors.success.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Page number text
            Center(
              child: Text(
                '${page.pageNum}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: percent > 0 && percent < 1.0
                      ? DashboardColors.textPrimary(isDark)
                      : textColor,
                ),
              ),
            ),

            // Revision badge — premium circular
            if (page.revisionCount > 0)
              Positioned(
                top: 1,
                right: 1,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        DashboardColors.primary,
                        DashboardColors.primaryViolet,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DashboardColors.primary.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'R${page.revisionCount}',
                      style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),

            // Anki done tick
            if (isAnkiDone)
              Positioned(
                bottom: 2,
                right: 2,
                child: Icon(Icons.check_circle_rounded,
                    size: 14, color: Colors.white.withValues(alpha: 0.9)),
              ),

            // Selection overlay
            if (selectionMode)
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? DashboardColors.primary.withValues(alpha: 0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: DashboardColors.primary, width: 2.5)
                        : null,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(Icons.check_circle_rounded,
                              size: 22, color: Colors.white),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSubtopicPicker(BuildContext context) {
    final subtopics = app.getSubtopicsForPage(page.pageNum);
    if (subtopics.isEmpty) {
      _cyclePageStatus(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SubtopicPickerSheet(
        pageNum: page.pageNum,
        page: page,
        app: app,
      ),
    );
  }

  void _cyclePageStatus(BuildContext context) {
    if (page.status == 'anki_done') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Mark as Unread?'),
          content:
              const Text('This will clear the read history for this page.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                app.updateFAPageStatus(page.pageNum, 'unread');
              },
              child: const Text('Mark Unread'),
            ),
          ],
        ),
      );
    } else if (page.status == 'read') {
      app.updateFAPageStatus(page.pageNum, 'anki_done');
    } else {
      app.updateFAPageStatus(page.pageNum, 'read');
    }
  }

  void _showFADetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FAPageDetailSheet(
        app: app,
        pageNum: page.pageNum,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Subtopic List View — premium styled
// ═══════════════════════════════════════════════════════════════

class _SubtopicListView extends StatelessWidget {
  final AppProvider app;
  final String searchQuery;
  final bool isDark;

  const _SubtopicListView({
    required this.app,
    required this.searchQuery,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    var subtopics = List<FASubtopic>.from(app.faSubtopics);
    if (subtopics.isEmpty) {
      return _EmptyState(
        icon: Icons.topic_rounded,
        title: 'No subtopics loaded',
        subtitle: 'Subtopics will appear once pages are imported',
      );
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      subtopics = subtopics
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.pageNum.toString().contains(q))
          .toList();
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 72 + 24,
      ),
      itemCount: subtopics.length,
      itemBuilder: (context, i) {
        final st = subtopics[i];
        Color statusColor;
        String statusLabel;
        switch (st.status) {
          case 'read':
            statusColor = DashboardColors.success;
            statusLabel = 'Read ✓';
            break;
          case 'anki_done':
            statusColor = DashboardColors.primaryViolet;
            statusLabel = 'Anki ✓';
            break;
          default:
            statusColor = DashboardColors.danger;
            statusLabel = 'Unread';
        }

        return Slidable(
          key: ValueKey('st_${st.id}'),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: twoActionPaneExtentRatio,
            children: [
              if (st.status != 'unread')
                SlidableAction(
                  onPressed: (_) => app.undoFASubtopic(st.id!),
                  backgroundColor: DashboardColors.warning,
                  foregroundColor: Colors.white,
                  icon: Icons.undo_rounded,
                  label: 'Undo',
                ),
              SlidableAction(
                onPressed: (_) => app.resetFASubtopic(st.id!),
                backgroundColor: DashboardColors.danger,
                foregroundColor: Colors.white,
                icon: Icons.restart_alt_rounded,
                label: 'Reset',
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DashboardColors.glassBorder(isDark),
                width: 0.5,
              ),
            ),
            child: ListTile(
              dense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              title: Text(
                st.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: DashboardColors.textPrimary(isDark),
                ),
              ),
              subtitle: Text(
                'Page ${st.pageNum}',
                style: TextStyle(
                  fontSize: 11,
                  color: DashboardColors.textPrimary(isDark)
                      .withValues(alpha: 0.5),
                ),
              ),
              trailing: InkWell(
                onTap: () {
                  if (st.status == 'unread') {
                    app.advanceFASubtopicRevision(st.id!);
                  } else {
                    final subRevId = 'fa-sub-${st.pageNum}-${st.id}';
                    final pageRevId = 'fa-page-${st.pageNum}';
                    final hasSubRev =
                        app.revisionItems.any((r) => r.id == subRevId);
                    final revId = hasSubRev ? subRevId : pageRevId;
                    final hasRev =
                        app.revisionItems.any((r) => r.id == revId);
                    if (hasRev) {
                      showRevisionConfidenceSheet(
                        context: context,
                        revisionItemId: revId,
                        title: '${st.name} (p.${st.pageNum})',
                        source: 'FA',
                      );
                    } else {
                      app.advanceFASubtopicRevision(st.id!);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => FAPageDetailSheet(
                    app: app,
                    pageNum: st.pageNum,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FA Card View — premium detailed cards
// ═══════════════════════════════════════════════════════════════

class _FACardView extends StatelessWidget {
  final AppProvider app;
  final List<FAPage> sorted;
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;
  final bool isDark;

  const _FACardView({
    required this.app,
    required this.sorted,
    required this.selectionMode,
    required this.selectedItems,
    required this.onToggleSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Group by subject
    final groupOrder = <String>[];
    final grouped = <String, List<FAPage>>{};
    for (final p in sorted) {
      if (!grouped.containsKey(p.subject)) {
        groupOrder.add(p.subject);
        grouped[p.subject] = [];
      }
      grouped[p.subject]!.add(p);
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 72 + 24,
      ),
      itemCount: groupOrder.length,
      itemBuilder: (context, i) {
        final subject = groupOrder[i];
        final pages = grouped[subject]!;
        final readCount = pages.where((p) => p.status != 'unread').length;
        final subProgress = pages.isNotEmpty ? readCount / pages.length : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: DashboardColors.verticalAccentGradient(),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subject,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DashboardColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: subProgress,
                      strokeWidth: 2.5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : DashboardColors.primary.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          DashboardColors.success),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$readCount/${pages.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DashboardColors.textPrimary(isDark)
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            // Cards
            ...pages.map((page) => _buildCard(context, page)),
          ],
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, FAPage page) {
    final percent = app.getPageCompletionPercent(page.pageNum);
    final isFullyRead = page.status != 'unread';
    final isAnkiDone = page.status == 'anki_done';
    final subtopics = app.getSubtopicsForPage(page.pageNum);
    final readSubs = subtopics.where((s) => s.status != 'unread').length;
    final key = 'fa:${page.pageNum}';
    final isSelected = selectedItems.contains(key);

    Color statusColor;
    String statusLabel;
    if (isAnkiDone) {
      statusColor = DashboardColors.primaryViolet;
      statusLabel = 'Anki Done';
    } else if (isFullyRead || percent >= 1.0) {
      statusColor = DashboardColors.success;
      statusLabel = 'Read';
    } else if (percent > 0) {
      statusColor = DashboardColors.warning;
      statusLabel = '${(percent * 100).round()}%';
    } else {
      statusColor = DashboardColors.danger;
      statusLabel = 'Unread';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Slidable(
        key: ValueKey(page.pageNum),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: twoActionPaneExtentRatio,
          children: [
            if (page.status != 'unread')
              SlidableAction(
                onPressed: (_) => app.undoFAPage(page.pageNum),
                backgroundColor: DashboardColors.warning,
                foregroundColor: Colors.white,
                icon: Icons.undo_rounded,
                label: 'Undo',
                borderRadius: BorderRadius.circular(14),
              ),
            SlidableAction(
              onPressed: (_) => app.resetFAPage(page.pageNum),
              backgroundColor: DashboardColors.danger,
              foregroundColor: Colors.white,
              icon: Icons.restart_alt_rounded,
              label: 'Reset',
              borderRadius: BorderRadius.circular(14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Material(
              color: isSelected
                  ? DashboardColors.primary.withValues(alpha: 0.08)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: selectionMode
                    ? () => onToggleSelect(key)
                    : () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20)),
                          ),
                          builder: (_) => FAPageDetailSheet(
                            app: app,
                            pageNum: page.pageNum,
                          ),
                        );
                      },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? DashboardColors.primary
                          : DashboardColors.glassBorder(isDark),
                      width: isSelected ? 2 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (selectionMode) ...[
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected
                              ? DashboardColors.primary
                              : DashboardColors.textPrimary(isDark)
                                  .withValues(alpha: 0.4),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                      ],
                      // Page number badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              statusColor.withValues(alpha: 0.15),
                              statusColor.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Text(
                            '${page.pageNum}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              page.customTitle ?? page.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: DashboardColors.textPrimary(isDark),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  '${page.system} • $readSubs/${subtopics.length} subtopics',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: DashboardColors.textPrimary(isDark)
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                if (page.lastRevisedAt != null) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.history_rounded,
                                    size: 10,
                                    color: DashboardColors.textPrimary(isDark)
                                        .withValues(alpha: 0.35),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    _formatTimeAgo(page.lastRevisedAt!),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: DashboardColors.textPrimary(isDark)
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status badge
                      InkWell(
                        onTap: selectionMode
                            ? null
                            : () {
                                if (page.status == 'unread') {
                                  app.advanceFAPageRevision(page.pageNum);
                                } else {
                                  final revId = 'fa-page-${page.pageNum}';
                                  final hasRev = app.revisionItems
                                      .any((r) => r.id == revId);
                                  if (hasRev) {
                                    showRevisionConfidenceSheet(
                                      context: context,
                                      revisionItemId: revId,
                                      title:
                                          '${page.title} (p.${page.pageNum})',
                                      source: 'FA',
                                    );
                                  } else {
                                    app.advanceFAPageRevision(page.pageNum);
                                  }
                                }
                              },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),
                      if (page.revisionCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                DashboardColors.primary,
                                DashboardColors.primaryViolet,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: DashboardColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                spreadRadius: -1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'R${page.revisionCount}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (_) {
      return '';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Empty State — premium styled
// ═══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 56,
            color: DashboardColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DashboardColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: DashboardColors.textPrimary(isDark).withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
