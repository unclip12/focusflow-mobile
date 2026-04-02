// =============================================================
// TrackerSheets — extracted bottom-sheet widgets for tracker
// AddFAPageSheet, AddUWorldTopicSheet, BulkMarkSheet,
// AddToTaskSheet, SubtopicPickerSheet
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

// ── Confirm today-task conflict ────────────────────────────────
Future<bool> confirmTodayTaskConflictForLibraryItem({
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

// ── Slidable extent constants ──────────────────────────────────
const double slidableActionExtentRatio = 0.28;
const double twoActionPaneExtentRatio = slidableActionExtentRatio * 2;

// ═══════════════════════════════════════════════════════════════
// Subtopic Picker Sheet
// ═══════════════════════════════════════════════════════════════

class SubtopicPickerSheet extends StatefulWidget {
  final int pageNum;
  final FAPage page;
  final AppProvider app;
  const SubtopicPickerSheet({
    super.key,
    required this.pageNum,
    required this.page,
    required this.app,
  });

  @override
  State<SubtopicPickerSheet> createState() => _SubtopicPickerSheetState();
}

class _SubtopicPickerSheetState extends State<SubtopicPickerSheet> {
  late List<FASubtopic> _subtopics;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _subtopics = widget.app.getSubtopicsForPage(widget.pageNum);
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

// ═══════════════════════════════════════════════════════════════
// Add FA Page Sheet
// ═══════════════════════════════════════════════════════════════

class AddFAPageSheet extends StatefulWidget {
  const AddFAPageSheet({super.key});

  @override
  State<AddFAPageSheet> createState() => _AddFAPageSheetState();
}

class _AddFAPageSheetState extends State<AddFAPageSheet> {
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
              // ignore: deprecated_member_use
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
              // ignore: deprecated_member_use
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

// ═══════════════════════════════════════════════════════════════
// Add UWorld Topic Sheet
// ═══════════════════════════════════════════════════════════════

class AddUWorldTopicSheet extends StatefulWidget {
  const AddUWorldTopicSheet({super.key});

  @override
  State<AddUWorldTopicSheet> createState() => _AddUWorldTopicSheetState();
}

class _AddUWorldTopicSheetState extends State<AddUWorldTopicSheet> {
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
              // ignore: deprecated_member_use
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

// ═══════════════════════════════════════════════════════════════
// Bulk Mark FA Pages Sheet
// ═══════════════════════════════════════════════════════════════

class BulkMarkSheet extends StatefulWidget {
  const BulkMarkSheet({super.key});

  @override
  State<BulkMarkSheet> createState() => _BulkMarkSheetState();
}

class _BulkMarkSheetState extends State<BulkMarkSheet> {
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
// Add to Task Sheet
// ═══════════════════════════════════════════════════════════════

class AddToTaskSheet extends StatelessWidget {
  final Set<String> selectedItems;
  final VoidCallback onDone;
  const AddToTaskSheet(
      {super.key, required this.selectedItems, required this.onDone});

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
