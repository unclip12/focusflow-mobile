import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/models/fa_subtopic.dart';
import 'package:focusflow_mobile/models/library_note.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/screens/library/add_note_sheet.dart';
import 'package:focusflow_mobile/screens/library/edit_metadata_sheet.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/utils/show_app_bottom_sheet.dart';

// ══════════════════════════════════════════════════════════════════
// FA Page Detail Sheet — premium liquid-glass redesign
// ══════════════════════════════════════════════════════════════════

class FAPageDetailSheet extends StatefulWidget {
  final AppProvider app;
  final int pageNum;

  const FAPageDetailSheet({
    super.key,
    required this.app,
    required this.pageNum,
  });

  @override
  State<FAPageDetailSheet> createState() => _FAPageDetailSheetState();
}

class _FAPageDetailSheetState extends State<FAPageDetailSheet>
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

  FAPage get _page =>
      widget.app.faPages.firstWhere((p) => p.pageNum == widget.pageNum);

  void _cyclePageStatus(BuildContext context) {
    if (_page.status == 'anki_done') {
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
                widget.app.updateFAPageStatus(_page.pageNum, 'unread');
              },
              child: const Text('Mark Unread'),
            ),
          ],
        ),
      );
    } else if (_page.status == 'read') {
      widget.app.updateFAPageStatus(_page.pageNum, 'anki_done');
    } else {
      widget.app.updateFAPageStatus(_page.pageNum, 'read');
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtopics = widget.app.getSubtopicsForPage(page.pageNum);

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
            _FADetailHeader(
              page: page,
              subtopics: subtopics,
              isDark: isDark,
              onEdit: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => EditMetadataSheet(
                    initialTitle: page.customTitle,
                    initialDescription: page.userDescription,
                    onSave: (title, desc) {
                      final updated = page.copyWith(
                        customTitle: title,
                        userDescription: desc,
                      );
                      widget.app.updateFAPageMetadata(updated);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // ── Quick Actions ───────────────────────────────
            _QuickActionRow(
              page: page,
              isDark: isDark,
              onCycleStatus: () => _cyclePageStatus(context),
            ),
            const SizedBox(height: 16),
            // ── Tab Bar ─────────────────────────────────────
            _GlassTabBar(
              controller: _tabController,
              tabs: const ['History & Progress', 'Notes & Attachments'],
              isDark: isDark,
            ),
            const SizedBox(height: 4),
            // ── Tab Content ─────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _HistoryTab(
                    page: page,
                    subtopics: subtopics,
                    app: widget.app,
                    scrollController: scrollController,
                    isDark: isDark,
                  ),
                  _NotesTab(
                    itemId: 'fa:${page.pageNum}',
                    itemType: 'fa',
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
// HEADER — title, breadcrumb chips, subtopic ring, edit button
// ══════════════════════════════════════════════════════════════════

class _FADetailHeader extends StatelessWidget {
  final FAPage page;
  final List<FASubtopic> subtopics;
  final bool isDark;
  final VoidCallback onEdit;

  const _FADetailHeader({
    required this.page,
    required this.subtopics,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final readSubs = subtopics.where((s) => s.status != 'unread').length;
    final subProgress =
        subtopics.isEmpty ? 0.0 : readSubs / subtopics.length;

    // Status properties
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (page.status) {
      case 'anki_done':
        statusColor = DashboardColors.primaryViolet;
        statusLabel = 'ANKI DONE';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'read':
        statusColor = DashboardColors.success;
        statusLabel = 'READ';
        statusIcon = Icons.menu_book_rounded;
        break;
      default:
        statusColor = DashboardColors.danger;
        statusLabel = 'UNREAD';
        statusIcon = Icons.circle_outlined;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient accent strip
          Container(
            width: 4,
            height: 56,
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
                        page.customTitle ?? page.title,
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
                if (page.customTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Original: ${page.title}',
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
                      label: 'Page ${page.pageNum}',
                      isDark: isDark,
                    ),
                    _BreadcrumbChip(
                      label: page.subject,
                      isDark: isDark,
                      color: DashboardColors.primary,
                    ),
                    _BreadcrumbChip(
                      label: page.system,
                      isDark: isDark,
                    ),
                  ],
                ),
                if (page.userDescription?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    page.userDescription!,
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
          // Subtopic ring + edit
          Column(
            children: [
              if (subtopics.isNotEmpty) ...[
                SizedBox(
                  width: 44,
                  height: 44,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: subProgress),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return CustomPaint(
                        painter: _RingPainter(
                          progress: value,
                          color: readSubs == subtopics.length
                              ? DashboardColors.success
                              : DashboardColors.primary,
                          trackColor: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : DashboardColors.primary
                                  .withValues(alpha: 0.08),
                          strokeWidth: 4,
                        ),
                        child: child,
                      );
                    },
                    child: Center(
                      child: Text(
                        '$readSubs/${subtopics.length}',
                        style: _inter(
                          size: 10,
                          weight: FontWeight.w700,
                          color: DashboardColors.textPrimary(isDark),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
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
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// QUICK ACTION ROW
// ══════════════════════════════════════════════════════════════════

class _QuickActionRow extends StatelessWidget {
  final FAPage page;
  final bool isDark;
  final VoidCallback onCycleStatus;

  const _QuickActionRow({
    required this.page,
    required this.isDark,
    required this.onCycleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (page.status == 'anki_done') ...[
            // When anki_done: show Mark Unread + Anki Done indicator
            Expanded(
              child: _GlassActionButton(
                icon: Icons.undo_rounded,
                label: 'Mark Unread',
                color: DashboardColors.warning,
                isDark: isDark,
                onTap: onCycleStatus,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlassActionButton(
                icon: Icons.check_circle_rounded,
                label: 'Anki Done ✓',
                color: DashboardColors.primaryViolet,
                isDark: isDark,
                onTap: () {},
              ),
            ),
          ] else if (page.status == 'read') ...[
            // When read: show Mark Anki Done button
            Expanded(
              child: _GlassActionButton(
                icon: Icons.check_circle_outline_rounded,
                label: 'Mark Anki Done',
                color: DashboardColors.primaryViolet,
                isDark: isDark,
                onTap: () {
                  final app = context.read<AppProvider>();
                  app.updateFAPageStatus(page.pageNum, 'anki_done');
                },
              ),
            ),
          ] else ...[
            // When unread: show Mark Read
            Expanded(
              child: _GlassActionButton(
                icon: Icons.menu_book_rounded,
                label: 'Mark Read',
                color: DashboardColors.success,
                isDark: isDark,
                onTap: onCycleStatus,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// GLASS TAB BAR — pill-shaped indicator
// ══════════════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════════════
// HISTORY TAB — glass info cards + revision timeline
// ══════════════════════════════════════════════════════════════════

class _HistoryTab extends StatelessWidget {
  final FAPage page;
  final List<FASubtopic> subtopics;
  final AppProvider app;
  final ScrollController scrollController;
  final bool isDark;

  const _HistoryTab({
    required this.page,
    required this.subtopics,
    required this.app,
    required this.scrollController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final readSubs = subtopics.where((s) => s.status != 'unread').length;
    final subProgress =
        subtopics.isEmpty ? 0.0 : (readSubs / subtopics.length) * 100;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      children: [
        // ── Info cards grid ─────────────────────────────
        Row(
          children: [
            Expanded(
              child: _GlassInfoCard(
                icon: Icons.auto_stories_rounded,
                label: 'First Read',
                value: page.firstReadAt != null
                    ? _formatDate(page.firstReadAt!)
                    : '—',
                subtitle: page.firstReadAt != null
                    ? _timeAgo(page.firstReadAt!)
                    : null,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlassInfoCard(
                icon: Icons.replay_rounded,
                label: 'Revisions',
                value: 'R${page.revisionCount}',
                subtitle: page.lastRevisedAt != null
                    ? _timeAgo(page.lastRevisedAt!)
                    : null,
                color: DashboardColors.primaryViolet,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GlassInfoCard(
                icon: Icons.check_circle_outline_rounded,
                label: 'Anki Done',
                value: page.ankiDoneAt != null
                    ? _formatDate(page.ankiDoneAt!)
                    : '—',
                subtitle: page.ankiDoneAt != null
                    ? _timeAgo(page.ankiDoneAt!)
                    : null,
                color: DashboardColors.success,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlassInfoCard(
                icon: Icons.event_rounded,
                label: 'Next Due',
                value: page.ankiDueDate != null
                    ? _formatDate(page.ankiDueDate!)
                    : '—',
                subtitle: page.ankiDueDate != null
                    ? _daysUntil(page.ankiDueDate!)
                    : null,
                color: DashboardColors.warning,
                isDark: isDark,
              ),
            ),
          ],
        ),
        // ── Subtopic progress bar ───────────────────────
        if (subtopics.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionLabel(label: 'Subtopic Progress', isDark: isDark),
          const SizedBox(height: 10),
          _GlassContainer(
            isDark: isDark,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$readSubs / ${subtopics.length} completed',
                      style: _inter(
                        size: 13,
                        weight: FontWeight.w500,
                        color: DashboardColors.textPrimary(isDark),
                      ),
                    ),
                    Text(
                      '${subProgress.round()}%',
                      style: _inter(
                        size: 13,
                        weight: FontWeight.w700,
                        color: readSubs == subtopics.length
                            ? DashboardColors.success
                            : DashboardColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: subProgress / 100),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : DashboardColors.primary
                                .withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          readSubs == subtopics.length
                              ? DashboardColors.success
                              : DashboardColors.primary,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Subtopic list
                ...subtopics.map((st) => _SubtopicRow(
                      subtopic: st,
                      isDark: isDark,
                    )),
              ],
            ),
          ),
        ],
        // ── Revision Timeline ───────────────────────────
        if (page.revisionHistory.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionLabel(label: 'Revision Timeline', isDark: isDark),
          const SizedBox(height: 10),
          _GlassContainer(
            isDark: isDark,
            child: Column(
              children: [
                for (int i = 0; i < page.revisionHistory.length; i++)
                  _TimelineEntry(
                    revision: page.revisionHistory[i],
                    isLast: i == page.revisionHistory.length - 1,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day}/${dt.month}/${dt.year}  $h:$m $amPm';
    } catch (_) {
      return iso;
    }
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
      if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return 'just now';
    } catch (_) {
      return '';
    }
  }

  String _daysUntil(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = dt.difference(DateTime.now());
      if (diff.isNegative) return 'overdue';
      if (diff.inDays == 0) return 'today';
      if (diff.inDays == 1) return 'tomorrow';
      return 'in ${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// NOTES TAB — notes list + add button
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
                  final added = await showAppBottomSheet<bool>(
                    context: context,
                    initialChildSize: 0.55,
                    minChildSize: 0.3,
                    maxChildSize: 0.95,
                    builder: (_, scrollController) => AddNoteSheet(
                      itemId: widget.itemId,
                      itemType: widget.itemType,
                      app: widget.app,
                      scrollController: scrollController,
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
        border: Border.all(
          color: c.withValues(alpha: 0.2),
          width: 0.5,
        ),
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

class _GlassInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color? color;
  final bool isDark;

  const _GlassInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? DashboardColors.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 14, color: c),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: _inter(
                      size: 11,
                      weight: FontWeight.w500,
                      color: DashboardColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: _inter(
                  size: 15,
                  weight: FontWeight.w700,
                  color: DashboardColors.textPrimary(isDark),
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: _inter(
                    size: 10,
                    weight: FontWeight.w500,
                    color: c.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            gradient: DashboardColors.verticalAccentGradient(),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: _inter(
            size: 11,
            weight: FontWeight.w700,
            color: DashboardColors.primary.withValues(alpha: 0.7),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _SubtopicRow extends StatelessWidget {
  final FASubtopic subtopic;
  final bool isDark;

  const _SubtopicRow({required this.subtopic, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    switch (subtopic.status) {
      case 'read':
        dotColor = DashboardColors.success;
        break;
      case 'anki_done':
        dotColor = DashboardColors.primaryViolet;
        break;
      default:
        dotColor = DashboardColors.textSecondary.withValues(alpha: 0.3);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: subtopic.status != 'unread'
                  ? [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              subtopic.name,
              style: _inter(
                size: 12,
                weight: FontWeight.w500,
                color: DashboardColors.textPrimary(isDark),
              ),
            ),
          ),
          if (subtopic.revisionCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DashboardColors.primary,
                    DashboardColors.primaryViolet,
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'R${subtopic.revisionCount}',
                style: _inter(
                  size: 8,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final FAPageRevision revision;
  final bool isLast;
  final bool isDark;

  const _TimelineEntry({
    required this.revision,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Timeline line + dot
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        DashboardColors.primary,
                        DashboardColors.primaryViolet,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            DashboardColors.primary.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            DashboardColors.primary.withValues(alpha: 0.4),
                            DashboardColors.primaryViolet
                                .withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Revision ${revision.revisionNum}',
                    style: _inter(
                      size: 13,
                      weight: FontWeight.w600,
                      color: DashboardColors.textPrimary(isDark),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDate(revision.date),
                        style: _inter(
                          size: 12,
                          weight: FontWeight.w400,
                          color: DashboardColors.textSecondary,
                        ),
                      ),
                      Text(
                        _timeAgo(revision.date),
                        style: _inter(
                          size: 10,
                          weight: FontWeight.w400,
                          color: DashboardColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day}/${dt.month}/${dt.year}  $h:$m $amPm';
    } catch (_) {
      return iso;
    }
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
      if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'just now';
    } catch (_) {
      return '';
    }
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
                    return Container(
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
                          Icon(Icons.attachment_rounded,
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

// ══════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS & HELPERS
// ══════════════════════════════════════════════════════════════════

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress
    if (progress > 0) {
      const startAngle = -1.5708; // -π/2
      final sweepAngle = 2 * 3.14159265 * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

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
