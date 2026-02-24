// =============================================================
// AddMaterialSheet — bottom sheet to add a new StudyMaterial
// Fields: title, type selector, URL/path, subject tag, notes.
// enableDrag: false, useSafeArea: true
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/study_material.dart';

Future<void> showAddMaterialSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context:            context,
    isScrollControlled: true,
    enableDrag:         false,
    useSafeArea:        true,
    backgroundColor:    Colors.transparent,
    builder: (_) => const _AddMaterialSheet(),
  );
}

class _AddMaterialSheet extends StatefulWidget {
  const _AddMaterialSheet();

  @override
  State<_AddMaterialSheet> createState() => _AddMaterialSheetState();
}

class _AddMaterialSheetState extends State<_AddMaterialSheet> {
  final _titleCtrl   = TextEditingController();
  final _urlCtrl     = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _notesCtrl   = TextEditingController();

  String _type = 'TEXT';

  static const _types = ['PDF', 'IMAGE', 'TEXT'];

  IconData _typeIcon(String t) {
    switch (t) {
      case 'PDF':   return Icons.picture_as_pdf_rounded;
      case 'IMAGE': return Icons.image_rounded;
      default:       return Icons.article_rounded;
    }
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'PDF':   return const Color(0xFFEF4444);
      case 'IMAGE': return const Color(0xFF3B82F6);
      default:       return const Color(0xFF10B981);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _subjectCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final notes   = _notesCtrl.text.trim();
    final url     = _urlCtrl.text.trim();
    final subject = _subjectCtrl.text.trim();
    final text    = [
      if (subject.isNotEmpty) 'Subject: $subject',
      if (url.isNotEmpty) 'URL: $url',
      if (notes.isNotEmpty) notes,
    ].join('\n');

    final material = StudyMaterial(
      id:         const Uuid().v4(),
      title:      title,
      text:       text,
      sourceType: _type,
      createdAt:  DateTime.now().toIso8601String(),
      isActive:   true,
      source:     'UPLOAD',
    );

    context.read<AppProvider>().upsertStudyMaterial(material);
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
            Text('Add Study Material',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // ── Title ─────────────────────────────────────────
            _label(theme, 'Title'),
            const SizedBox(height: 6),
            _input(cs, theme, _titleCtrl, 'Material name'),
            const SizedBox(height: 14),

            // ── Type selector ─────────────────────────────────
            _label(theme, 'Type'),
            const SizedBox(height: 8),
            Row(
              children: _types.map((t) {
                final selected = _type == t;
                final color    = _typeColor(t);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(
                          right: t != _types.last ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.12)
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
                          Icon(_typeIcon(t), size: 20,
                              color: selected
                                  ? color
                                  : cs.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(height: 4),
                          Text(t, style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w700 : FontWeight.w500,
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

            // ── URL / Path ────────────────────────────────────
            _label(theme, 'URL / File Path'),
            const SizedBox(height: 6),
            _input(cs, theme, _urlCtrl, 'https://… or local path'),
            const SizedBox(height: 14),

            // ── Subject tag ───────────────────────────────────
            _label(theme, 'Subject Tag'),
            const SizedBox(height: 6),
            _input(cs, theme, _subjectCtrl, 'e.g. Anatomy'),
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
                  hintText:  'Optional notes…',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                  border:    InputBorder.none,
                  isDense:   true,
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
                child: const Text('Save Material',
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

  Widget _input(ColorScheme cs, ThemeData theme,
      TextEditingController ctrl, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color:        cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
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
