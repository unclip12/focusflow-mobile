// =============================================================
// TrackerScreen — G5 unified tracker with 4 tabs
// FA 2025 | Sketchy | Pathoma | UWorld
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/models/fa_subtopic.dart';
import 'package:focusflow_mobile/models/sketchy_video.dart';
import 'package:focusflow_mobile/models/uworld_topic.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: const Text('Tracker'),
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
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FATab(),
          _SketchyTab(),
          _PathomaTab(),
          _UWorldTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
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
  const _FATab();

  @override
  State<_FATab> createState() => _FATabState();
}

class _FATabState extends State<_FATab> {
  bool _showSubtopicView = false;

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
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.grid_view_rounded, size: 16),
                        label: Text('Pages', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.list_rounded, size: 16),
                        label: Text('Topics', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    selected: {_showSubtopicView},
                    onSelectionChanged: (v) =>
                        setState(() => _showSubtopicView = v.first),
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ────────────────────────────────────────
            Expanded(
              child: _showSubtopicView
                  ? _SubtopicListView(app: app)
                  : _PageGridView(app: app, sorted: sorted),
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
  const _PageGridView({required this.app, required this.sorted});

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
                  return _LiquidFillPageBox(
                    page: page,
                    app: app,
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
  const _LiquidFillPageBox({required this.page, required this.app});

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
      onTap: () => _showSubtopicPicker(context),
      onLongPress: () => _showDetailPopup(context),
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
  const _SketchyTab();

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
                    ),
                    _SketchyVideoList(
                      videos: app.sketchyPharmVideos,
                      onToggle: (id, watched) =>
                          app.toggleSketchyPharmWatched(id, watched),
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

  const _SketchyVideoList({
    required this.videos,
    required this.onToggle,
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
  const _PathomaTab();

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
  const _UWorldTab();

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

    final statusLabel = _selectedStatus == 'read' ? 'Read' : 'Anki Done';
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
            initialValue: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Mark as',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'read', child: Text('Read')),
              DropdownMenuItem(value: 'anki_done', child: Text('Anki Done')),
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
