// =============================================================
// QuickStudySheet — start a free-form study session
// Timer + resource picker (FA pages, etc.)
// Auto-creates a block in the day plan when done
// =============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/fa_page.dart';
import 'package:focusflow_mobile/utils/constants.dart';

class QuickStudySheet extends StatefulWidget {
  const QuickStudySheet({super.key});

  @override
  State<QuickStudySheet> createState() => _QuickStudySheetState();
}

class _QuickStudySheetState extends State<QuickStudySheet> {
  bool _studying = false;
  Timer? _timer;
  int _elapsedSeconds = 0;
  DateTime? _startTime;

  // Pages studied during this session
  final List<_StudiedPage> _studiedPages = [];
  DateTime? _currentPageStart;
  int? _currentPageNum;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStudying() {
    setState(() {
      _studying = true;
      _startTime = DateTime.now();
      _elapsedSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _stopStudying() async {
    _timer?.cancel();
    // Finish current page if any
    if (_currentPageNum != null && _currentPageStart != null) {
      _studiedPages.add(_StudiedPage(
        pageNum: _currentPageNum!,
        seconds: DateTime.now().difference(_currentPageStart!).inSeconds,
      ));
    }
    // Auto-create a block in today's plan
    await _createStudyBlock();
    if (mounted) Navigator.pop(context);
  }

  void _selectFAPage() {
    final app = context.read<AppProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FAPagePicker(
        faPages: app.faPages,
        onSelect: (pageNum) {
          Navigator.pop(context);
          _switchToPage(pageNum);
        },
      ),
    );
  }

  void _switchToPage(int pageNum) {
    // Save time for previous page
    if (_currentPageNum != null && _currentPageStart != null) {
      _studiedPages.add(_StudiedPage(
        pageNum: _currentPageNum!,
        seconds: DateTime.now().difference(_currentPageStart!).inSeconds,
      ));
    }
    setState(() {
      _currentPageNum = pageNum;
      _currentPageStart = DateTime.now();
    });
  }

  Future<void> _createStudyBlock() async {
    if (_elapsedSeconds < 10) return; // Skip very short sessions
    final app = context.read<AppProvider>();
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final startStr =
        '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final durationMin = (_elapsedSeconds / 60).ceil();

    // Build tasks from studied pages
    final tasks = _studiedPages.map((sp) {
      return BlockTask(
        id: const Uuid().v4(),
        type: 'FA_PAGE',
        detail: 'FA p.${sp.pageNum}',
        completed: true,
      );
    }).toList();

    final existingPlan = app.getDayPlan(dateStr);
    final existingBlocks = List<Block>.from(existingPlan?.blocks ?? []);

    final block = Block(
      id: const Uuid().v4(),
      index: existingBlocks.length,
      date: dateStr,
      title: 'Quick Study${_studiedPages.isNotEmpty ? ' (${_studiedPages.length} pages)' : ''}',
      type: BlockType.revisionFa,
      status: BlockStatus.done,
      plannedStartTime: startStr,
      plannedEndTime: endStr,
      plannedDurationMinutes: durationMin,
      actualStartTime: _startTime!.toIso8601String(),
      actualEndTime: now.toIso8601String(),
      tasks: tasks,
    );

    existingBlocks.add(block);

    // Add to today's day plan
    if (existingPlan != null) {
      await app.upsertDayPlan(existingPlan.copyWith(blocks: existingBlocks));
    } else {
      final plan = DayPlan(
        date: dateStr,
        faPages: const [],
        faPagesCount: 0,
        videos: const [],
        notesFromUser: '',
        notesFromAI: '',
        attachments: const [],
        breaks: const [],
        blocks: existingBlocks,
        totalStudyMinutesPlanned: durationMin,
        totalBreakMinutes: 0,
      );
      await app.upsertDayPlan(plan);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Study session saved — ${durationMin}min${_studiedPages.isNotEmpty ? ', ${_studiedPages.length} pages' : ''}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatElapsed(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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
            _studying ? 'Studying...' : 'Quick Study',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 20),

          if (!_studying) ...[
            // Pre-study screen
            Icon(Icons.menu_book_rounded,
                size: 48, color: cs.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'Start a free-form study session.\nYou can add FA pages as you study.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _startStudying,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Studying'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ] else ...[
            // Timer display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: cs.primary.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  Text(
                    _formatElapsed(_elapsedSeconds),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (_currentPageNum != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Currently on FA p.$_currentPageNum',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Studied pages list
            if (_studiedPages.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pages studied:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _studiedPages.map((sp) {
                  return Chip(
                    label: Text(
                      'p.${sp.pageNum} (${(sp.seconds / 60).ceil()}m)',
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectFAPage,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Page'),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _stopStudying,
                    icon: const Icon(Icons.stop_rounded, size: 18),
                    label: const Text('Stop'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StudiedPage {
  final int pageNum;
  final int seconds;
  const _StudiedPage({required this.pageNum, required this.seconds});
}

/// Simple FA page picker for quick study mode
class _FAPagePicker extends StatefulWidget {
  final List<FAPage> faPages;
  final ValueChanged<int> onSelect;
  const _FAPagePicker({required this.faPages, required this.onSelect});

  @override
  State<_FAPagePicker> createState() => _FAPagePickerState();
}

class _FAPagePickerState extends State<_FAPagePicker> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<FAPage> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.faPages;
    _searchCtrl.addListener(_filter);
  }

  void _filter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = widget.faPages;
      } else {
        final numQuery = int.tryParse(q);
        _filtered = widget.faPages.where((p) {
          if (numQuery != null) return p.pageNum.toString().contains(q);
          return p.title.toLowerCase().contains(q) ||
              p.subject.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by page # or topic...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final page = _filtered[i];
                return ListTile(
                  dense: true,
                  title: Text('p.${page.pageNum}  ${page.title}'),
                  subtitle: Text(
                    page.subject,
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                  onTap: () => widget.onSelect(page.pageNum),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
