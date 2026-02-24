// =============================================================
// FALoggerScreen — lists FMGEEntry items with search + FAB
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/fmge_entry.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/screens/fa_logger/fa_log_modal.dart';

class FALoggerScreen extends StatefulWidget {
  const FALoggerScreen({super.key});

  @override
  State<FALoggerScreen> createState() => _FALoggerScreenState();
}

class _FALoggerScreenState extends State<FALoggerScreen> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FMGEEntry> _filtered(List<FMGEEntry> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all
        .where((e) =>
            e.subject.toLowerCase().contains(q) ||
            (e.notes?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final items = _filtered(app.fmgeEntries);

    return AppScaffold(
      screenName: 'FA Logger',
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color:        cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText:  'Search entries…',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                  icon:   Icon(Icons.search_rounded,
                      size: 20, color: cs.onSurface.withValues(alpha: 0.35)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // ── List / empty ────────────────────────────────────
          Expanded(
            child: items.isEmpty
                ? _EmptyState(hasQuery: _query.isNotEmpty)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _EntryCard(entry: items[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showFALogModal(context),
        backgroundColor: cs.primary,
        child: Icon(Icons.add_rounded, color: cs.onPrimary),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// ENTRY CARD
// ══════════════════════════════════════════════════════════════════

class _EntryCard extends StatelessWidget {
  final FMGEEntry entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        cs.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:        const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.medical_services_rounded,
                    size: 18, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.subject,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Revision count badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${entry.revisionCount}x',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:      cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Slide range
          Row(
            children: [
              Icon(Icons.layers_rounded,
                  size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Text(
                'Slides ${entry.slideStart} – ${entry.slideEnd}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              if (entry.lastStudiedAt != null) ...[
                const Spacer(),
                Icon(Icons.access_time_rounded,
                    size: 13, color: cs.onSurface.withValues(alpha: 0.35)),
                const SizedBox(width: 3),
                Text(
                  _formatDate(entry.lastStudiedAt!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          if (entry.notes != null && entry.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.notes!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ══════════════════════════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color:  const Color(0xFF6366F1).withValues(alpha: 0.08),
                shape:  BoxShape.circle,
              ),
              child: Icon(
                hasQuery
                    ? Icons.search_off_rounded
                    : Icons.medical_services_outlined,
                size: 32,
                color: const Color(0xFF6366F1).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasQuery ? 'No matching entries' : 'No FMGE entries yet',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasQuery
                  ? 'Try a different search term'
                  : 'Tap + to log your first entry',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
