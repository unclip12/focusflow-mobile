// =============================================================
// Sketchy Tab — Premium redesigned Sketchy videos tab
// Micro | Pharm sub-tabs with glass expansion tiles
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/sketchy_video.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/screens/library/library_item_detail_sheet.dart';
import 'package:focusflow_mobile/screens/revision_hub/revision_confidence_sheet.dart';
import 'package:focusflow_mobile/screens/tracker/tracker_sheets.dart';

class SketchyTab extends StatefulWidget {
  final AppProvider app;
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;
  final String searchQuery;

  const SketchyTab({
    super.key,
    required this.app,
    required this.selectionMode,
    required this.selectedItems,
    required this.onToggleSelect,
    this.searchQuery = '',
  });

  @override
  State<SketchyTab> createState() => _SketchyTabState();
}

class _SketchyTabState extends State<SketchyTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allVideos = [
      ...widget.app.sketchyMicroVideos,
      ...widget.app.sketchyPharmVideos,
    ];
    final watchedCount = allVideos.where((v) => v.watched).length;
    final totalCount = allVideos.length;

    if (totalCount == 0) {
      return _SketchyEmptyState();
    }

    return Column(
      children: [
        // ── Progress header ─────────────────────────────
        _SketchyProgressHeader(
          watchedCount: watchedCount,
          totalCount: totalCount,
          isDark: isDark,
        ),

        // ── Sub-tab bar ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
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
                child: TabBar(
                  controller: _subTabController,
                  tabs: [
                    Tab(
                        text:
                            'Micro (${widget.app.sketchyMicroVideos.length})'),
                    Tab(
                        text:
                            'Pharm (${widget.app.sketchyPharmVideos.length})'),
                  ],
                  labelColor: DashboardColors.primary,
                  unselectedLabelColor:
                      DashboardColors.textPrimary(isDark).withValues(alpha: 0.5),
                  indicatorColor: DashboardColors.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Video lists ─────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _SketchyVideoList(
                videos: widget.app.sketchyMicroVideos,
                app: widget.app,
                selectionMode: widget.selectionMode,
                selectedItems: widget.selectedItems,
                onToggleSelect: widget.onToggleSelect,
                searchQuery: widget.searchQuery,
                isDark: isDark,
              ),
              _SketchyVideoList(
                videos: widget.app.sketchyPharmVideos,
                app: widget.app,
                selectionMode: widget.selectionMode,
                selectedItems: widget.selectedItems,
                onToggleSelect: widget.onToggleSelect,
                searchQuery: widget.searchQuery,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Progress header ────────────────────────────────────────────

class _SketchyProgressHeader extends StatelessWidget {
  final int watchedCount;
  final int totalCount;
  final bool isDark;

  const _SketchyProgressHeader({
    required this.watchedCount,
    required this.totalCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? watchedCount / totalCount : 0.0;
    final textColor = DashboardColors.textPrimary(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                  width: 42,
                  height: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          strokeCap: StrokeCap.round,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFF10B981).withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF10B981),
                          ),
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$watchedCount / $totalCount videos',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${totalCount - watchedCount} remaining',
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_circle_rounded,
                  size: 32,
                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Video list grouped by category ────────────────────────────

class _SketchyVideoList extends StatelessWidget {
  final List<SketchyVideo> videos;
  final AppProvider app;
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;
  final String searchQuery;
  final bool isDark;

  const _SketchyVideoList({
    required this.videos,
    required this.app,
    required this.selectionMode,
    required this.selectedItems,
    required this.onToggleSelect,
    required this.searchQuery,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    var filtered = List<SketchyVideo>.from(videos);
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered
          .where((v) =>
              v.title.toLowerCase().contains(q) ||
              v.category.toLowerCase().contains(q) ||
              v.subcategory.toLowerCase().contains(q))
          .toList();
    }

    // Group by category → subcategory
    final catOrder = <String>[];
    final grouped = <String, List<SketchyVideo>>{};
    for (final v in filtered) {
      final key = v.category;
      if (!grouped.containsKey(key)) {
        catOrder.add(key);
        grouped[key] = [];
      }
      grouped[key]!.add(v);
    }

    if (catOrder.isEmpty) {
      return Center(
        child: Text(
          searchQuery.isNotEmpty ? 'No matching videos' : 'No videos loaded',
          style: TextStyle(
            color: DashboardColors.textPrimary(isDark).withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 72 + 24,
        top: 8,
      ),
      itemCount: catOrder.length,
      itemBuilder: (context, i) {
        final cat = catOrder[i];
        final catVideos = grouped[cat]!;
        final watchedInCat = catVideos.where((v) => v.watched).length;

        // Sub-group by subcategory
        final subCatOrder = <String>[];
        final subGrouped = <String, List<SketchyVideo>>{};
        for (final v in catVideos) {
          final sc = v.subcategory;
          if (!subGrouped.containsKey(sc)) {
            subCatOrder.add(sc);
            subGrouped[sc] = [];
          }
          subGrouped[sc]!.add(v);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: DashboardColors.glassBorder(isDark),
                  width: 0.5,
                ),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: catVideos.length <= 10 || searchQuery.isNotEmpty,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                  title: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.textPrimary(isDark),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$watchedInCat/${catVideos.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DashboardColors.textPrimary(isDark)
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: DashboardColors.textPrimary(isDark)
                            .withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                  children: subCatOrder.map((sc) {
                    final scVideos = subGrouped[sc]!;
                    final scWatched = scVideos.where((v) => v.watched).length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subcategory header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: DashboardColors.primaryLight,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sc,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: DashboardColors.primaryLight,
                                  ),
                                ),
                              ),
                              Text(
                                '$scWatched/${scVideos.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: DashboardColors.textPrimary(isDark)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Videos
                        ...scVideos.map((video) => _buildVideoTile(context, video)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoTile(BuildContext context, SketchyVideo video) {
    final key = 'sketchy:${video.id}';
    final isSelected = selectedItems.contains(key);

    // Check for revision item
    final revIdMicro = 'sketchy-micro-${video.id}';
    final revIdPharm = 'sketchy-pharm-${video.id}';
    final revItem = app.revisionItems.cast<dynamic>().firstWhere(
          (r) => r.id == revIdMicro || r.id == revIdPharm,
          orElse: () => null,
        );
    final hasRevision = revItem != null;
    final revIndex = hasRevision ? revItem.currentRevisionIndex as int : 0;

    return Slidable(
      key: ValueKey(key),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: slidableActionExtentRatio,
        children: [
          SlidableAction(
            onPressed: (_) => app.toggleSketchyWatched(video.id!, !video.watched),
            backgroundColor: video.watched
                ? DashboardColors.warning
                : DashboardColors.success,
            foregroundColor: Colors.white,
            icon: video.watched ? Icons.undo_rounded : Icons.check_rounded,
            label: video.watched ? 'Undo' : 'Done',
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        dense: true,
        title: Row(
          children: [
            Expanded(
              child: Text(
                video.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: DashboardColors.textPrimary(isDark),
                  decoration: video.watched ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Revision badge
            if (hasRevision && video.watched) ...[
              const SizedBox(width: 6),
              Container(
                width: 22,
                height: 22,
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
                      blurRadius: 4,
                      spreadRadius: -1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'R$revIndex',
                    style: const TextStyle(
                      fontSize: 7,
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
        leading: selectionMode
            ? Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected
                    ? DashboardColors.primary
                    : DashboardColors.textPrimary(isDark).withValues(alpha: 0.3),
                size: 20,
              )
            : null,
        trailing: InkWell(
          onTap: () async {
            if (!video.watched) {
              final proceed = await confirmTodayTaskConflictForLibraryItem(
                context: context,
                app: app,
                itemId: video.id!,
                candidateTitles: [
                  video.title,
                  'Sketchy: ${video.title}',
                ],
              );
              if (!proceed || !context.mounted) return;
              app.toggleSketchyWatched(video.id!, true);
            } else {
              final revId = 'sketchy-${video.id}';
              final hasRev = app.revisionItems.any((r) => r.id == revId);
              if (hasRev) {
                showRevisionConfidenceSheet(
                  context: context,
                  revisionItemId: revId,
                  title: video.title,
                  source: 'Sketchy',
                );
              } else {
                app.toggleSketchyWatched(video.id!, false);
              }
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: video.watched
                  ? DashboardColors.success.withValues(alpha: 0.12)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: video.watched
                    ? DashboardColors.success.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              video.watched ? 'Watched ✓' : 'Not Watched',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: video.watched
                    ? DashboardColors.success
                    : DashboardColors.textPrimary(isDark).withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        onTap: selectionMode
            ? () => onToggleSelect(key)
            : () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => LibraryItemDetailSheet(
                    app: app,
                    item: video,
                    itemType: 'sketchy',
                  ),
                );
              },
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────

class _SketchyEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_outline_rounded,
            size: 56,
            color: DashboardColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Sketchy videos loaded',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DashboardColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Import your Sketchy video data to get started',
            style: TextStyle(
              fontSize: 13,
              color:
                  DashboardColors.textPrimary(isDark).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
