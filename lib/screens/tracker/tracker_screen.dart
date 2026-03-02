// =============================================================
// TrackerScreen — G5 unified tracker with 4 tabs
// FA 2025 | Sketchy | Pathoma | UWorld
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/models/fa_subtopic.dart';
import 'package:focusflow_mobile/models/pathoma_chapter.dart';
import 'package:focusflow_mobile/models/sketchy_video.dart';
import 'package:focusflow_mobile/models/uworld_topic.dart';
import 'package:focusflow_mobile/utils/constants.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
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
        title: Text(_selectionMode
            ? '${_selectedItems.length} selected'
            : 'Library'),
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
                border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 20, color: cs.primary),
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
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

        final readCount =
            sorted.where((p) => p.status != 'unread').length;
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
                            value: totalPages > 0
                                ? readCount / totalPages
                                : 0,
                            minHeight: 6,
                            backgroundColor:
                                cs.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.green),
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
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: groupOrder.length,
      itemBuilder: (context, i) {
        final subject = groupOrder[i];
        final pages = grouped[subject]!;
        final readCount =
            pages.where((p) => p.status != 'unread').length;
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
                      onToggleSelect: () => onToggleSelect('fa:${page.pageNum}'),
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
      onTap: selectionMode ? onToggleSelect : () => _showSubtopicPicker(context),
      onLongPress: selectionMode ? null : () => _showDetailPopup(context),
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
                          color: (isAnkiDone
                                  ? Colors.purple
                                  : Colors.green)
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
                  color: percent > 0 && percent < 1.0
                      ? cs.onSurface
                      : textColor,
                ),
              ),
            ),

            // Revision badge
            if (page.revisionCount > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
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
          content: const Text(
              'This will clear the read history for this page.'),
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

  void _showDetailPopup(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subtopics = app.getSubtopicsForPage(page.pageNum);
    final readSubs = subtopics.where((s) => s.status != 'unread').length;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Page ${page.pageNum} — ${page.title}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            Text(
              '${page.subject} • ${page.system}',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow('Status', page.status.toUpperCase(), cs),
            _detailRow('Subtopics',
                '$readSubs / ${subtopics.length} done', cs),
            if (page.firstReadAt != null)
              _detailRow('First Read', _formatDate(page.firstReadAt!), cs),
            if (page.ankiDoneAt != null)
              _detailRow('Anki Done', _formatDate(page.ankiDoneAt!), cs),
            _detailRow(
                'Revisions', 'R${page.revisionCount}', cs),
            if (page.revisionHistory.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Revision History',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  )),
              const SizedBox(height: 4),
              ...page.revisionHistory.map((r) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Text(
                      'R${r.revisionNum}: ${_formatDate(r.date)}',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  )),
            ],
            const SizedBox(height: 16),
            if (page.status == 'anki_done')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _cyclePageStatus(context);
                  },
                  child: const Text('Mark as Unread'),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
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

  bool get _allSelected =>
      _subtopics.every((s) => _selected.contains(s.id));

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
      if (s.id != null &&
          _selected.contains(s.id!) &&
          s.status == 'unread') {
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
          20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
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
                      decoration: alreadyRead
                          ? TextDecoration.lineThrough
                          : null,
                      color: alreadyRead
                          ? cs.onSurfaceVariant
                          : cs.onSurface,
                    ),
                  ),
                  subtitle: alreadyRead
                      ? Text(
                          st.status == 'anki_done'
                              ? 'Anki ✓'
                              : 'Read ✓',
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
      padding: const EdgeInsets.only(bottom: 80),
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

        return ListTile(
          dense: true,
          title: Text(
            st.name,
            style: const TextStyle(fontSize: 13),
          ),
          subtitle: Text(
            'Page ${st.pageNum}',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
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
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
            padding: const EdgeInsets.only(bottom: 80),
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
                    final subWatched =
                        items.where((v) => v.watched).length;
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
                                    style: TextStyle(fontSize: 10, color: cs.primary))
                                : null,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: cs.primary,
                          );
                        }
                        return CheckboxListTile(
                          dense: true,
                          value: v.watched,
                          onChanged: (val) {
                            final id = v.id;
                            if (id != null) {
                              onToggle(id, val ?? false);
                            }
                          },
                          title: Text(
                            v.title,
                            style: const TextStyle(fontSize: 13),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: cs.primary,
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
                padding: const EdgeInsets.only(bottom: 80),
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

                  return CheckboxListTile(
                    value: ch.watched,
                    onChanged: (val) {
                      final id = ch.id;
                      if (id != null) {
                        app.togglePathomaChapterWatched(id, val ?? false);
                      }
                    },
                    title: Text('Ch ${ch.chapter} — ${ch.title}'),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: cs.primary,
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
        
        final overallPct = totalDone > 0 ? (totalCorrect * 100 ~/ totalDone) : 0;
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
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '$overallPct% accuracy',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: systems.length,
                itemBuilder: (context, i) {
                  final sys = systems[i];
                  final subs = grouped[sys]!;
                  
                  int sysDone = 0;
                  int sysTotal = 0;
                  for (final s in subs) {
                    sysDone += s.doneQuestions;
                    sysTotal += s.totalQuestions;
                  }
                  
                  return ExpansionTile(
                    title: Text(sys, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text(
                      '$sysDone / $sysTotal',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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
                          title: Text(sub.subtopic, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            '${sub.doneQuestions}/${sub.totalQuestions} done · $subPct%',
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: cs.primary,
                        );
                      }
                          
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary.withValues(alpha: 0.7)),
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
                                  fontWeight: FontWeight.w600,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditUWorldProgressSheet(topic: sub),
    );
  }
}

class _EditUWorldProgressSheet extends StatefulWidget {
  final UWorldTopic topic;
  const _EditUWorldProgressSheet({required this.topic});

  @override
  State<_EditUWorldProgressSheet> createState() => _EditUWorldProgressSheetState();
}

class _EditUWorldProgressSheetState extends State<_EditUWorldProgressSheet> {
  late int _done;
  late int _correct;

  @override
  void initState() {
    super.initState();
    _done = widget.topic.doneQuestions;
    _correct = widget.topic.correctQuestions;
  }

  void _updateDone(int delta) {
    setState(() {
      _done = (_done + delta).clamp(0, widget.topic.totalQuestions);
      _correct = _correct.clamp(0, _done); // Correct can't exceed done
    });
  }

  void _updateCorrect(int delta) {
    setState(() {
      _correct = (_correct + delta).clamp(0, _done);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            widget.topic.subtopic,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.topic.system,
            style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 28),
          
          // Row 1: Done
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Questions done:',
                style: TextStyle(fontSize: 16, color: cs.onSurface),
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _done > 0 ? () => _updateDone(-1) : null,
                    icon: const Icon(Icons.remove),
                    iconSize: 20,
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '$_done',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _done < widget.topic.totalQuestions ? () => _updateDone(1) : null,
                    icon: const Icon(Icons.add),
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Row 2: Correct
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Correct:',
                style: TextStyle(fontSize: 16, color: cs.onSurface),
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _correct > 0 ? () => _updateCorrect(-1) : null,
                    icon: const Icon(Icons.remove),
                    iconSize: 20,
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '$_correct',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _correct < _done ? () => _updateCorrect(1) : null,
                    icon: const Icon(Icons.add),
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final app = context.read<AppProvider>();
                app.updateUWorldProgress(widget.topic.id!, _done, _correct);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Shared empty placeholder widget
// ═══════════════════════════════════════════════════════════════

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
    final unreadPages = app.faPages
        .where((p) => p.status == 'unread')
        .toList()
      ..sort((a, b) => a.pageNum.compareTo(b.pageNum));
    final lowestUnread = unreadPages.isNotEmpty ? unreadPages.first.pageNum : 31;
    _fromCtrl = TextEditingController(text: '$lowestUnread');
    _toCtrl = TextEditingController(text: '${(lowestUnread + 9).clamp(31, 706)}');
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

    final statusLabel = _selectedStatus == 'read' ? 'Read' : (_selectedStatus == 'anki_done' ? 'Anki Done' : 'Unread');
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
        24 + MediaQuery.of(context).viewInsets.bottom,
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
            // ignore: deprecated_member_use
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
            final allVideos = [...app.sketchyMicroVideos, ...app.sketchyPharmVideos];
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
          title = topic != null
              ? 'UWorld: ${topic.subtopic}'
              : 'UWorld Questions';
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
        plannedDurationMinutes: 0,
        status: BlockStatus.notStarted,
      ));
    }

    final allBlocks = [...existingBlocks, ...newBlocks];
    final plan = existing?.copyWith(blocks: allBlocks) ?? DayPlan(
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
      if (key.startsWith('fa:')) faCount++;
      else if (key.startsWith('sketchy:')) sketchyCount++;
      else if (key.startsWith('pathoma:')) pathomaCount++;
      else if (key.startsWith('uworld:')) uworldCount++;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
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
      padding: const EdgeInsets.only(bottom: 80),
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
              final readSubs = subtopics.where((s) => s.status != 'unread').length;
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Material(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.08)
                      : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: selectionMode
                        ? () => onToggleSelect(key)
                        : null,
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
                              color: isSelected ? cs.primary : cs.onSurfaceVariant,
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
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
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
              );
            }),
          ],
        );
      },
    );
  }
}
