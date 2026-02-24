// =============================================================
// FALogModal — bottom sheet to add a new FMGEEntry
// Fields: subject, slide range, category, severity, notes.
// enableDrag: false, useSafeArea: true
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/fmge_entry.dart';

Future<void> showFALogModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context:             context,
    isScrollControlled:  true,
    enableDrag:          false,
    useSafeArea:         true,
    backgroundColor:     Colors.transparent,
    builder: (_) => const _FALogSheet(),
  );
}

class _FALogSheet extends StatefulWidget {
  const _FALogSheet();

  @override
  State<_FALogSheet> createState() => _FALogSheetState();
}

class _FALogSheetState extends State<_FALogSheet> {
  final _subjectCtrl    = TextEditingController();
  final _notesCtrl      = TextEditingController();
  final _slideStartCtrl = TextEditingController();
  final _slideEndCtrl   = TextEditingController();

  String _category = 'First Aid';
  String _severity = 'Medium';

  static const _categories = ['First Aid', 'Emergency', 'Protocol'];
  static const _severities = ['Low', 'Medium', 'High'];

  Color _severityColor(String s) {
    switch (s) {
      case 'Low':    return const Color(0xFF10B981);
      case 'Medium': return const Color(0xFFF59E0B);
      case 'High':   return const Color(0xFFEF4444);
      default:       return const Color(0xFFF59E0B);
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _notesCtrl.dispose();
    _slideStartCtrl.dispose();
    _slideEndCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final subject = _subjectCtrl.text.trim();
    if (subject.isEmpty) return;

    final start = int.tryParse(_slideStartCtrl.text.trim()) ?? 0;
    final end   = int.tryParse(_slideEndCtrl.text.trim()) ?? 0;

    final entry = FMGEEntry(
      id:                    const Uuid().v4(),
      subject:               '$_category: $subject',
      slideStart:            start,
      slideEnd:              end,
      revisionCount:         0,
      currentRevisionIndex:  0,
      logs:                  [],
      notes:                 '[$_severity] ${_notesCtrl.text.trim()}',
      lastStudiedAt:         DateTime.now().toIso8601String(),
    );

    context.read<AppProvider>().upsertFMGEEntry(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ────────────────────────────────────────
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color:        cs.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('Log FA Entry',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // ── Title ─────────────────────────────────────────
            _label(theme, 'Subject / Title'),
            const SizedBox(height: 6),
            _textField(cs, theme, _subjectCtrl, 'e.g. CPR Protocol'),
            const SizedBox(height: 14),

            // ── Category dropdown ─────────────────────────────
            _label(theme, 'Category'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color:        cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value:     _category,
                  isExpanded: true,
                  dropdownColor: cs.surface,
                  style:     theme.textTheme.bodyMedium,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Slide range ───────────────────────────────────
            _label(theme, 'Slide Range'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _textField(
                    cs, theme, _slideStartCtrl, 'Start',
                    inputType: TextInputType.number)),
                const SizedBox(width: 10),
                Text('–', style: theme.textTheme.titleMedium),
                const SizedBox(width: 10),
                Expanded(child: _textField(
                    cs, theme, _slideEndCtrl, 'End',
                    inputType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 14),

            // ── Severity selector ─────────────────────────────
            _label(theme, 'Severity'),
            const SizedBox(height: 8),
            Row(
              children: _severities.map((s) {
                final selected = _severity == s;
                final color    = _severityColor(s);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _severity = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(
                          right: s != _severities.last ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.15)
                            : cs.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? color
                              : cs.onSurface.withValues(alpha: 0.08),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(s, style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? color
                                : cs.onSurface.withValues(alpha: 0.55),
                          )),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // ── Notes ─────────────────────────────────────────
            _label(theme, 'Notes'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color:        cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _notesCtrl,
                maxLines:   3,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Additional details…',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                  border:   InputBorder.none,
                  isDense:  true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Save button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Entry',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(ThemeData theme, String text) => Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _textField(ColorScheme cs, ThemeData theme,
      TextEditingController ctrl, String hint,
      {TextInputType inputType = TextInputType.text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color:        cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: inputType,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText:  hint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.3),
          ),
          border:    InputBorder.none,
          isDense:   true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}
