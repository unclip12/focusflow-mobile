// =============================================================
// FALogModal — bottom sheet to add a new FA page study entry.
// Fields: page numbers, study date, start/end time, coverage,
// subtopics, notes. Persists to KB + creates RevisionItem.
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:focusflow_mobile/models/knowledge_base.dart';
import 'package:focusflow_mobile/models/revision_item.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/services/srs_service.dart';

const _uuid = Uuid();

void showFALogModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _FALogSheet(),
  );
}

class _FALogSheet extends StatefulWidget {
  const _FALogSheet();

  @override
  State<_FALogSheet> createState() => _FALogSheetState();
}

class _FALogSheetState extends State<_FALogSheet> {
  final _pagesCtrl = TextEditingController();
  final _subtopicsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _studyDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime;
  double _coverage = 50;
  List<String> _subtopicChips = [];
  bool _saving = false;

  @override
  void dispose() {
    _pagesCtrl.dispose();
    _subtopicsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _studyDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _studyDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _save() async {
    if (_pagesCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter page number(s)')),
      );
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);

    final app = context.read<AppProvider>();
    final mode = app.revisionSettings?.mode ?? 'strict';

    try {
      // Parse page numbers
      final pageNumbers = <int>[];
      for (final part in _pagesCtrl.text.trim().split(RegExp(r'[,\s]+'))) {
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

      final studiedAt = DateTime(
        _studyDate.year,
        _studyDate.month,
        _studyDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      // Build subtopics as TrackableItem list
      final subtopics = _subtopicChips
          .map((name) => TrackableItem(
                id: _uuid.v4(),
                name: name,
                revisionCount: 0,
                currentRevisionIndex: 0,
                logs: const [],
              ))
          .toList();

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
          lastStudiedAt: studiedAt.toIso8601String(),
          revisionIndex: 0,
          mode: mode,
        );

        final updatedEntry = (existing ??
                KnowledgeBaseEntry(
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
                ))
            .copyWith(
          lastStudiedAt: studiedAt.toIso8601String(),
          firstStudiedAt:
              existing?.firstStudiedAt ?? studiedAt.toIso8601String(),
          nextRevisionAt: nextRevision,
          revisionCount: (existing?.revisionCount ?? 0) + 1,
          currentRevisionIndex: _coverage.toInt(),
          notes: _notesCtrl.text.trim().isNotEmpty
              ? _notesCtrl.text.trim()
              : existing?.notes ?? '',
          topics: subtopics.isNotEmpty ? subtopics : existing?.topics ?? [],
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ FA pages logged! Revision scheduled.'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              20,
        ),
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

            Center(
              child: Text(
                '📘 Log FA Page Study',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 20),

            // ── Page numbers ────────────────────────────────────
            _label(theme, 'Page number(s)'),
            _textField(cs, theme, _pagesCtrl, 'e.g. 45 or 45-48'),
            const SizedBox(height: 16),

            // ── Study date ──────────────────────────────────────
            _label(theme, 'Study date'),
            _pickerTile(
              cs,
              theme,
              icon: Icons.calendar_today_rounded,
              text: DateFormat('MMM d, yyyy').format(_studyDate),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            // ── Start & end time ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(theme, 'Start time'),
                      _pickerTile(
                        cs,
                        theme,
                        icon: Icons.access_time_rounded,
                        text: _startTime.format(context),
                        onTap: _pickStartTime,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(theme, 'End time'),
                      _pickerTile(
                        cs,
                        theme,
                        icon: Icons.access_time_rounded,
                        text: _endTime?.format(context) ?? 'Not set',
                        onTap: _pickEndTime,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Coverage slider ─────────────────────────────────
            _label(theme, 'Coverage'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _coverage,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${_coverage.toInt()}%',
                    onChanged: (v) => setState(() => _coverage = v),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${_coverage.toInt()}%',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Subtopics ───────────────────────────────────────
            _label(theme, 'Subtopics (comma-separated)'),
            _textField(cs, theme, _subtopicsCtrl, 'e.g. Anatomy, Physiology'),
            if (_subtopicChips.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _subtopicChips
                    .map((t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () =>
                              setState(() => _subtopicChips.remove(t)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),

            // ── Notes ───────────────────────────────────────────
            _label(theme, 'Notes (optional)'),
            _textField(cs, theme, _notesCtrl, 'Any additional notes...',
                maxLines: 3),
            const SizedBox(height: 24),

            // ── Save button ─────────────────────────────────────
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
                    : const Text('Save Entry',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────
  Widget _label(ThemeData theme, String text) => Padding(
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
          if (ctrl == _subtopicsCtrl) {
            final parts = ctrl.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            setState(() => _subtopicChips = parts);
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

  Widget _pickerTile(
    ColorScheme cs,
    ThemeData theme, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 10),
              Text(
                text,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
}
