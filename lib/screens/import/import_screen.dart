// =============================================================
// ImportScreen — Quick Import: paste JSON, preview, execute
// =============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/models/uworld_session.dart';

// ── Private parsed-action model ──────────────────────────────────
class _ParsedAction {
  final String type;
  final String previewText;
  final bool isValid;
  final Map<String, dynamic> rawData;

  const _ParsedAction({
    required this.type,
    required this.previewText,
    required this.isValid,
    required this.rawData,
  });
}

// ── Screen ───────────────────────────────────────────────────────
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final TextEditingController _jsonCtrl = TextEditingController();
  List<_ParsedAction> _actions = [];
  String? _parseError;
  bool _executed = false;

  @override
  void dispose() {
    _jsonCtrl.dispose();
    super.dispose();
  }

  // ── Parse logic ────────────────────────────────────────────────
  void _parse() {
    setState(() {
      _parseError = null;
      _actions = [];
      _executed = false;
    });

    final text = _jsonCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _parseError = 'Empty input — paste a JSON array');
      return;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (e) {
      setState(() => _parseError = 'Invalid JSON — check syntax');
      return;
    }

    if (decoded is! List) {
      setState(() => _parseError = 'Expected a JSON array [ ... ]');
      return;
    }

    final app = context.read<AppProvider>();
    final parsed = <_ParsedAction>[];

    for (final item in decoded) {
      if (item is! Map<String, dynamic>) {
        parsed.add(const _ParsedAction(
          type: 'unknown',
          previewText: '⚠️ Invalid action object',
          isValid: false,
          rawData: {},
        ));
        continue;
      }

      final type = item['type'] as String? ?? 'unknown';
      final action = _parseAction(type, item, app);
      parsed.add(action);
    }

    setState(() => _actions = parsed);
  }

  _ParsedAction _parseAction(
      String type, Map<String, dynamic> data, AppProvider app) {
    switch (type) {
      case 'mark_fa_pages_read':
        final from = data['from'] as int? ?? 0;
        final to = data['to'] as int? ?? 0;
        final count = to - from + 1;
        return _ParsedAction(
          type: type,
          previewText: '📖 Mark FA pages $from–$to as Read ($count pages)',
          isValid: true,
          rawData: data,
        );

      case 'mark_fa_anki_done':
        final from = data['from'] as int? ?? 0;
        final to = data['to'] as int? ?? 0;
        final count = to - from + 1;
        return _ParsedAction(
          type: type,
          previewText:
              '🃏 Mark FA pages $from–$to as Anki Done ($count pages)',
          isValid: true,
          rawData: data,
        );

      case 'log_uworld_session':
        final subject = data['subject'] as String? ?? '';
        final total = data['total'] as int? ?? 0;
        final correct = data['correct'] as int? ?? 0;
        final date = data['date'] as String? ?? '';
        final pct = total > 0 ? (correct * 100 / total).round() : 0;
        String dateLabel = date;
        try {
          final dt = DateTime.parse(date);
          dateLabel = DateFormat('MMM d').format(dt);
        } catch (_) {}
        return _ParsedAction(
          type: type,
          previewText:
              '📊 Log UWorld: $subject — $correct/$total ($pct%) on $dateLabel',
          isValid: true,
          rawData: data,
        );

      case 'mark_sketchy_watched':
        final title = data['title'] as String? ?? '';
        final found = app.sketchyItems.any(
            (s) => s.name.toLowerCase().contains(title.toLowerCase()));
        return _ParsedAction(
          type: type,
          previewText: found
              ? '🎬 Mark Sketchy watched: $title'
              : '⚠️ Sketchy item not found: $title',
          isValid: found,
          rawData: data,
        );

      case 'mark_pathoma_watched':
        final chapter = data['chapter'] as int? ?? 0;
        final found =
            app.pathomaItems.any((p) => p.chapter == chapter);
        return _ParsedAction(
          type: type,
          previewText: found
              ? '🔬 Mark Pathoma Ch.$chapter as watched'
              : '⚠️ Pathoma chapter not found: $chapter',
          isValid: found,
          rawData: data,
        );

      case 'set_exam_dates':
        final fmge = data['fmge'] as String? ?? '';
        final step1 = data['step1'] as String? ?? '';
        String fLabel = fmge, sLabel = step1;
        try {
          fLabel = DateFormat('MMM d yyyy').format(DateTime.parse(fmge));
        } catch (_) {}
        try {
          sLabel = DateFormat('MMM d yyyy').format(DateTime.parse(step1));
        } catch (_) {}
        return _ParsedAction(
          type: type,
          previewText: '📅 Set FMGE: $fLabel · Step 1: $sLabel',
          isValid: true,
          rawData: data,
        );

      case 'set_daily_goals':
        final faPages = data['fa_pages'] as int? ?? 0;
        final ankiCards = data['anki_cards'] as int? ?? 0;
        return _ParsedAction(
          type: type,
          previewText:
              '🎯 Set goals: FA $faPages pages/day · Anki $ankiCards cards/day',
          isValid: true,
          rawData: data,
        );

      default:
        return _ParsedAction(
          type: type,
          previewText: '⚠️ Unknown action type: $type',
          isValid: false,
          rawData: data,
        );
    }
  }

  // ── Execute logic ──────────────────────────────────────────────
  Future<void> _execute() async {
    final app = context.read<AppProvider>();
    final sp = context.read<SettingsProvider>();
    int count = 0;

    for (final action in _actions) {
      if (!action.isValid) continue;
      final d = action.rawData;

      switch (action.type) {
        case 'mark_fa_pages_read':
          await app.bulkMarkFAPages(
              d['from'] as int, d['to'] as int, 'read');
          count++;
          break;

        case 'mark_fa_anki_done':
          await app.bulkMarkFAPages(
              d['from'] as int, d['to'] as int, 'anki_done');
          count++;
          break;

        case 'log_uworld_session':
          final session = UWorldSession(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            subject: d['subject'] as String,
            done: d['total'] as int,
            correct: d['correct'] as int,
            date: d['date'] as String,
          );
          await app.addUWorldSession(session);
          count++;
          break;

        case 'mark_sketchy_watched':
          final title = d['title'] as String;
          final idx = app.sketchyItems.indexWhere(
              (s) => s.name.toLowerCase().contains(title.toLowerCase()));
          if (idx >= 0) {
            final updated =
                app.sketchyItems[idx].copyWith(status: 'watched');
            await app.upsertSketchyItem(updated);
            count++;
          }
          break;

        case 'mark_pathoma_watched':
          final chapter = d['chapter'] as int;
          final idx =
              app.pathomaItems.indexWhere((p) => p.chapter == chapter);
          if (idx >= 0) {
            final updated =
                app.pathomaItems[idx].copyWith(status: 'watched');
            await app.upsertPathomaItem(updated);
            count++;
          }
          break;

        case 'set_exam_dates':
          if (d.containsKey('fmge')) {
            await sp.setFmgeDate(d['fmge'] as String);
          }
          if (d.containsKey('step1')) {
            await sp.setStep1Date(d['step1'] as String);
          }
          count++;
          break;

        case 'set_daily_goals':
          if (d.containsKey('fa_pages')) {
            await sp.setDailyFAGoal(d['fa_pages'] as int);
          }
          if (d.containsKey('anki_cards')) {
            await sp.setAnkiBatchSize(d['anki_cards'] as int);
          }
          count++;
          break;
      }
    }

    if (!mounted) return;

    setState(() {
      _executed = true;
      _actions = [];
      _jsonCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ $count actions applied')),
    );
  }

  // ── Clear ──────────────────────────────────────────────────────
  void _clear() {
    setState(() {
      _jsonCtrl.clear();
      _actions = [];
      _parseError = null;
      _executed = false;
    });
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final validCount = _actions.where((a) => a.isValid).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Import'),
            Text(
              'Paste a JSON command block',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. JSON text field ───────────────────────────────
            TextField(
              controller: _jsonCtrl,
              minLines: 6,
              maxLines: 16,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: InputDecoration(
                hintText:
                    '[\n  { "type": "mark_fa_pages_read", "from": 50, "to": 92 }\n]',
                hintStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _jsonCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clear,
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}), // refresh clear button
            ),

            const SizedBox(height: 12),

            // ── 2. Parse + Clear buttons ─────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _parse,
                    child: const Text('Parse'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _clear,
                  child: const Text('Clear'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 3. Error banner ──────────────────────────────────
            if (_parseError != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: cs.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _parseError!,
                        style: TextStyle(color: cs.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),

            // ── 4. Preview section ───────────────────────────────
            if (_actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Actions Preview (${_actions.length} actions)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _actions.length,
                itemBuilder: (ctx, i) {
                  final a = _actions[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: a.isValid
                            ? cs.primaryContainer
                            : cs.errorContainer,
                        child: Text(
                          _iconForType(a.type),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      title: Text(
                        a.previewText,
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: Chip(
                        label: Text(
                          a.isValid ? 'OK' : '⚠️ Warning',
                          style: TextStyle(
                            fontSize: 12,
                            color: a.isValid
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                        backgroundColor: a.isValid
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  );
                },
              ),

              // ── 5. Execute button ──────────────────────────────
              if (validCount > 0) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _execute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Execute $validCount Actions'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _iconForType(String type) {
    switch (type) {
      case 'mark_fa_pages_read':
        return '📖';
      case 'mark_fa_anki_done':
        return '🃏';
      case 'log_uworld_session':
        return '📊';
      case 'mark_sketchy_watched':
        return '🎬';
      case 'mark_pathoma_watched':
        return '🔬';
      case 'set_exam_dates':
        return '📅';
      case 'set_daily_goals':
        return '🎯';
      default:
        return '❓';
    }
  }
}
