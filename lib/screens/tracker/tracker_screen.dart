// =============================================================
// TrackerScreen — G5 unified tracker with 4 tabs
// FA 2025 | Sketchy | Pathoma | UWorld
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/models/sketchy_video.dart';
import 'package:focusflow_mobile/models/uworld_session.dart';
import 'package:focusflow_mobile/utils/constants.dart';

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
                            if (v.id != null) {
                              onToggle(v.id!, val ?? false);
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
        // Use G6 pathomaChapters if available, fall back to old pathomaItems
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
            // Chapter list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: chapters.length,
                itemBuilder: (context, i) {
                  final ch = chapters[i];
                  return CheckboxListTile(
                    value: ch.watched,
                    onChanged: (val) {
                      if (ch.id != null) {
                        app.togglePathomaChapterWatched(
                            ch.id!, val ?? false);
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
    final cs = Theme.of(context).colorScheme;

    return Consumer<AppProvider>(
      builder: (context, app, _) {
        // Aggregate per subject
        final totals = <String, _SubjectStats>{};
        for (final subj in kFmgeSubjects) {
          totals[subj] = _SubjectStats(0, 0);
        }
        for (final s in app.uWorldSessions) {
          final current = totals[s.subject];
          if (current != null) {
            totals[s.subject] =
                _SubjectStats(current.done + s.done, current.correct + s.correct);
          }
        }

        // Grand total
        int totalDone = 0;
        for (final v in totals.values) {
          totalDone += v.done;
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            // Summary card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.quiz_rounded, color: cs.primary, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Questions',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '$totalDone done',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Per-subject list
            ...kFmgeSubjects.map((subj) {
              final stats = totals[subj]!;
              final pct = stats.done > 0
                  ? (stats.correct * 100 ~/ stats.done)
                  : 0;
              final subtitle = stats.done > 0
                  ? '${stats.done}q done · $pct% correct'
                  : '0q done';

              return ListTile(
                title: Text(subj),
                subtitle: Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded,
                      color: cs.primary),
                  onPressed: () =>
                      _showAddSessionSheet(context, subj),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _showAddSessionSheet(BuildContext context, String subject) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddUWorldSessionSheet(subject: subject),
    );
  }
}

class _SubjectStats {
  final int done;
  final int correct;
  const _SubjectStats(this.done, this.correct);
}

// ── Add UWorld Session Bottom Sheet ──────────────────────────────

class _AddUWorldSessionSheet extends StatefulWidget {
  final String subject;
  const _AddUWorldSessionSheet({required this.subject});

  @override
  State<_AddUWorldSessionSheet> createState() =>
      _AddUWorldSessionSheetState();
}

class _AddUWorldSessionSheetState extends State<_AddUWorldSessionSheet> {
  final _doneCtrl = TextEditingController();
  final _correctCtrl = TextEditingController();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _doneCtrl.dispose();
    _correctCtrl.dispose();
    super.dispose();
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
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Log UWorld Session',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subject,
            style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _doneCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Questions Done',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _correctCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Correct',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
              ),
              child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final done = int.tryParse(_doneCtrl.text.trim()) ?? 0;
                final correct =
                    int.tryParse(_correctCtrl.text.trim()) ?? 0;
                if (done <= 0) return;

                final session = UWorldSession(
                  id: const Uuid().v4(),
                  subject: widget.subject,
                  done: done,
                  correct: correct,
                  date: DateFormat('yyyy-MM-dd').format(_selectedDate),
                );
                context.read<AppProvider>().addUWorldSession(session);
                Navigator.of(context).pop();
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
    // Find lowest unread page
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
          // Drag handle
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
          // From / To fields side by side
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
          // Status dropdown
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
