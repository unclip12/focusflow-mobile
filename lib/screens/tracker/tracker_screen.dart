// =============================================================
// TrackerScreen — G6 Premium Library with liquid glass UI
// FA 2025 | Sketchy | Pathoma | UWorld
// AppScaffold + Aurora + Glass tabs + Search/Sort/Filter
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/widgets/aurora_background.dart';
import 'package:focusflow_mobile/screens/tracker/fa_tab.dart';
import 'package:focusflow_mobile/screens/tracker/sketchy_tab.dart';
import 'package:focusflow_mobile/screens/tracker/pathoma_tab.dart';
import 'package:focusflow_mobile/screens/tracker/uworld_tab.dart';
import 'package:focusflow_mobile/screens/tracker/video_lectures_tab.dart';
import 'package:focusflow_mobile/screens/tracker/tracker_sheets.dart';
import 'package:focusflow_mobile/utils/show_app_bottom_sheet.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── State ────────────────────────────────────────────
  bool _selectionMode = false;
  final Set<String> _selectedItems = {};
  bool _showSearch = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _sortBy = 'page_order';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSelect(String key) {
    setState(() {
      if (_selectedItems.contains(key)) {
        _selectedItems.remove(key);
        if (_selectedItems.isEmpty) _selectionMode = false;
      } else {
        _selectedItems.add(key);
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final app = context.watch<AppProvider>();
    final streakCount = app.streakData.currentStreak;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: DashboardColors.background(isDark),
      body: Stack(
        children: [
          // ── Aurora background ───────────────────────────
          Positioned.fill(
            child: AuroraBackground(isDark: isDark),
          ),

          // ── Content ────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Glass header ─────────────────────────
                _GlassLibraryHeader(
                  streakCount: streakCount,
                  isDark: isDark,
                  selectionMode: _selectionMode,
                  selectedCount: _selectedItems.length,
                  onExitSelection: _exitSelection,
                  onToggleSelection: () {
                    setState(() {
                      _selectionMode = !_selectionMode;
                      if (!_selectionMode) _selectedItems.clear();
                    });
                  },
                  showSearch: _showSearch,
                  onToggleSearch: () {
                    setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        _searchCtrl.clear();
                        _searchQuery = '';
                      }
                    });
                  },
                  onShowSort: () => _showSortSheet(context),
                  onShowFilter: () => _showFilterSheet(context),
                  onShowAdd: () => _showAddSheet(context, app),
                  onBulkMark: () => _showBulkSheet(context),
                ),

                // ── Search bar (animated) ────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _showSearch
                      ? _GlassSearchBar(
                          controller: _searchCtrl,
                          isDark: isDark,
                        )
                      : const SizedBox.shrink(),
                ),

                // ── Glass tab bar ────────────────────────
                _GlassLibraryTabBar(
                  controller: _tabController,
                  isDark: isDark,
                  app: app,
                ),

                // ── Tab content ──────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // FA 2025
                      FATab(
                        selectionMode: _selectionMode,
                        selectedItems: _selectedItems,
                        onToggleSelect: _toggleSelect,
                        searchQuery: _searchQuery,
                        statusFilter: _statusFilter,
                        sortBy: _sortBy,
                      ),
                      // Sketchy
                      SketchyTab(
                        app: app,
                        selectionMode: _selectionMode,
                        selectedItems: _selectedItems,
                        onToggleSelect: _toggleSelect,
                        searchQuery: _searchQuery,
                      ),
                      // Pathoma
                      PathomaTab(
                        app: app,
                        selectionMode: _selectionMode,
                        selectedItems: _selectedItems,
                        onToggleSelect: _toggleSelect,
                        searchQuery: _searchQuery,
                      ),
                      // UWorld
                      UWorldTab(
                        app: app,
                        selectionMode: _selectionMode,
                        selectedItems: _selectedItems,
                        onToggleSelect: _toggleSelect,
                        searchQuery: _searchQuery,
                      ),
                      // Video Lectures
                      VideoLecturesTab(
                        app: app,
                        selectionMode: _selectionMode,
                        selectedItems: _selectedItems,
                        onToggleSelect: _toggleSelect,
                        searchQuery: _searchQuery,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Selection mode bottom bar (above nav bar) ──
          if (_selectionMode && _selectedItems.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom,
              child: _GlassSelectionBar(
                count: _selectedItems.length,
                isDark: isDark,
                onAddToTask: () {
                  showAppBottomSheet(
                    context: context,
                    initialChildSize: 0.55,
                    minChildSize: 0.3,
                    builder: (ctx, sc) => SingleChildScrollView(
                      controller: sc,
                      child: AddToTaskSheet(
                        selectedItems: _selectedItems,
                        onDone: _exitSelection,
                      ),
                    ),
                  );
                },
                onClear: _exitSelection,
              ),
            ),
        ],
      ),
    );
  }

  // ── Sort sheet ──────────────────────────────────────────────

  void _showSortSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showAppBottomSheet(
      context: context,
      initialChildSize: 0.45,
      minChildSize: 0.25,
      builder: (ctx, sc) => ListView(
        controller: sc,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Text(
            'Sort By',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DashboardColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 12),
          ...[
              ('page_order', 'Page Order', Icons.sort_rounded),
              ('status', 'Status', Icons.traffic_rounded),
              ('subject', 'Subject', Icons.school_rounded),
              ('last_revised', 'Last Revised', Icons.schedule_rounded),
              ('revision_count', 'Revision Count', Icons.repeat_rounded),
            ].map((item) {
              final (value, label, icon) = item;
              final isActive = _sortBy == value;
              return ListTile(
                dense: true,
                leading: Icon(icon,
                    color: isActive
                        ? DashboardColors.primary
                        : DashboardColors.textPrimary(isDark)
                            .withValues(alpha: 0.4)),
                title: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? DashboardColors.primary
                        : DashboardColors.textPrimary(isDark),
                  ),
                ),
                trailing: isActive
                    ? const Icon(Icons.check_rounded,
                        color: DashboardColors.primary)
                    : null,
                onTap: () {
                  setState(() => _sortBy = value);
                  Navigator.pop(ctx);
                },
              );
            }),
        ],
      ),
    );
  }

  // ── Filter sheet ────────────────────────────────────────────

  void _showFilterSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showAppBottomSheet(
      context: context,
      initialChildSize: 0.5,
      minChildSize: 0.25,
      builder: (ctx, sc) => ListView(
        controller: sc,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Text(
            'Filter By Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DashboardColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 12),
          ...[
              ('all', 'All Items', Icons.select_all_rounded,
                  DashboardColors.primary),
              ('unread', 'Unread', Icons.circle_outlined,
                  DashboardColors.danger),
              ('read', 'Read', Icons.check_circle_outline_rounded,
                  DashboardColors.success),
              ('anki_done', 'Anki Done', Icons.verified_rounded,
                  DashboardColors.primaryViolet),
              ('has_revision', 'Has Revisions', Icons.repeat_rounded,
                  DashboardColors.primaryLight),
            ].map((item) {
              final (value, label, icon, color) = item;
              final isActive = _statusFilter == value;
              return ListTile(
                dense: true,
                leading: Icon(icon,
                    color: isActive
                        ? color
                        : DashboardColors.textPrimary(isDark)
                            .withValues(alpha: 0.4)),
                title: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? color
                        : DashboardColors.textPrimary(isDark),
                  ),
                ),
                trailing: isActive
                    ? Icon(Icons.check_rounded, color: color)
                    : null,
                onTap: () {
                  setState(() => _statusFilter = value);
                  Navigator.pop(ctx);
                },
              );
            }),
        ],
      ),
    );
  }

  // ── Add sheet ───────────────────────────────────────────────

  void _showAddSheet(BuildContext context, AppProvider app) {
    final tabIndex = _tabController.index;
    if (tabIndex == 0) {
      showAppBottomSheet(
        context: context,
        initialChildSize: 0.7,
        minChildSize: 0.3,
        builder: (ctx, sc) => SingleChildScrollView(
          controller: sc,
          child: const AddFAPageSheet(),
        ),
      );
    } else if (tabIndex == 3) {
      showAppBottomSheet(
        context: context,
        initialChildSize: 0.55,
        minChildSize: 0.3,
        builder: (ctx, sc) => SingleChildScrollView(
          controller: sc,
          child: const AddUWorldTopicSheet(),
        ),
      );
    }
  }

  // ── Bulk mark ───────────────────────────────────────────────

  void _showBulkSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      builder: (ctx, sc) => SingleChildScrollView(
        controller: sc,
        child: const BulkMarkSheet(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Glass Library Header — premium header with actions
// ═══════════════════════════════════════════════════════════════

class _GlassLibraryHeader extends StatelessWidget {
  final int streakCount;
  final bool isDark;
  final bool selectionMode;
  final int selectedCount;
  final VoidCallback onExitSelection;
  final VoidCallback onToggleSelection;
  final bool showSearch;
  final VoidCallback onToggleSearch;
  final VoidCallback onShowSort;
  final VoidCallback onShowFilter;
  final VoidCallback onShowAdd;
  final VoidCallback onBulkMark;

  const _GlassLibraryHeader({
    required this.streakCount,
    required this.isDark,
    required this.selectionMode,
    required this.selectedCount,
    required this.onExitSelection,
    required this.onToggleSelection,
    required this.showSearch,
    required this.onToggleSearch,
    required this.onShowSort,
    required this.onShowFilter,
    required this.onShowAdd,
    required this.onBulkMark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.60),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? DashboardColors.glassBorderDark
                    : DashboardColors.glassBorderLight,
                width: 0.5,
              ),
            ),
          ),
          child: selectionMode
              ? _buildSelectionHeader(context)
              : _buildNormalHeader(context),
        ),
      ),
    );
  }

  Widget _buildNormalHeader(BuildContext context) {
    return Row(
      children: [
        // Title
        Text(
          'Library',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: DashboardColors.textPrimary(isDark),
          ),
        ),
        const Spacer(),

        // Action buttons
        _GlassIconBtn(
          icon: showSearch ? Icons.search_off_rounded : Icons.search_rounded,
          isDark: isDark,
          isActive: showSearch,
          onTap: onToggleSearch,
          tooltip: 'Search',
        ),
        const SizedBox(width: 4),
        _GlassIconBtn(
          icon: Icons.sort_rounded,
          isDark: isDark,
          onTap: onShowSort,
          tooltip: 'Sort',
        ),
        const SizedBox(width: 4),
        _GlassIconBtn(
          icon: Icons.filter_alt_rounded,
          isDark: isDark,
          onTap: onShowFilter,
          tooltip: 'Filter',
        ),
        const SizedBox(width: 4),
        _GlassIconBtn(
          icon: Icons.checklist_rounded,
          isDark: isDark,
          onTap: onToggleSelection,
          tooltip: 'Select',
        ),
        const SizedBox(width: 4),

        // More menu
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            size: 20,
            color: DashboardColors.textPrimary(isDark).withValues(alpha: 0.6),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            switch (value) {
              case 'add':
                onShowAdd();
                break;
              case 'bulk':
                onBulkMark();
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'add',
              child: Row(
                children: [
                  Icon(Icons.add_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Add Item'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'bulk',
              child: Row(
                children: [
                  Icon(Icons.checklist_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Bulk Mark'),
                ],
              ),
            ),
          ],
        ),

        // Streak badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? DashboardColors.primary.withValues(alpha: 0.15)
                : DashboardColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: DashboardColors.primary.withValues(alpha: 0.20),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  size: 13, color: Colors.deepOrange),
              const SizedBox(width: 3),
              Text(
                '$streakCount',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.close_rounded,
              color: DashboardColors.textPrimary(isDark)),
          onPressed: onExitSelection,
          tooltip: 'Cancel',
        ),
        Text(
          '$selectedCount selected',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: DashboardColors.textPrimary(isDark),
          ),
        ),
        const Spacer(),
        Text(
          'Tap items to select',
          style: TextStyle(
            fontSize: 12,
            color: DashboardColors.textPrimary(isDark).withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Glass Icon Button — compact action button
// ═══════════════════════════════════════════════════════════════

class _GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  final String tooltip;
  final bool isActive;

  const _GlassIconBtn({
    required this.icon,
    required this.isDark,
    required this.onTap,
    required this.tooltip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? DashboardColors.primary.withValues(alpha: 0.15)
                : isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? DashboardColors.primary.withValues(alpha: 0.3)
                  : DashboardColors.glassBorder(isDark),
              width: 0.5,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive
                ? DashboardColors.primary
                : DashboardColors.textPrimary(isDark).withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Glass Search Bar — animated search input
// ═══════════════════════════════════════════════════════════════

class _GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;

  const _GlassSearchBar({
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DashboardColors.glassBorder(isDark),
                width: 0.5,
              ),
            ),
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontSize: 14,
                color: DashboardColors.textPrimary(isDark),
              ),
              decoration: InputDecoration(
                hintText: 'Search pages, topics, videos...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: DashboardColors.textPrimary(isDark)
                      .withValues(alpha: 0.4),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: DashboardColors.primary.withValues(alpha: 0.5),
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: controller.clear,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Glass Library Tab Bar — premium tab bar with item counts
// ═══════════════════════════════════════════════════════════════

class _GlassLibraryTabBar extends StatelessWidget {
  final TabController controller;
  final bool isDark;
  final AppProvider app;

  const _GlassLibraryTabBar({
    required this.controller,
    required this.isDark,
    required this.app,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: DashboardColors.glassBorder(isDark),
                width: 0.5,
              ),
            ),
            child: TabBar(
              controller: controller,
              tabs: [
                _buildTab('FA', app.faPages.length),
                _buildTab('Sketchy',
                    app.sketchyMicroVideos.length + app.sketchyPharmVideos.length),
                _buildTab('Pathoma', app.pathomaChapters.length),
                _buildTab('UWorld', app.uworldTopics.length),
                _buildTab('Videos', app.videoLectures.length),
              ],
              labelColor: DashboardColors.primary,
              unselectedLabelColor:
                  DashboardColors.textPrimary(isDark).withValues(alpha: 0.5),
              indicatorColor: DashboardColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
          if (count > 0) ...[
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: DashboardColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.primary.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Glass Selection Bar — bottom bar during selection mode
// ═══════════════════════════════════════════════════════════════

class _GlassSelectionBar extends StatelessWidget {
  final int count;
  final bool isDark;
  final VoidCallback onAddToTask;
  final VoidCallback onClear;

  const _GlassSelectionBar({
    required this.count,
    required this.isDark,
    required this.onAddToTask,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: isDark
                ? DashboardColors.primary.withValues(alpha: 0.12)
                : DashboardColors.primary.withValues(alpha: 0.08),
            border: Border(
              top: BorderSide(
                color: DashboardColors.primary.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Count badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: DashboardColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count item${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              // Add to task button
              FilledButton.icon(
                onPressed: onAddToTask,
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: const Text('Add to Task'),
                style: FilledButton.styleFrom(
                  backgroundColor: DashboardColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              const SizedBox(width: 8),
              // Clear button
              OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: DashboardColors.primary.withValues(alpha: 0.3),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: DashboardColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
