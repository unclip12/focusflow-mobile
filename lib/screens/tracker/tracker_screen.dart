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
import 'package:focusflow_mobile/models/sketchy_item.dart';
import 'package:focusflow_mobile/models/pathoma_item.dart';
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
// TAB 2 — Sketchy
// ═══════════════════════════════════════════════════════════════

class _SketchyTab extends StatelessWidget {
  const _SketchyTab();

  static const _statusCycle = ['unwatched', 'watched', 'mastered'];

  String _nextStatus(String current) {
    final idx = _statusCycle.indexOf(current);
    return _statusCycle[(idx + 1) % _statusCycle.length];
  }

  Color _chipColor(String status, ColorScheme cs) {
    switch (status) {
      case 'watched':
        return Colors.amber;
      case 'mastered':
        return Colors.green;
      default:
        return cs.outlineVariant;
    }
  }

  String _chipLabel(String status) {
    switch (status) {
      case 'watched':
        return 'Watched';
      case 'mastered':
        return 'Mastered';
      default:
        return 'Unwatched';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        if (app.sketchyItems.isEmpty) {
          return const _EmptyPlaceholder(
            icon: Icons.videocam_rounded,
            text: 'Sketchy items will appear here.',
          );
        }

        // Separate by type
        final micro = app.sketchyItems
            .where((i) => i.type == 'micro')
            .toList();
        final pharma = app.sketchyItems
            .where((i) => i.type == 'pharma')
            .toList();

        return ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            if (micro.isNotEmpty)
              _SketchySection(
                title: 'Micro',
                items: micro,
                nextStatus: _nextStatus,
                chipColor: _chipColor,
                chipLabel: _chipLabel,
              ),
            if (pharma.isNotEmpty)
              _SketchySection(
                title: 'Pharma',
                items: pharma,
                nextStatus: _nextStatus,
                chipColor: _chipColor,
                chipLabel: _chipLabel,
              ),
          ],
        );
      },
    );
  }
}

class _SketchySection extends StatelessWidget {
  final String title;
  final List<SketchyItem> items;
  final String Function(String) nextStatus;
  final Color Function(String, ColorScheme) chipColor;
  final String Function(String) chipLabel;

  const _SketchySection({
    required this.title,
    required this.items,
    required this.nextStatus,
    required this.chipColor,
    required this.chipLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Group by category
    final grouped = <String, List<SketchyItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    final categories = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ),
        ...categories.map((cat) {
          final catItems = grouped[cat]!;
          return ExpansionTile(
            title: Text(cat),
            children: catItems.map((item) {
              return ListTile(
                dense: true,
                title: Text(item.name),
                trailing: ActionChip(
                  label: Text(
                    chipLabel(item.status),
                    style: TextStyle(
                      color: item.status == 'unwatched'
                          ? cs.onSurfaceVariant
                          : Colors.white,
                      fontSize: 11,
                    ),
                  ),
                  backgroundColor: chipColor(item.status, cs),
                  onPressed: () {
                    context
                        .read<AppProvider>()
                        .updateSketchyStatus(item.id, nextStatus(item.status));
                  },
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 3 — Pathoma
// ═══════════════════════════════════════════════════════════════

class _PathomaTab extends StatelessWidget {
  const _PathomaTab();

  static const _statusCycle = ['unwatched', 'watched', 'reviewed'];

  String _nextStatus(String current) {
    final idx = _statusCycle.indexOf(current);
    return _statusCycle[(idx + 1) % _statusCycle.length];
  }

  Color _chipColor(String status, ColorScheme cs) {
    switch (status) {
      case 'watched':
        return cs.primary;
      case 'reviewed':
        return Colors.green;
      default:
        return cs.outlineVariant;
    }
  }

  String _chipLabel(String status) {
    switch (status) {
      case 'watched':
        return 'Watched';
      case 'reviewed':
        return 'Reviewed';
      default:
        return 'Unwatched';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        if (app.pathomaItems.isEmpty) {
          return const _EmptyPlaceholder(
            icon: Icons.biotech_rounded,
            text: 'Pathoma chapters will appear here.',
          );
        }

        final sorted = List<PathomaItem>.from(app.pathomaItems)
          ..sort((a, b) => a.chapter.compareTo(b.chapter));

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: sorted.length,
          itemBuilder: (context, i) {
            final item = sorted[i];
            final cs = Theme.of(context).colorScheme;

            return ListTile(
              title: Text('Ch ${item.chapter} — ${item.title}'),
              trailing: ActionChip(
                label: Text(
                  _chipLabel(item.status),
                  style: TextStyle(
                    color: item.status == 'unwatched'
                        ? cs.onSurfaceVariant
                        : Colors.white,
                    fontSize: 11,
                  ),
                ),
                backgroundColor: _chipColor(item.status, cs),
                onPressed: () {
                  app.updatePathomaStatus(item.id, _nextStatus(item.status));
                },
              ),
            );
          },
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
