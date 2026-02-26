// =============================================================
// TrackerScreen — G5 unified tracker with 4 tabs
// FA 2025 | Sketchy | Pathoma | UWorld
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
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
// TAB 1 — FA 2025
// ═══════════════════════════════════════════════════════════════

class _FATab extends StatelessWidget {
  const _FATab();

  static const _statusCycle = ['unread', 'read', 'anki_done'];

  String _nextStatus(String current) {
    final idx = _statusCycle.indexOf(current);
    return _statusCycle[(idx + 1) % _statusCycle.length];
  }

  Color _chipColor(String status, ColorScheme cs) {
    switch (status) {
      case 'read':
        return cs.primary;
      case 'anki_done':
        return Colors.green;
      default:
        return cs.outlineVariant;
    }
  }

  String _chipLabel(String status) {
    switch (status) {
      case 'read':
        return 'Read';
      case 'anki_done':
        return 'Anki ✓';
      default:
        return 'Unread';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        if (app.faPages.isEmpty) {
          return _EmptyPlaceholder(
            icon: Icons.menu_book_rounded,
            text: 'No FA pages loaded yet.\nSeed data coming in G6.',
          );
        }

        // Group by subject
        final grouped = <String, List<FAPage>>{};
        for (final p in app.faPages) {
          grouped.putIfAbsent(p.subject, () => []).add(p);
        }
        // Sort subjects
        final subjects = grouped.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: subjects.length,
          itemBuilder: (context, i) {
            final subject = subjects[i];
            final pages = grouped[subject]!
              ..sort((a, b) => a.pageNum.compareTo(b.pageNum));
            final readCount =
                pages.where((p) => p.status != 'unread').length;

            return ExpansionTile(
              title: Text(subject),
              subtitle: Text(
                '$readCount / ${pages.length} read',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              children: pages.map((page) {
                final cs = Theme.of(context).colorScheme;
                return ListTile(
                  dense: true,
                  title: Text('p.${page.pageNum}  ${page.title}'),
                  trailing: ActionChip(
                    label: Text(
                      _chipLabel(page.status),
                      style: TextStyle(
                        color: page.status == 'unread'
                            ? cs.onSurfaceVariant
                            : Colors.white,
                        fontSize: 11,
                      ),
                    ),
                    backgroundColor: _chipColor(page.status, cs),
                    onPressed: () {
                      app.updateFAPageStatus(
                        page.pageNum,
                        _nextStatus(page.status),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
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
            value: _selectedStatus,
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
