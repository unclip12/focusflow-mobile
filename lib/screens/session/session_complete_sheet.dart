// =============================================================
// SessionCompleteSheet — bottom sheet shown after ending a session.
// Type-specific form, KB updates, revision scheduling.
// =============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:focusflow_mobile/models/day_plan.dart';
import 'package:focusflow_mobile/models/knowledge_base.dart';
import 'package:focusflow_mobile/models/revision_item.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/utils/constants.dart';

const _uuid = Uuid();

/// Show the completion sheet. Called from SessionScreen.
void showSessionCompleteSheet(
  BuildContext context, {
  required Block block,
  required int blockIndex,
  required String dayPlanDate,
  required DateTime startedAt,
  required DateTime endedAt,
  required int elapsedSeconds,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CompletionSheet(
      block: block,
      blockIndex: blockIndex,
      dayPlanDate: dayPlanDate,
      startedAt: startedAt,
      endedAt: endedAt,
      elapsedSeconds: elapsedSeconds,
    ),
  );
}

// ══════════════════════════════════════════════════════════════════

class _CompletionSheet extends StatefulWidget {
  final Block block;
  final int blockIndex;
  final String dayPlanDate;
  final DateTime startedAt;
  final DateTime endedAt;
  final int elapsedSeconds;

  const _CompletionSheet({
    required this.block,
    required this.blockIndex,
    required this.dayPlanDate,
    required this.startedAt,
    required this.endedAt,
    required this.elapsedSeconds,
  });

  @override
  State<_CompletionSheet> createState() => _CompletionSheetState();
}

class _CompletionSheetState extends State<_CompletionSheet> {
  // ── Common controllers ──────────────────────────────────────
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  // ── FA-specific ─────────────────────────────────────────────
  late TextEditingController _pagesCtrl;
  double _coveragePercent = 50;
  final _subtopicsCtrl = TextEditingController();
  List<String> _subtopicChips = [];

  // ── Video-specific ──────────────────────────────────────────
  late TextEditingController _minutesWatchedCtrl;
  late TextEditingController _topicCtrl;

  // ── QBank-specific ──────────────────────────────────────────
  final _questionsCtrl = TextEditingController();
  final _correctCtrl = TextEditingController();

  // ── Anki-specific ───────────────────────────────────────────
  final _cardsCtrl = TextEditingController();

  String get _taskType {
    // Check block tasks first
    if (widget.block.tasks != null && widget.block.tasks!.isNotEmpty) {
      return widget.block.tasks!.first.type;
    }
    // Fall back to block type
    switch (widget.block.type) {
      case BlockType.revisionFa:
        return 'FA';
      case BlockType.video:
        return 'VIDEO';
      case BlockType.qbank:
        return 'QBANK';
      case BlockType.anki:
        return 'ANKI';
      case BlockType.fmgeRevision:
        return 'FMGE';
      default:
        return 'OTHER';
    }
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill from block data
    final meta = widget.block.tasks?.isNotEmpty == true
        ? widget.block.tasks!.first.meta
        : null;

    _pagesCtrl = TextEditingController(
        text: meta?.pageNumber?.toString() ?? '');
    _minutesWatchedCtrl = TextEditingController(
        text: (widget.elapsedSeconds ~/ 60).toString());
    _topicCtrl = TextEditingController(
        text: meta?.topic ?? widget.block.title);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _pagesCtrl.dispose();
    _subtopicsCtrl.dispose();
    _minutesWatchedCtrl.dispose();
    _topicCtrl.dispose();
    _questionsCtrl.dispose();
    _correctCtrl.dispose();
    _cardsCtrl.dispose();
    super.dispose();
  }

  String _formatDuration(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  // ── Save logic ──────────────────────────────────────────────
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final app = context.read<AppProvider>();
    final now = DateTime.now();
    final mode = app.revisionSettings?.mode ?? 'strict';

    try {
      // 1. FA-specific: update KB entries and create revision items
      if (_taskType == 'FA' || _taskType == 'FMGE' || _taskType == 'REVISION') {
        await _saveFAEntries(app, now, mode);
      }

      // 2. Update block status to 'done' in DayPlan
      await _updateBlockStatus(app);

      // 3. Handle coverage < 100% for FA tasks
      if ((_taskType == 'FA' || _taskType == 'FMGE' || _taskType == 'REVISION') &&
          _coveragePercent < 100) {
        if (mounted) await _showCoverageDialog();
      }

      // 4. Show SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Session saved! Revision scheduled.'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 5. Show congratulation overlay
      if (mounted) await _showCongratulationOverlay();

      // 6. Navigate back — pop the sheet, then pop the session screen
      if (mounted) {
        Navigator.of(context).pop(); // close sheet
        Navigator.of(context).pop(); // pop session screen back to Today's Plan
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving session: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveFAEntries(
      AppProvider app, DateTime now, String mode) async {
    final pagesText = _pagesCtrl.text.trim();
    if (pagesText.isEmpty) return;

    // Parse page numbers (supports "45", "45-48", "45,46,47")
    final pageNumbers = <int>[];
    for (final part in pagesText.split(RegExp(r'[,\s]+'))) {
      if (part.contains('-')) {
        final range = part.split('-');
        final start = int.tryParse(range[0].trim());
        final end = int.tryParse(range[1].trim());
        if (start != null && end != null) {
          for (var i = start; i <= end; i++) {
            pageNumbers.add(i);
          }
        }
      } else {
        final n = int.tryParse(part.trim());
        if (n != null) pageNumbers.add(n);
      }
    }

    for (final page in pageNumbers) {
      final pageStr = page.toString();

      // Find or create KB entry
      KnowledgeBaseEntry? existing;
      try {
        existing =
            app.knowledgeBase.firstWhere((e) => e.pageNumber == pageStr);
      } catch (_) {
        existing = null;
      }

      final nextRevision = SrsService.calculateNextRevisionDateString(
        lastStudiedAt: now.toIso8601String(),
        revisionIndex: 0,
        mode: mode,
      );

      final updatedEntry = (existing ?? KnowledgeBaseEntry(
        pageNumber: pageStr,
        title: 'FA Page $pageStr',
        subject: '',
        system: '',
        revisionCount: 0,
        currentRevisionIndex: 0,
        ankiTotal: 0,
        ankiCovered: 0,
        videoLinks: const [],
        tags: const [],
        notes: '',
        logs: const [],
        topics: const [],
      )).copyWith(
        lastStudiedAt: now.toIso8601String(),
        firstStudiedAt: existing?.firstStudiedAt ?? now.toIso8601String(),
        nextRevisionAt: nextRevision,
        revisionCount: (existing?.revisionCount ?? 0) + 1,
        currentRevisionIndex: _coveragePercent.toInt(),
      );

      await app.upsertKBEntry(updatedEntry);

      // Create revision item
      final revItem = RevisionItem(
        id: _uuid.v4(),
        type: 'PAGE',
        pageNumber: pageStr,
        title: updatedEntry.title,
        parentTitle: '',
        nextRevisionAt: nextRevision ?? '',
        currentRevisionIndex: 0,
      );
      await app.upsertRevisionItem(revItem);
    }
  }

  Future<void> _updateBlockStatus(AppProvider app) async {
    final plan = app.getDayPlan(widget.dayPlanDate);
    if (plan == null || plan.blocks == null) return;

    final blocks = List<Block>.from(plan.blocks!);
    if (widget.blockIndex >= 0 && widget.blockIndex < blocks.length) {
      blocks[widget.blockIndex] = blocks[widget.blockIndex].copyWith(
        status: BlockStatus.done,
        actualStartTime: widget.startedAt.toIso8601String(),
        actualEndTime: widget.endedAt.toIso8601String(),
        actualDurationMinutes: widget.elapsedSeconds ~/ 60,
        completionStatus:
            _coveragePercent >= 100 ? 'COMPLETED' : 'PARTIAL',
      );
      await app.upsertDayPlan(plan.copyWith(blocks: blocks));
    }
  }

  Future<void> _showCoverageDialog() async {
    await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            'You covered ${_coveragePercent.toInt()}% — what about the rest?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'today'),
            child: const Text('Add to today'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'tomorrow'),
            child: const Text('Schedule tomorrow'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'skip'),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCongratulationOverlay() async {
    final overlay = OverlayEntry(
      builder: (ctx) => Positioned.fill(
        child: Material(
          color: Colors.black54,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 40, vertical: 32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    'Great work! Keep going',
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    await Future.delayed(const Duration(seconds: 2));
    overlay.remove();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => SingleChildScrollView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ─────────────────────────────────────────
            Center(
              child: Text(
                '🎉 Session Complete!',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Duration',
              value: _formatDuration(widget.elapsedSeconds),
              icon: Icons.timer_outlined,
              cs: cs,
              theme: theme,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              label: 'Time',
              value:
                  '${DateFormat('h:mm a').format(widget.startedAt)} – ${DateFormat('h:mm a').format(widget.endedAt)}',
              icon: Icons.schedule_rounded,
              cs: cs,
              theme: theme,
            ),

            const SizedBox(height: 20),
            Divider(color: cs.onSurface.withValues(alpha: 0.08)),
            const SizedBox(height: 12),

            // ── What did you study? ────────────────────────────
            Text(
              'What did you study?',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // Type-specific form
            ..._buildFormFields(theme, cs),

            const SizedBox(height: 24),

            // ── Save button ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save & Complete',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFormFields(ThemeData theme, ColorScheme cs) {
    switch (_taskType) {
      case 'FA':
      case 'REVISION':
      case 'FMGE':
        return _buildFAFields(theme, cs);
      case 'VIDEO':
        return _buildVideoFields(theme, cs);
      case 'QBANK':
        return _buildQBankFields(theme, cs);
      case 'ANKI':
        return _buildAnkiFields(theme, cs);
      default:
        return _buildGenericFields(theme, cs);
    }
  }

  // ── FA / FMGE form ──────────────────────────────────────────
  List<Widget> _buildFAFields(ThemeData theme, ColorScheme cs) => [
        _fieldLabel(theme, 'Pages studied'),
        _textField(cs, theme, _pagesCtrl, 'e.g. 45 or 45-48',
            inputType: TextInputType.text),
        const SizedBox(height: 14),
        _fieldLabel(theme, 'Coverage'),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _coveragePercent,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${_coveragePercent.toInt()}%',
                onChanged: (v) => setState(() => _coveragePercent = v),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '${_coveragePercent.toInt()}%',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _fieldLabel(theme, 'Subtopics covered'),
        _textField(cs, theme, _subtopicsCtrl, 'Comma-separated subtopics'),
        if (_subtopicChips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _subtopicChips
                .map((t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      deleteIcon:
                          const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(
                          () => _subtopicChips.remove(t)),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 14),
        _fieldLabel(theme, 'Notes (optional)'),
        _textField(cs, theme, _notesCtrl, 'Any notes...', maxLines: 3),
      ];

  // ── Video form ──────────────────────────────────────────────
  List<Widget> _buildVideoFields(ThemeData theme, ColorScheme cs) => [
        _fieldLabel(theme, 'Minutes watched'),
        _textField(cs, theme, _minutesWatchedCtrl, 'Minutes',
            inputType: TextInputType.number),
        const SizedBox(height: 14),
        _fieldLabel(theme, 'Topic'),
        _textField(cs, theme, _topicCtrl, 'Topic covered'),
        const SizedBox(height: 14),
        _fieldLabel(theme, 'Notes (optional)'),
        _textField(cs, theme, _notesCtrl, 'Any notes...', maxLines: 3),
      ];

  // ── QBank form ──────────────────────────────────────────────
  List<Widget> _buildQBankFields(ThemeData theme, ColorScheme cs) {
    final attempted = int.tryParse(_questionsCtrl.text) ?? 0;
    final correct = int.tryParse(_correctCtrl.text) ?? 0;
    final pct = attempted > 0 ? (correct / attempted * 100).toInt() : 0;

    return [
      _fieldLabel(theme, 'Questions attempted'),
      _textField(cs, theme, _questionsCtrl, 'Number of questions',
          inputType: TextInputType.number),
      const SizedBox(height: 14),
      _fieldLabel(theme, 'Correct answers'),
      _textField(cs, theme, _correctCtrl, 'Number correct',
          inputType: TextInputType.number),
      const SizedBox(height: 6),
      Text(
        'Accuracy: $pct%',
        style: theme.textTheme.labelMedium?.copyWith(
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 50
                  ? Colors.orange
                  : cs.error,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 14),
      _fieldLabel(theme, 'Notes (optional)'),
      _textField(cs, theme, _notesCtrl, 'Any notes...', maxLines: 3),
    ];
  }

  // ── Anki form ───────────────────────────────────────────────
  List<Widget> _buildAnkiFields(ThemeData theme, ColorScheme cs) => [
        _fieldLabel(theme, 'Cards reviewed'),
        _textField(cs, theme, _cardsCtrl, 'Number of cards',
            inputType: TextInputType.number),
        const SizedBox(height: 14),
        _fieldLabel(theme, 'Notes (optional)'),
        _textField(cs, theme, _notesCtrl, 'Any notes...', maxLines: 3),
      ];

  // ── Generic / Other ─────────────────────────────────────────
  List<Widget> _buildGenericFields(ThemeData theme, ColorScheme cs) => [
        _fieldLabel(theme, 'Notes (optional)'),
        _textField(cs, theme, _notesCtrl, 'What did you study?',
            maxLines: 3),
      ];

  // ── Shared helpers ──────────────────────────────────────────
  Widget _fieldLabel(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: theme.textTheme.labelMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      );

  Widget _textField(
    ColorScheme cs,
    ThemeData theme,
    TextEditingController ctrl,
    String hint, {
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: inputType,
        maxLines: maxLines,
        style: theme.textTheme.bodyMedium,
        onChanged: (_) {
          // Update subtopic chips when typing comma-separated
          if (ctrl == _subtopicsCtrl) {
            final parts = ctrl.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            setState(() => _subtopicChips = parts);
          }
          if (ctrl == _questionsCtrl || ctrl == _correctCtrl) {
            setState(() {}); // recalc accuracy
          }
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium
              ?.copyWith(color: cs.onSurface.withValues(alpha: 0.35)),
          filled: true,
          fillColor: cs.onSurface.withValues(alpha: 0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════
// INFO ROW
// ══════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme cs;
  final ThemeData theme;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
