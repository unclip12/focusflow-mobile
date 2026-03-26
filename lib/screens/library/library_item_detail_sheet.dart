import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:focusflow_mobile/models/library_note.dart';
import 'package:focusflow_mobile/models/sketchy_video.dart';
import 'package:focusflow_mobile/models/pathoma_chapter.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/screens/library/add_note_sheet.dart';
import 'package:focusflow_mobile/screens/library/edit_metadata_sheet.dart';
import 'package:focusflow_mobile/screens/library/attachment_helper.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';

// ══════════════════════════════════════════════════════════════════
// Library Item Detail Sheet — Sketchy / Pathoma (liquid-glass)
// ══════════════════════════════════════════════════════════════════

class LibraryItemDetailSheet extends StatefulWidget {
  final AppProvider app;
  final dynamic item; // SketchyVideo or PathomaChapter
  final String itemType; // 'sketchy' or 'pathoma'

  const LibraryItemDetailSheet({
    super.key,
    required this.app,
    required this.item,
    required this.itemType,
  });

  @override
  State<LibraryItemDetailSheet> createState() => _LibraryItemDetailSheetState();
}

class _LibraryItemDetailSheetState extends State<LibraryItemDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  dynamic get _item {
    if (widget.itemType == 'sketchy') {
      final sketchy = widget.item as SketchyVideo;
      return widget.app.sketchyMicroVideos.firstWhere(
        (v) => v.id == sketchy.id,
        orElse: () => widget.app.sketchyPharmVideos.firstWhere(
          (v) => v.id == sketchy.id,
          orElse: () => widget.item,
        ),
      );
    } else {
      final pathoma = widget.item as PathomaChapter;
      return widget.app.pathomaChapters.firstWhere(
        (c) => c.id == pathoma.id,
        orElse: () => widget.item,
      );
    }
  }

  String get _itemId {
    if (widget.itemType == 'sketchy') {
      return 'sketchy:${(widget.item as SketchyVideo).id}';
    } else {
      return 'pathoma:${(widget.item as PathomaChapter).id}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dynamic item = _item;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // ── Drag handle ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // ── Header ──────────────────────────────────────
            _LibraryDetailHeader(
              item: item,
              itemType: widget.itemType,
              isDark: isDark,
              onEdit: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => EditMetadataSheet(
                    initialTitle: item.customTitle,
                    initialDescription: item.userDescription,
                    onSave: (title, desc) {
                      final updated = item.copyWith(
                        customTitle: title,
                        userDescription: desc,
                      );
                      if (widget.itemType == 'sketchy') {
                        widget.app.updateSketchyMetadata(updated);
                      } else {
                        widget.app.updatePathomaMetadata(updated);
                      }
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // ── Quick Actions ───────────────────────────────
            _LibraryQuickActions(
              item: item,
              itemType: widget.itemType,
              app: widget.app,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            // ── Tab Bar ─────────────────────────────────────
            _GlassTabBar(
              controller: _tabController,
              tabs: const ['Progress', 'Notes & Attachments'],
              isDark: isDark,
            ),
            const SizedBox(height: 4),
            // ── Tab Content ─────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ProgressTab(
                    item: item,
                    itemType: widget.itemType,
                    app: widget.app,
                    scrollController: scrollController,
                    isDark: isDark,
                  ),
                  _NotesTab(
                    itemId: _itemId,
                    itemType: widget.itemType,
                    app: widget.app,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════════════════

class _LibraryDetailHeader extends StatelessWidget {
  final dynamic item;
  final String itemType;
  final bool isDark;
  final VoidCallback onEdit;

  const _LibraryDetailHeader({
    required this.item,
    required this.itemType,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWatched = item.watched;
    final statusColor =
        isWatched ? DashboardColors.success : DashboardColors.warning;
    final statusLabel = isWatched ? 'WATCHED' : 'NOT WATCHED';
    final statusIcon =
        isWatched ? Icons.check_circle_rounded : Icons.circle_outlined;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient accent strip
          Container(
            width: 4,
            height: 48,
            margin: const EdgeInsets.only(top: 4, right: 14),
            decoration: BoxDecoration(
              gradient: DashboardColors.verticalAccentGradient(),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title + breadcrumbs
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.customTitle ?? item.title,
                        style: _inter(
                          size: 20,
                          weight: FontWeight.w700,
                          color: DashboardColors.textPrimary(isDark),
                        ),
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: _inter(
                              size: 9,
                              weight: FontWeight.w800,
                              color: statusColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (item.customTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Original: ${item.title}',
                    style: _inter(
                      size: 11,
                      weight: FontWeight.w400,
                      color: DashboardColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // Breadcrumb chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _BreadcrumbChip(
                      label: itemType == 'sketchy' ? 'Sketchy' : 'Pathoma',
                      isDark: isDark,
                      color: DashboardColors.primary,
                    ),
                    if (itemType == 'sketchy') ...[
                      _BreadcrumbChip(
                          label: item.category, isDark: isDark),
                      _BreadcrumbChip(
                          label: item.subcategory, isDark: isDark),
                    ] else
                      _BreadcrumbChip(
                        label: 'Chapter ${item.chapter}',
                        isDark: isDark,
                      ),
                  ],
                ),
                if (item.userDescription?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.userDescription!,
                    style: _inter(
                      size: 12,
                      weight: FontWeight.w400,
                      color: DashboardColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Edit button
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : DashboardColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: DashboardColors.glassBorder(isDark),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.edit_rounded,
                size: 16,
                color: DashboardColors.textPrimary(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// QUICK ACTIONS
// ══════════════════════════════════════════════════════════════════

class _LibraryQuickActions extends StatelessWidget {
  final dynamic item;
  final String itemType;
  final AppProvider app;
  final bool isDark;

  const _LibraryQuickActions({
    required this.item,
    required this.itemType,
    required this.app,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWatched = item.watched;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _GlassActionButton(
              icon: isWatched
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              label: isWatched ? 'Mark Unwatched' : 'Mark Watched',
              color: isWatched
                  ? DashboardColors.warning
                  : DashboardColors.success,
              isDark: isDark,
              onTap: () {
                if (itemType == 'sketchy') {
                  app.toggleSketchyWatched(item.id, !isWatched);
                } else {
                  app.togglePathomaChapterWatched(item.id, !isWatched);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// PROGRESS TAB
// ══════════════════════════════════════════════════════════════════

class _ProgressTab extends StatelessWidget {
  final dynamic item;
  final String itemType;
  final AppProvider app;
  final ScrollController scrollController;
  final bool isDark;

  const _ProgressTab({
    required this.item,
    required this.itemType,
    required this.app,
    required this.scrollController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWatched = item.watched;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      children: [
        // Watch status card
        _GlassContainer(
          isDark: isDark,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isWatched
                          ? DashboardColors.success
                          : DashboardColors.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isWatched
                      ? Icons.check_circle_rounded
                      : Icons.play_circle_outline_rounded,
                  size: 24,
                  color: isWatched
                      ? DashboardColors.success
                      : DashboardColors.warning,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWatched
                          ? 'You have watched this'
                          : 'Not watched yet',
                      style: _inter(
                        size: 14,
                        weight: FontWeight.w600,
                        color: DashboardColors.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isWatched
                          ? 'Tap the button above to mark as unwatched'
                          : 'Tap the button above to mark as watched',
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
        // Resource info
        const SizedBox(height: 12),
        _GlassContainer(
          isDark: isDark,
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.category_rounded,
                label: 'Type',
                value: itemType == 'sketchy' ? 'Sketchy Video' : 'Pathoma Chapter',
                isDark: isDark,
              ),
              if (itemType == 'sketchy') ...[
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.folder_rounded,
                  label: 'Category',
                  value: item.category,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.subdirectory_arrow_right_rounded,
                  label: 'Subcategory',
                  value: item.subcategory,
                  isDark: isDark,
                ),
              ] else ...[
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.bookmark_rounded,
                  label: 'Chapter',
                  value: '${item.chapter}',
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// NOTES TAB
// ══════════════════════════════════════════════════════════════════

class _NotesTab extends StatefulWidget {
  final String itemId;
  final String itemType;
  final AppProvider app;
  final bool isDark;

  const _NotesTab({
    required this.itemId,
    required this.itemType,
    required this.app,
    required this.isDark,
  });

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  List<LibraryNote>? _notes;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await widget.app.getLibraryNotes(widget.itemId);
    if (mounted) {
      setState(() => _notes = notes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    if (_notes == null) {
      return Center(
        child: CircularProgressIndicator(
          color: DashboardColors.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _notes!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : DashboardColors.primary
                                  .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: DashboardColors.glassBorder(isDark),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.note_alt_rounded,
                          size: 28,
                          color:
                              DashboardColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notes yet',
                        style: _inter(
                          size: 14,
                          weight: FontWeight.w500,
                          color: DashboardColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap below to add your first note',
                        style: _inter(
                          size: 12,
                          weight: FontWeight.w400,
                          color: DashboardColors.textSecondary
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.of(context).padding.bottom + 20,
                  ),
                  itemCount: _notes!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final note = _notes![i];
                    return _GlassNoteCard(
                      note: note,
                      isDark: isDark,
                    );
                  },
                ),
        ),
        // ── Add Note Button ───────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: DashboardColors.glassBorder(isDark),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: _GlassActionButton(
                icon: Icons.add_rounded,
                label: 'Add Note / Attachment',
                color: DashboardColors.primary,
                isDark: isDark,
                onTap: () async {
                  final added = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => AddNoteSheet(
                      itemId: widget.itemId,
                      itemType: widget.itemType,
                      app: widget.app,
                    ),
                  );
                  if (added == true) {
                    _loadNotes();
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// REUSABLE COMPONENTS
// ══════════════════════════════════════════════════════════════════

class _BreadcrumbChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color? color;

  const _BreadcrumbChip({
    required this.label,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? DashboardColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: _inter(
          size: 10,
          weight: FontWeight.w600,
          color: c,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: _inter(
                    size: 13,
                    weight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final bool isDark;

  const _GlassTabBar({
    required this.controller,
    required this.tabs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DashboardColors.glassBorder(isDark),
          width: 0.5,
        ),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: isDark
              ? DashboardColors.primary.withValues(alpha: 0.2)
              : DashboardColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: DashboardColors.primary.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: DashboardColors.primary,
        unselectedLabelColor: DashboardColors.textSecondary,
        labelStyle: _inter(size: 12, weight: FontWeight.w600),
        unselectedLabelStyle: _inter(size: 12, weight: FontWeight.w500),
        tabs: tabs.map((t) => Tab(text: t, height: 36)).toList(),
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _GlassContainer({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DashboardColors.glassBorder(isDark),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: DashboardColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: DashboardColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: _inter(
            size: 12,
            weight: FontWeight.w500,
            color: DashboardColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: _inter(
            size: 13,
            weight: FontWeight.w600,
            color: DashboardColors.textPrimary(isDark),
          ),
        ),
      ],
    );
  }
}

class _GlassNoteCard extends StatelessWidget {
  final LibraryNote note;
  final bool isDark;

  const _GlassNoteCard({required this.note, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.noteText.isNotEmpty)
                Text(
                  note.noteText,
                  style: _inter(
                    size: 13,
                    weight: FontWeight.w400,
                    color: DashboardColors.textPrimary(isDark),
                  ),
                ),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note.tags
                      .map((t) => _BreadcrumbChip(
                            label: t,
                            isDark: isDark,
                            color: DashboardColors.primary,
                          ))
                      .toList(),
                ),
              ],
              if (note.attachmentPaths.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note.attachmentPaths.map((path) {
                    return GestureDetector(
                      onTap: () =>
                          AttachmentHelper.openAttachment(context, path),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: DashboardColors.warning
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: DashboardColors.warning
                                .withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(AttachmentHelper.getIcon(path),
                                size: 12,
                                color: DashboardColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              path.split('/').last,
                              style: _inter(
                                size: 10,
                                weight: FontWeight.w500,
                                color: DashboardColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────

TextStyle _inter({
  required double size,
  FontWeight weight = FontWeight.w400,
  Color? color,
  double? letterSpacing,
}) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );
}
