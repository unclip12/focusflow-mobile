// =============================================================
// TrackerScreen — G5 unified tracker with 4 tabs
// FA 2025 | Sketchy | Pathoma | UWorld
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:uuid/uuid.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/models/fa_subtopic.dart';
import 'package:focusflow_mobile/models/pathoma_chapter.dart';
import 'package:focusflow_mobile/models/sketchy_video.dart';
import 'package:focusflow_mobile/models/uworld_topic.dart';
import 'package:focusflow_mobile/screens/library/fa_item_detail_sheet.dart';
import 'package:focusflow_mobile/screens/library/library_item_detail_sheet.dart';
import 'package:focusflow_mobile/screens/library/uworld_detail_sheet.dart';
import 'package:focusflow_mobile/screens/revision_hub/revision_confidence_sheet.dart';
import 'package:focusflow_mobile/utils/constants.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

const double _slidableActionExtentRatio = 0.28;
const double _twoActionPaneExtentRatio = _slidableActionExtentRatio * 2;

Future<bool> _confirmTodayTaskConflictForLibraryItem({
  required BuildContext context,
  required AppProvider app,
  required int itemId,
  required Iterable<String> candidateTitles,
}) async {
  final matchingBlocks = app.getTodayBlocksForLibraryVideo(
    videoId: itemId,
    candidateTitles: candidateTitles,
  );
  if (matchingBlocks.isEmpty) return true;

  final action = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Already In Today\'s Tasks'),
      content: const Text(
        'This item is already in today\'s tasks. Mark as Revision instead?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop('keep'),
          child: const Text('Keep'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop('remove'),
          child: const Text('Remove from tasks'),
        ),
      ],
    ),
  );

  if (action == 'remove') {
    await app.removeTodayBlocksById(matchingBlocks.map((block) => block.id));
    return true;
  }

  return action == 'keep';
}

class _TrackerScreenState extends State<TrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Selection mode state ──────────────────────────────────
  bool _selectionMode = false;
  final Set<String> _selectedItems = {}; // e.g. 'fa:45', 'sketchy:12'

  void _toggleSelection(String key) {
    setState(() {
      if (_selectedItems.contains(key)) {
        _selectedItems.remove(key);
        if (_selectedItems.isEmpty) _selectionMode = false;
      } else {
        _selectedItems.add(key);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedItems.clear();
    });
  }

  void _showTrackerAddSheet() {
    WidgetBuilder? builder;
    if (_tabController.index == 0) {
      builder = (_) => const _AddFAPageSheet();
    } else if (_tabController.index == 3) {
      builder = (_) => const _AddUWorldTopicSheet();
    }
    if (builder == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: builder,
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _selectionMode ? '${_selectedItems.length} selected' : 'Library'),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: [
          if (!_selectionMode)
            IconButton(
              icon: const Icon(Icons.checklist_rounded),
              tooltip: 'Select items',
              onPressed: () => setState(() => _selectionMode = true),
            ),
          if (!_selectionMode &&
              (_tabController.index == 0 || _tabController.index == 3))
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: _tabController.index == 0
                  ? 'Add FA page'
                  : 'Add UWorld topic',
              onPressed: _showTrackerAddSheet,
            ),
          if (_selectionMode && _selectedItems.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() => _selectedItems.clear()),
              icon: const Icon(Icons.deselect_rounded, size: 18),
              label: const Text('Clear'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'FA 2025'),
            Tab(text: 'Sketchy'),
            Tab(text: 'Pathoma'),
            Tab(text: 'UWorld'),
          ],
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FATab(
                  selectionMode: _selectionMode,
                  selectedItems: _selectedItems,
                  onToggleSelect: _toggleSelection,
                ),
                _SketchyTab(
                  selectionMode: _selectionMode,
                  selectedItems: _selectedItems,
                  onToggleSelect: _toggleSelection,
                ),
                _PathomaTab(
                  selectionMode: _selectionMode,
                  selectedItems: _selectedItems,
                  onToggleSelect: _toggleSelection,
                ),
                _UWorldTab(
                  selectionMode: _selectionMode,
                  selectedItems: _selectedItems,
                  onToggleSelect: _toggleSelection,
                ),
              ],
            ),
          ),
          // ── Bottom selection bar ────────────────────────────
          if (_selectionMode && _selectedItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                border: Border(
                    top: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.3))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 20, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedItems.length} item${_selectedItems.length == 1 ? '' : 's'} selected',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          useSafeArea: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => _AddToTaskSheet(
                            selectedItems: Set<String>.from(_selectedItems),
                            onDone: _exitSelectionMode,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_task_rounded, size: 18),
                      label: const Text('Add to Task'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: !_selectionMode && _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => const _BulkMarkSheet(),
                );
              },
              child: const Icon(Icons.playlist_add_check_rounded),
            )
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 1 — FA 2025 (liquid-fill page boxes + subtopic picker)
// ═══════════════════════════════════════════════════════════════

class _FATab extends StatefulWidget {
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;
  const _FATab({
    required this.selectionMode,
    required this.selectedItems,
    required this.onToggleSelect,
  });

  @override
  State<_FATab> createState() => _FATabState();
}

class _FATabState extends State<_FATab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        if (app.faPages.isEmpty) {
          return _EmptyPlaceholder(
            icon: Icons.menu_book_rounded,
            text: 'No FA pages loaded yet.',
          );
        }

        final cs = Theme.of(context).colorScheme;

        // Sort by orderIndex for FA book order
        final sorted = List<FAPage>.from(app.faPages)
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

        final readCount = sorted.where((p) => p.status != 'unread').length;
        final totalPages = sorted.length;

        return Column(
          children: [
            // ── Header: progress + view toggle ─────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$readCount / $totalPages pages',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalPages > 0 ? readCount / totalPages : 0,
                            minHeight: 6,
                            backgroundColor: cs.surfaceContainerHighest,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'pages',
                        icon: Icon(Icons.grid_view_rounded, size: 16),
                        label: Text('Pages', style: TextStyle(fontSize: 10)),
                      ),
                      ButtonSegment(
                        value: 'topics',
                        icon: Icon(Icons.list_rounded, size: 16),
                        label: Text('Topics', style: TextStyle(fontSize: 10)),
                      ),
                      ButtonSegment(
                        value: 'cards',
                        icon: Icon(Icons.view_agenda_rounded, size: 16),
                        label: Text('Cards', style: TextStyle(fontSize: 10)),
                      ),
                    ],
                    selected: {app.faViewMode},
                    onSelectionChanged: (v) => app.saveFAViewMode(v.first),
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ────────────────────────────────────────
            Expanded(
              child: app.faViewMode == 'topics'
                  ? _SubtopicListView(app: app)
                  : app.faViewMode == 'cards'
                      ? _FACardView(
                          app: app,
                          sorted: sorted,
                          selectionMode: widget.selectionMode,
                          selectedItems: widget.selectedItems,
                          onToggleSelect: widget.onToggleSelect,
                        )
                      : _PageGridView(
                          app: app,
                          sorted: sorted,
                          selectionMode: widget.selectionMode,
                          selectedItems: widget.selectedItems,
                          onToggleSelect: widget.onToggleSelect,
                        ),
            ),
          ],
        );
      },
    );
  }
}

/// Grid of liquid-fill page number boxes grouped by subject
class _PageGridView extends StatelessWidget {
  final AppProvider app;
  final List<FAPage> sorted;
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;
  const _PageGridView({
    required this.app,
    required this.sorted,
    required this.selectionMode,
    required this.selectedItems,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    // Group by subject, preserving order
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
        final cs = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      subject,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  Text(
                    '$readCount/${pages.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
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
                      isSelected: selectedItems.contains('fa:${page.pageNum}'),
                      onToggleSelect: () =>
                          onToggleSelect('fa:${page.pageNum}'),
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

/// Individual liquid-fill page number box
class _LiquidFillPageBox extends StatelessWidget {
  final FAPage page;
  final AppProvider app;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  const _LiquidFillPageBox({
    required this.page,
    required this.app,
    required this.selectionMode,
    required this.isSelected,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final percent = app.getPageCompletionPercent(page.pageNum);
    final isFullyRead = page.status != 'unread';
    final isAnkiDone = page.status == 'anki_done';

    // Colors
    Color textColor;
    Color boxBg;

    if (isAnkiDone) {
      textColor = Colors.white;
      boxBg = Colors.purple;
    } else if (percent >= 1.0 || isFullyRead) {
      textColor = Colors.white;
      boxBg = Colors.green;
    } else if (percent > 0) {
      textColor = cs.onSurface;
      boxBg = cs.surfaceContainerHigh;
    } else {
      textColor = Colors.white;
      boxBg = Colors.red.shade700;
    }

    const boxSize = 56.0;

    return GestureDetector(
      onTap:
          selectionMode ? onToggleSelect : () => _showSubtopicPicker(context),
      onLongPress: selectionMode ? null : () => _showFADetailSheet(context),
      child: SizedBox(
        width: boxSize,
        height: boxSize,
        child: Stack(
          children: [
            // Background box
            Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: percent > 0 && percent < 1.0
                    ? cs.surfaceContainerHigh
                    : boxBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAnkiDone
                      ? Colors.purple.withValues(alpha: 0.4)
                      : isFullyRead || percent >= 1.0
                          ? Colors.green.withValues(alpha: 0.4)
                          : percent > 0
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.red.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: percent >= 1.0 || isFullyRead
                    ? [
                        BoxShadow(
                          color: (isAnkiDone ? Colors.purple : Colors.green)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),

            // Liquid fill (bottom-to-top)
            if (percent > 0 && percent < 1.0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    height: boxSize * percent,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.green.shade500,
                          Colors.green.shade300.withValues(alpha: 0.8),
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
                  color:
                      percent > 0 && percent < 1.0 ? cs.onSurface : textColor,
                ),
              ),
            ),

            // Revision badge
            if (page.revisionCount > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'R${page.revisionCount}',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Anki done tick overlay
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
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary.withValues(alpha: 0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: cs.primary, width: 2.5)
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
      // No subtopics — direct cycle
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
      builder: (_) => _SubtopicPickerSheet(
        pageNum: page.pageNum,
        page: page,
        app: app,
      ),
    );
  }

  void _cyclePageStatus(BuildContext context) {
    if (page.status == 'anki_done') {
      // Show confirmation to mark unread
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

/// Bottom sheet for picking subtopics to mark as read
class _SubtopicPickerSheet extends StatefulWidget {
  final int pageNum;
  final FAPage page;
  final AppProvider app;
  const _SubtopicPickerSheet({
    required this.pageNum,
    required this.page,
    required this.app,
  });

  @override
  State<_SubtopicPickerSheet> createState() => _SubtopicPickerSheetState();
}

class _SubtopicPickerSheetState extends State<_SubtopicPickerSheet> {
  late List<FASubtopic> _subtopics;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _subtopics = widget.app.getSubtopicsForPage(widget.pageNum);
    // Pre-select already-read subtopics
    for (final s in _subtopics) {
      if (s.status != 'unread' && s.id != null) {
        _selected.add(s.id!);
      }
    }
  }

  bool get _allSelected => _subtopics.every((s) => _selected.contains(s.id));

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
        // Keep already-read ones selected
        for (final s in _subtopics) {
          if (s.status != 'unread' && s.id != null) {
            _selected.add(s.id!);
          }
        }
      } else {
        _selected.clear();
        for (final s in _subtopics) {
          if (s.id != null) _selected.add(s.id!);
        }
      }
    });
  }

  Future<void> _save() async {
    // Find newly selected (unread → read)
    final newlySelected = <int>[];
    for (final s in _subtopics) {
      if (s.id != null && _selected.contains(s.id!) && s.status == 'unread') {
        newlySelected.add(s.id!);
      }
    }
    if (newlySelected.isNotEmpty) {
      await widget.app.markSubtopicsRead(newlySelected);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final readCount = _subtopics.where((s) => s.status != 'unread').length;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Page ${widget.pageNum} — Subtopics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _toggleAll,
                icon: Icon(
                  _allSelected
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                  size: 16,
                ),
                label: Text(_allSelected ? 'Deselect' : 'All'),
              ),
            ],
          ),
          Text(
            '${widget.page.subject} • $readCount/${_subtopics.length} done',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              itemCount: _subtopics.length,
              itemBuilder: (context, i) {
                final st = _subtopics[i];
                final isSelected = _selected.contains(st.id);
                final alreadyRead = st.status != 'unread';

                return CheckboxListTile(
                  dense: true,
                  value: isSelected,
                  onChanged: alreadyRead
                      ? null
                      : (v) {
                          setState(() {
                            if (v == true && st.id != null) {
                              _selected.add(st.id!);
                            } else if (st.id != null) {
                              _selected.remove(st.id!);
                            }
                          });
                        },
                  title: Text(
                    st.name,
                    style: TextStyle(
                      fontSize: 13,
                      decoration:
                          alreadyRead ? TextDecoration.lineThrough : null,
                      color: alreadyRead ? cs.onSurfaceVariant : cs.onSurface,
                    ),
                  ),
                  subtitle: alreadyRead
                      ? Text(
                          st.status == 'anki_done' ? 'Anki ✓' : 'Read ✓',
                          style: TextStyle(
                            fontSize: 10,
                            color: st.status == 'anki_done'
                                ? Colors.purple
                                : Colors.green,
                          ),
                        )
                      : null,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flat list of all subtopics across all pages
class _SubtopicListView extends StatelessWidget {
  final AppProvider app;
  const _SubtopicListView({required this.app});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subtopics = List<FASubtopic>.from(app.faSubtopics);
    if (subtopics.isEmpty) {
      return _EmptyPlaceholder(
        icon: Icons.topic_rounded,
        text: 'No subtopics loaded yet.',
      );
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
            statusColor = Colors.green;
            statusLabel = 'Read ✓';
            break;
          case 'anki_done':
            statusColor = Colors.purple;
            statusLabel = 'Anki ✓';
            break;
          default:
            statusColor = Colors.red.shade700;
            statusLabel = 'Unread';
        }

        return Slidable(
          key: ValueKey('st_${st.id}'),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: _twoActionPaneExtentRatio,
            children: [
              if (st.status != 'unread')
                SlidableAction(
                  onPressed: (_) => app.undoFASubtopic(st.id!),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  icon: Icons.undo_rounded,
                  label: 'Undo',
                ),
              SlidableAction(
                onPressed: (_) => app.resetFASubtopic(st.id!),
                backgroundColor: Colors.red.shade700,
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
          child: ListTile(
            dense: true,
            title: Text(
              st.name,
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              'Page ${st.pageNum}',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            trailing: InkWell(
              onTap: () {
                if (st.status == 'unread') {
                  app.advanceFASubtopicRevision(st.id!);
                } else {
                  // Find the revision item for parent page or subtopic
                  final subRevId = 'fa-sub-${st.pageNum}-${st.id}';
                  final pageRevId = 'fa-page-${st.pageNum}';
                  // Prefer subtopic revision if it exists, else fall back to page
                  final hasSubRev = app.revisionItems.any((r) => r.id == subRevId);
                  final revId = hasSubRev ? subRevId : pageRevId;
                  final hasRev = app.revisionItems.any((r) => r.id == revId);
                  if (hasRev) {
                    showRevisionConfidenceSheet(
                      context: context,
                      revisionItemId: revId,
                      title: '${st.name} (p.${st.pageNum})',
                      source: 'FA',
                    );
                  } else {
                    // No revision item yet — advance normally
                    app.advanceFASubtopicRevision(st.id!);
                  }
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => FAPageDetailSheet(
                  app: app,
                  pageNum: st.pageNum,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 2 — Sketchy (Micro + Pharm sub-tabs)
// ═══════════════════════════════════════════════════════════════

class _SketchyTab extends StatelessWidget {
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;
  const _SketchyTab({
    required this.selectionMode,
    required this.selectedItems,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Micro'),
              Tab(text: 'Pharm'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, app, _) {
                return TabBarView(
                  children: [
                    _SketchyVideoList(
                      videos: app.sketchyMicroVideos,
                      onToggle: (id, watched) =>
                          app.toggleSketchyMicroWatched(id, watched),
                      selectionMode: selectionMode,
                      selectedItems: selectedItems,
                      onToggleSelect: onToggleSelect,
                    ),
                    _SketchyVideoList(
                      videos: app.sketchyPharmVideos,
                      onToggle: (id, watched) =>
                          app.toggleSketchyPharmWatched(id, watched),
                      selectionMode: selectionMode,
                      selectedItems: selectedItems,
                      onToggleSelect: onToggleSelect,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SketchyVideoList extends StatelessWidget {
  final List<SketchyVideo> videos;
  final void Function(int id, bool watched) onToggle;
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;

  const _SketchyVideoList({
    required this.videos,
    required this.onToggle,
    required this.selectionMode,
    required this.selectedItems,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const _EmptyPlaceholder(
        icon: Icons.videocam_rounded,
        text: 'Sketchy items will appear here.',
      );
    }

    final cs = Theme.of(context).colorScheme;
    final watchedCount = videos.where((v) => v.watched).length;
    final total = videos.length;
    final progress = total > 0 ? watchedCount / total : 0.0;

    // Group by category → subcategory
    final grouped = <String, Map<String, List<SketchyVideo>>>{};
    for (final v in videos) {
      grouped
          .putIfAbsent(v.category, () => {})
          .putIfAbsent(v.subcategory, () => [])
          .add(v);
    }
    final categories = grouped.keys.toList();

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$watchedCount / $total watched',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
            ],
          ),
        ),
        // Grouped list
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 72 + 24,
            ),
            children: categories.map((cat) {
              final subcategories = grouped[cat]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  ...subcategories.entries.map((entry) {
                    final subcat = entry.key;
                    final items = entry.value;
                    final subWatched = items.where((v) => v.watched).length;
                    return ExpansionTile(
                      title: Text(subcat),
                      subtitle: Text(
                        '$subWatched / ${items.length}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      children: items.map((v) {
                        final key = 'sketchy:${v.id}';
                        final isSelected = selectedItems.contains(key);
                        if (selectionMode) {
                          return CheckboxListTile(
                            dense: true,
                            value: isSelected,
                            onChanged: (_) => onToggleSelect(key),
                            title: Text(
                              v.title,
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: v.watched
                                ? Text('Watched ✓',
                                    style: TextStyle(
                                        fontSize: 10, color: cs.primary))
                                : null,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: cs.primary,
                          );
                        }

                        // Status color / label based on revision progress
                        final app = context.read<AppProvider>();
                        final isMicro =
                            v.category.toLowerCase().contains('micro');
                        final skRevId = isMicro
                            ? 'sketchy-micro-${v.id}'
                            : 'sketchy-pharm-${v.id}';
                        final skRevIdx = app.revisionItems
                            .indexWhere((r) => r.id == skRevId);
                        final skRevCount = skRevIdx >= 0
                            ? app.revisionItems[skRevIdx].currentRevisionIndex
                            : 0;

                        Color statusColor;
                        String statusLabel;
                        if (!v.watched) {
                          statusColor = Colors.red.shade700;
                          statusLabel = 'Unwatched';
                        } else if (skRevCount > 0) {
                          statusColor = Colors.blue;
                          statusLabel = 'Rev $skRevCount';
                        } else {
                          statusColor = Colors.green;
                          statusLabel = 'Watched ✓';
                        }

                        // Undo action based on micro vs pharm
                        Future<void> handleUndo() async {
                          final app = context.read<AppProvider>();
                          await app.undoSketchy(v.id!);
                        }

                        // Reset action
                        Future<void> handleReset() async {
                          final app = context.read<AppProvider>();
                          await app.resetSketchy(v.id!);
                        }

                        return Slidable(
                          key: ValueKey('sketchy_${v.id}'),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            extentRatio: _twoActionPaneExtentRatio,
                            children: [
                              if (v.watched)
                                SlidableAction(
                                  onPressed: (_) => handleUndo(),
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  icon: Icons.undo_rounded,
                                  label: 'Undo',
                                ),
                              SlidableAction(
                                onPressed: (_) => handleReset(),
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                                icon: Icons.restart_alt_rounded,
                                label: 'Reset',
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          child: ListTile(
                            dense: true,
                            title: Text(
                              v.title,
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: InkWell(
                              onTap: v.id != null
                                  ? () async {
                                      final app = context.read<AppProvider>();
                                      if (!v.watched) {
                                        final shouldAdvance =
                                            await _confirmTodayTaskConflictForLibraryItem(
                                          context: context,
                                          app: app,
                                          itemId: v.id!,
                                          candidateTitles: {
                                            'Sketchy: ${v.title}',
                                          },
                                        );
                                        if (!shouldAdvance) return;
                                        app.advanceSketchyRevision(v.id!);
                                      } else {
                                        // Already watched → show confidence sheet
                                        final isMicro = v.category.toLowerCase().contains('micro');
                                        final revId = isMicro
                                            ? 'sketchy-micro-${v.id}'
                                            : 'sketchy-pharm-${v.id}';
                                        final hasRev = app.revisionItems.any((r) => r.id == revId);
                                        if (hasRev) {
                                          showRevisionConfidenceSheet(
                                            context: context,
                                            revisionItemId: revId,
                                            title: v.title,
                                            source: isMicro ? 'SKETCHY_MICRO' : 'SKETCHY_PHARM',
                                          );
                                        } else {
                                          app.advanceSketchyRevision(v.id!);
                                        }
                                      }
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color:
                                          statusColor.withValues(alpha: 0.3)),
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
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                ),
                                builder: (_) => LibraryItemDetailSheet(
                                  app: context.read<AppProvider>(),
                                  item: v,
                                  itemType: 'sketchy',
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 3 — Pathoma
// ═══════════════════════════════════════════════════════════════

class _PathomaTab extends StatelessWidget {
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;
  const _PathomaTab({
    required this.selectionMode,
    required this.selectedItems,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final chapters = app.pathomaChapters;

        if (chapters.isEmpty) {
          return const _EmptyPlaceholder(
            icon: Icons.biotech_rounded,
            text: 'Pathoma chapters will appear here.',
          );
        }

        final cs = Theme.of(context).colorScheme;
        final watchedCount = chapters.where((c) => c.watched).length;
        final total = chapters.length;
        final progress = total > 0 ? watchedCount / total : 0.0;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$watchedCount / $total watched',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 72 + 24,
                ),
                itemCount: chapters.length,
                itemBuilder: (context, i) {
                  final ch = chapters[i];
                  final key = 'pathoma:${ch.id}';
                  final isSelected = selectedItems.contains(key);

                  if (selectionMode) {
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => onToggleSelect(key),
                      title: Text('Ch ${ch.chapter} — ${ch.title}'),
                      subtitle: ch.watched
                          ? Text('Watched ✓',
                              style: TextStyle(fontSize: 10, color: cs.primary))
                          : null,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: cs.primary,
                    );
                  }

                  // Status color / label based on revision progress
                  final skRevId = 'pathoma-ch-${ch.id}';
                  final ptRevIdx =
                      app.revisionItems.indexWhere((r) => r.id == skRevId);
                  final ptRevCount = ptRevIdx >= 0
                      ? app.revisionItems[ptRevIdx].currentRevisionIndex
                      : 0;

                  Color statusColor;
                  String statusLabel;
                  if (!ch.watched) {
                    statusColor = Colors.red.shade700;
                    statusLabel = 'Unwatched';
                  } else if (ptRevCount > 0) {
                    statusColor = Colors.blue;
                    statusLabel = 'Rev $ptRevCount';
                  } else {
                    statusColor = Colors.green;
                    statusLabel = 'Watched ✓';
                  }

                  return Slidable(
                    key: ValueKey('pathoma_${ch.id}'),
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      extentRatio: _twoActionPaneExtentRatio,
                      children: [
                        if (ch.watched)
                          SlidableAction(
                            onPressed: (_) => app.undoPathomaChapter(ch.id!),
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            icon: Icons.undo_rounded,
                            label: 'Undo',
                          ),
                        SlidableAction(
                          onPressed: (_) => app.resetPathomaChapter(ch.id!),
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          icon: Icons.restart_alt_rounded,
                          label: 'Reset',
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text('Ch ${ch.chapter} — ${ch.title}'),
                      trailing: InkWell(
                        onTap: ch.id != null
                            ? () async {
                                if (!ch.watched) {
                                  final shouldAdvance =
                                      await _confirmTodayTaskConflictForLibraryItem(
                                    context: context,
                                    app: app,
                                    itemId: ch.id!,
                                    candidateTitles: {
                                      'Pathoma Ch${ch.chapter}: ${ch.title}',
                                    },
                                  );
                                  if (!shouldAdvance) return;
                                  app.advancePathomaRevision(ch.id!);
                                } else {
                                  // Already watched → show confidence sheet
                                  final revId = 'pathoma-ch-${ch.id}';
                                  final hasRev = app.revisionItems.any((r) => r.id == revId);
                                  if (hasRev) {
                                    showRevisionConfidenceSheet(
                                      context: context,
                                      revisionItemId: revId,
                                      title: 'Ch ${ch.chapter} — ${ch.title}',
                                      source: 'PATHOMA',
                                    );
                                  } else {
                                    app.advancePathomaRevision(ch.id!);
                                  }
                                }
                              }
                            : null,
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
                      onTap: () {
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
                            item: ch,
                            itemType: 'pathoma',
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 4 — UWorld
// ═══════════════════════════════════════════════════════════════

class _UWorldTab extends StatelessWidget {
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;
  const _UWorldTab({
    required this.selectionMode,
    required this.selectedItems,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final topics = app.uworldTopics;

        if (topics.isEmpty) {
          return const _EmptyPlaceholder(
            icon: Icons.quiz_rounded,
            text: 'UWorld topics will appear here.',
          );
        }

        final cs = Theme.of(context).colorScheme;

        // Calculate totals
        int totalDone = 0;
        int totalQs = 0;
        int totalCorrect = 0;

        for (final t in topics) {
          totalDone += t.doneQuestions;
          totalQs += t.totalQuestions;
          totalCorrect += t.correctQuestions;
        }

        final overallPct =
            totalDone > 0 ? (totalCorrect * 100 ~/ totalDone) : 0;
        final overallProgress = totalQs > 0 ? totalDone / totalQs : 0.0;

        // Group by system
        final grouped = <String, List<UWorldTopic>>{};
        for (final t in topics) {
          grouped.putIfAbsent(t.system, () => []).add(t);
        }

        // Ensure consistent order (e.g. general principles first, then alphabetical)
        final systems = grouped.keys.toList()
          ..sort((a, b) {
            final aGen = a.contains('General Principles');
            final bGen = b.contains('General Principles');
            if (aGen && !bGen) return -1;
            if (!aGen && bGen) return 1;
            return a.compareTo(b);
          });

        return Column(
          children: [
            // Sticky Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: cs.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$totalDone / $totalQs done',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '$overallPct% accuracy',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: overallProgress,
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                ],
              ),
            ),

            // Body - ListView of Systems
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 72 + 24,
                ),
                itemCount: systems.length,
                itemBuilder: (context, i) {
                  final sys = systems[i];
                  final subs = grouped[sys]!;
                  final subtopicCount = subs.length;

                  int sysDone = 0;
                  int sysTotal = 0;
                  for (final s in subs) {
                    sysDone += s.doneQuestions;
                    sysTotal += s.totalQuestions;
                  }

                  return ExpansionTile(
                    title: Text(sys,
                        style: const TextStyle(fontWeight: FontWeight.w400)),
                    subtitle: Text(
                      '$subtopicCount ${subtopicCount == 1 ? 'subtopic' : 'subtopics'}',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    trailing: Text(
                      '$sysDone / $sysTotal',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    children: subs.map((sub) {
                      final subPct = sub.doneQuestions > 0
                          ? (sub.correctQuestions * 100 ~/ sub.doneQuestions)
                          : 0;
                      final subProgress = sub.totalQuestions > 0
                          ? sub.doneQuestions / sub.totalQuestions
                          : 0.0;
                      final key = 'uworld:${sub.id}';
                      final isUwSelected = selectedItems.contains(key);

                      if (selectionMode) {
                        return CheckboxListTile(
                          dense: true,
                          value: isUwSelected,
                          onChanged: (_) => onToggleSelect(key),
                          title: Text(sub.subtopic,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            '${sub.doneQuestions}/${sub.totalQuestions} done · $subPct%',
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: cs.primary,
                        );
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 4),
                        title: Text(
                          sub.subtopic,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: Text(
                                  '${sub.doneQuestions} / ${sub.totalQuestions}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: subProgress,
                                    minHeight: 4,
                                    backgroundColor: cs.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        cs.primary.withValues(alpha: 0.7)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                        trailing: sub.doneQuestions > 0
                            ? Chip(
                                label: Text('$subPct%'),
                                padding: EdgeInsets.zero,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w400,
                                ),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: cs.surfaceContainerHigh,
                                side: BorderSide.none,
                              )
                            : const SizedBox(width: 48), // Placeholder to align
                        onTap: () => _editSubtopicProgress(context, sub),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _editSubtopicProgress(BuildContext context, UWorldTopic sub) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UWorldDetailSheet(
        app: context.read<AppProvider>(),
        topic: sub,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Shared empty placeholder widget
// ═══════════════════════════════════════════════════════════════

class _AddFAPageSheet extends StatefulWidget {
  const _AddFAPageSheet();

  @override
  State<_AddFAPageSheet> createState() => _AddFAPageSheetState();
}

class _AddFAPageSheetState extends State<_AddFAPageSheet> {
  final _pageNumCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _subject;
  String? _system;
  String? _pageError;
  bool _saving = false;

  @override
  void dispose() {
    _pageNumCtrl.dispose();
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pageNumText = _pageNumCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    final pageNum = int.tryParse(pageNumText);

    setState(() {
      _pageError = pageNumText.isEmpty || pageNum == null
          ? 'Enter a valid page number'
          : null;
    });
    if (_pageError != null) return;

    final app = context.read<AppProvider>();
    if (app.faPages.any((p) => p.pageNum == pageNum)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Page already exists')),
      );
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final page = FAPage(
      pageNum: pageNum!,
      subject: _subject ?? '',
      system: _system ?? '',
      title: title,
      userDescription: notes.isEmpty ? null : notes,
      status: 'unread',
      orderIndex: pageNum,
    );

    await app.upsertFAPage(page);
    if (!mounted) return;

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('FA Page $pageNum added'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Add FA Page',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pageNumCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Page number',
                border: const OutlineInputBorder(),
                errorText: _pageError,
              ),
              onChanged: (_) {
                if (_pageError != null) {
                  setState(() => _pageError = null);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _subject,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
              items: kFmgeSubjects
                  .map((subject) => DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _subject = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _system,
              decoration: const InputDecoration(
                labelText: 'System',
                border: OutlineInputBorder(),
              ),
              items: kBodySystems
                  .map((system) => DropdownMenuItem<String>(
                        value: system,
                        child: Text(system),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _system = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title / Topic',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Notes',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Page'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddUWorldTopicSheet extends StatefulWidget {
  const _AddUWorldTopicSheet();

  @override
  State<_AddUWorldTopicSheet> createState() => _AddUWorldTopicSheetState();
}

class _AddUWorldTopicSheetState extends State<_AddUWorldTopicSheet> {
  final _topicNameCtrl = TextEditingController();
  final _totalQuestionsCtrl = TextEditingController();

  String? _system;
  String? _topicNameError;
  String? _totalQuestionsError;
  bool _saving = false;

  @override
  void dispose() {
    _topicNameCtrl.dispose();
    _totalQuestionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final topicName = _topicNameCtrl.text.trim();
    final totalQuestionsText = _totalQuestionsCtrl.text.trim();
    final totalQuestions = int.tryParse(totalQuestionsText);

    setState(() {
      _topicNameError = topicName.isEmpty ? 'Topic name is required' : null;
      _totalQuestionsError =
          totalQuestionsText.isEmpty || totalQuestions == null
              ? 'Enter a valid total questions value'
              : null;
    });
    if (_topicNameError != null || _totalQuestionsError != null) return;

    setState(() => _saving = true);
    final app = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final topic = UWorldTopic(
      system: _system ?? '',
      subtopic: topicName,
      totalQuestions: totalQuestions!,
      doneQuestions: 0,
      correctQuestions: 0,
    );

    await app.addUWorldTopic(topic);
    if (!mounted) return;

    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('UWorld topic added'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Add UWorld Topic',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _topicNameCtrl,
              decoration: InputDecoration(
                labelText: 'Topic name',
                border: const OutlineInputBorder(),
                errorText: _topicNameError,
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_topicNameError != null) {
                  setState(() => _topicNameError = null);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _system,
              decoration: const InputDecoration(
                labelText: 'System',
                border: OutlineInputBorder(),
              ),
              items: kBodySystems
                  .map((system) => DropdownMenuItem<String>(
                        value: system,
                        child: Text(system),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _system = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _totalQuestionsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Total questions',
                border: const OutlineInputBorder(),
                errorText: _totalQuestionsError,
              ),
              onChanged: (_) {
                if (_totalQuestionsError != null) {
                  setState(() => _totalQuestionsError = null);
                }
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Topic'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyPlaceholder({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Bulk Mark FA Pages Bottom Sheet
// ═══════════════════════════════════════════════════════════════

class _BulkMarkSheet extends StatefulWidget {
  const _BulkMarkSheet();

  @override
  State<_BulkMarkSheet> createState() => _BulkMarkSheetState();
}

class _BulkMarkSheetState extends State<_BulkMarkSheet> {
  late TextEditingController _fromCtrl;
  late TextEditingController _toCtrl;
  String _selectedStatus = 'read';
  String? _fromError;
  String? _toError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    final unreadPages = app.faPages.where((p) => p.status == 'unread').toList()
      ..sort((a, b) => a.pageNum.compareTo(b.pageNum));
    final lowestUnread =
        unreadPages.isNotEmpty ? unreadPages.first.pageNum : 31;
    _fromCtrl = TextEditingController(text: '$lowestUnread');
    _toCtrl =
        TextEditingController(text: '${(lowestUnread + 9).clamp(31, 706)}');
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final from = int.tryParse(_fromCtrl.text.trim());
    final to = int.tryParse(_toCtrl.text.trim());
    String? fErr;
    String? tErr;

    if (from == null || from < 31 || from > 706) {
      fErr = 'Must be between 31 and 706';
    }
    if (to == null || to > 706) {
      tErr = 'Must be ≤ 706';
    } else if (from != null && to < from) {
      tErr = 'Must be ≥ From page';
    }

    setState(() {
      _fromError = fErr;
      _toError = tErr;
    });
    return fErr == null && tErr == null;
  }

  bool get _isValid {
    final from = int.tryParse(_fromCtrl.text.trim());
    final to = int.tryParse(_toCtrl.text.trim());
    if (from == null || from < 31 || from > 706) return false;
    if (to == null || to > 706 || to < from) return false;
    return true;
  }

  Future<void> _confirm() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    final from = int.parse(_fromCtrl.text.trim());
    final to = int.parse(_toCtrl.text.trim());
    final app = context.read<AppProvider>();
    final count = await app.bulkMarkFAPages(from, to, _selectedStatus);
    if (!mounted) return;
    Navigator.of(context).pop();

    final statusLabel = _selectedStatus == 'read'
        ? 'Read'
        : (_selectedStatus == 'anki_done' ? 'Anki Done' : 'Unread');
    if (count >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Amazing! You read $count pages today! Keep going!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $count pages marked as $statusLabel')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Bulk Mark FA Pages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _fromCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'From Page',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {
                        _fromError = null;
                      }),
                    ),
                    if (_fromError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          _fromError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                          ),
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
                    TextField(
                      controller: _toCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'To Page',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {
                        _toError = null;
                      }),
                    ),
                    if (_toError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          _toError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Mark as',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'read', child: Text('Read')),
              DropdownMenuItem(value: 'anki_done', child: Text('Anki Done')),
              DropdownMenuItem(value: 'unread', child: Text('Unread (Reset)')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _selectedStatus = v);
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving || !_isValid ? null : _confirm,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Mark Pages'),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Add to Task — schedule selected items from tracker
// ═══════════════════════════════════════════════════════════════

class _AddToTaskSheet extends StatelessWidget {
  final Set<String> selectedItems;
  final VoidCallback onDone;
  const _AddToTaskSheet({required this.selectedItems, required this.onDone});

  static const _uuid = Uuid();

  String _dateKey(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  Future<void> _addToDate(BuildContext context, String dateKey) async {
    final app = context.read<AppProvider>();
    final existing = app.getDayPlan(dateKey);
    final existingBlocks = List<Block>.from(existing?.blocks ?? []);
    final newBlocks = <Block>[];

    for (final key in selectedItems) {
      final parts = key.split(':');
      if (parts.length < 2) continue;
      final type = parts[0];
      final id = parts.sublist(1).join(':');

      BlockType blockType;
      String title;

      switch (type) {
        case 'fa':
          blockType = BlockType.revisionFa;
          final pageNum = int.tryParse(id);
          if (pageNum != null) {
            final page = app.faPages.cast<FAPage?>().firstWhere(
                  (p) => p!.pageNum == pageNum,
                  orElse: () => null,
                );
            title = page != null
                ? 'FA Page $pageNum — ${page.title}'
                : 'FA Page $pageNum';
          } else {
            title = 'FA Page $id';
          }
          break;
        case 'sketchy':
          blockType = BlockType.video;
          final videoId = int.tryParse(id);
          SketchyVideo? video;
          if (videoId != null) {
            final allVideos = [
              ...app.sketchyMicroVideos,
              ...app.sketchyPharmVideos
            ];
            video = allVideos.cast<SketchyVideo?>().firstWhere(
                  (v) => v!.id == videoId,
                  orElse: () => null,
                );
          }
          title = video != null ? 'Sketchy: ${video.title}' : 'Sketchy Video';
          break;
        case 'pathoma':
          blockType = BlockType.video;
          final chId = int.tryParse(id);
          PathomaChapter? ch;
          if (chId != null) {
            ch = app.pathomaChapters.cast<PathomaChapter?>().firstWhere(
                  (c) => c!.id == chId,
                  orElse: () => null,
                );
          }
          title = ch != null
              ? 'Pathoma Ch${ch.chapter}: ${ch.title}'
              : 'Pathoma Chapter';
          break;
        case 'uworld':
          blockType = BlockType.qbank;
          final uwId = int.tryParse(id);
          UWorldTopic? topic;
          if (uwId != null) {
            topic = app.uworldTopics.cast<UWorldTopic?>().firstWhere(
                  (t) => t!.id == uwId,
                  orElse: () => null,
                );
          }
          title =
              topic != null ? 'UWorld: ${topic.subtopic}' : 'UWorld Questions';
          break;
        default:
          blockType = BlockType.other;
          title = 'Study Task';
      }

      newBlocks.add(Block(
        id: _uuid.v4(),
        index: existingBlocks.length + newBlocks.length,
        date: dateKey,
        plannedStartTime: '00:00',
        plannedEndTime: '00:00',
        type: blockType,
        title: title,
        relatedVideoId: blockType == BlockType.video ? id : null,
        plannedDurationMinutes: 0,
        status: BlockStatus.notStarted,
      ));
    }

    final allBlocks = [...existingBlocks, ...newBlocks];
    final plan = existing?.copyWith(blocks: allBlocks) ??
        DayPlan(
          date: dateKey,
          faPages: const [],
          faPagesCount: 0,
          videos: const [],
          notesFromUser: '',
          notesFromAI: '',
          attachments: const [],
          breaks: const [],
          blocks: allBlocks,
          totalStudyMinutesPlanned: 0,
          totalBreakMinutes: 0,
        );

    await app.upsertDayPlan(plan);
    await app.syncFlowActivitiesFromDayPlan(dateKey);

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${newBlocks.length} task${newBlocks.length == 1 ? '' : 's'} added to $dateKey',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final tomorrowKey = _dateKey(now.add(const Duration(days: 1)));

    // Count items by type
    int faCount = 0, sketchyCount = 0, pathomaCount = 0, uworldCount = 0;
    for (final key in selectedItems) {
      if (key.startsWith('fa:'))
        faCount++;
      else if (key.startsWith('sketchy:'))
        sketchyCount++;
      else if (key.startsWith('pathoma:'))
        pathomaCount++;
      else if (key.startsWith('uworld:')) uworldCount++;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add ${selectedItems.length} item${selectedItems.length == 1 ? '' : 's'} to plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // Summary chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              if (faCount > 0)
                Chip(
                  avatar: const Icon(Icons.menu_book_rounded, size: 16),
                  label: Text('$faCount FA page${faCount > 1 ? 's' : ''}'),
                  visualDensity: VisualDensity.compact,
                ),
              if (sketchyCount > 0)
                Chip(
                  avatar: const Icon(Icons.play_circle_rounded, size: 16),
                  label: Text('$sketchyCount Sketchy'),
                  visualDensity: VisualDensity.compact,
                ),
              if (pathomaCount > 0)
                Chip(
                  avatar: const Icon(Icons.biotech_rounded, size: 16),
                  label: Text('$pathomaCount Pathoma'),
                  visualDensity: VisualDensity.compact,
                ),
              if (uworldCount > 0)
                Chip(
                  avatar: const Icon(Icons.quiz_rounded, size: 16),
                  label: Text('$uworldCount UWorld'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _scheduleButton(
                  context: context,
                  icon: Icons.today_rounded,
                  label: 'Today',
                  sublabel: todayKey,
                  color: const Color(0xFF10B981),
                  onTap: () => _addToDate(context, todayKey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _scheduleButton(
                  context: context,
                  icon: Icons.upcoming_rounded,
                  label: 'Tomorrow',
                  sublabel: tomorrowKey,
                  color: const Color(0xFF6366F1),
                  onTap: () => _addToDate(context, tomorrowKey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now.add(const Duration(days: 2)),
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (picked != null && context.mounted) {
                  await _addToDate(context, _dateKey(picked));
                }
              },
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: const Text('Pick a Date'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _scheduleButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FA Card View — detailed cards with topic info
// ═══════════════════════════════════════════════════════════════

class _FACardView extends StatelessWidget {
  final AppProvider app;
  final List<FAPage> sorted;
  final bool selectionMode;
  final Set<String> selectedItems;
  final void Function(String key) onToggleSelect;

  const _FACardView({
    required this.app,
    required this.sorted,
    required this.selectionMode,
    required this.selectedItems,
    required this.onToggleSelect,
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

    final cs = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 72 + 24,
      ),
      itemCount: groupOrder.length,
      itemBuilder: (context, i) {
        final subject = groupOrder[i];
        final pages = grouped[subject]!;
        final readCount = pages.where((p) => p.status != 'unread').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      subject,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  Text(
                    '$readCount/${pages.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            ...pages.map((page) {
              final percent = app.getPageCompletionPercent(page.pageNum);
              final isFullyRead = page.status != 'unread';
              final isAnkiDone = page.status == 'anki_done';
              final subtopics = app.getSubtopicsForPage(page.pageNum);
              final readSubs =
                  subtopics.where((s) => s.status != 'unread').length;
              final key = 'fa:${page.pageNum}';
              final isSelected = selectedItems.contains(key);

              Color statusColor;
              String statusLabel;
              if (isAnkiDone) {
                statusColor = Colors.purple;
                statusLabel = 'Anki Done';
              } else if (isFullyRead || percent >= 1.0) {
                statusColor = Colors.green;
                statusLabel = 'Read';
              } else if (percent > 0) {
                statusColor = Colors.orange;
                statusLabel = '${(percent * 100).round()}%';
              } else {
                statusColor = Colors.red.shade700;
                statusLabel = 'Unread';
              }

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Slidable(
                  key: ValueKey(page.pageNum),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: _twoActionPaneExtentRatio,
                    children: [
                      if (page.status != 'unread')
                        SlidableAction(
                          onPressed: (_) => app.undoFAPage(page.pageNum),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          icon: Icons.undo_rounded,
                          label: 'Undo',
                          borderRadius: BorderRadius.circular(14),
                        ),
                      SlidableAction(
                        onPressed: (_) => app.resetFAPage(page.pageNum),
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        icon: Icons.restart_alt_rounded,
                        label: 'Reset',
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ],
                  ),
                  child: Material(
                    color: isSelected
                        ? cs.primary.withValues(alpha: 0.08)
                        : cs.surfaceContainerLow,
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
                                ? cs.primary
                                : cs.outlineVariant.withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
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
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                            ],
                            // Page number badge
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
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
                                    page.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${page.system} · $readSubs/${subtopics.length} subtopics',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status badge (now a button to advance)
                            InkWell(
                              onTap: selectionMode
                                  ? null
                                  : () {
                                      if (page.status == 'unread') {
                                        // First time — cycle to 'read'
                                        app.advanceFAPageRevision(page.pageNum);
                                      } else {
                                        // Already read/anki_done → show confidence sheet
                                        final revId = 'fa-page-${page.pageNum}';
                                        final hasRev = app.revisionItems.any((r) => r.id == revId);
                                        if (hasRev) {
                                          showRevisionConfidenceSheet(
                                            context: context,
                                            revisionItemId: revId,
                                            title: '${page.title} (p.${page.pageNum})',
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
                                      color:
                                          statusColor.withValues(alpha: 0.3)),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'R${page.revisionCount}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: cs.primary,
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
              );
            }),
          ],
        );
      },
    );
  }
}
