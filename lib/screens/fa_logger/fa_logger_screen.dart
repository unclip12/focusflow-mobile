// =============================================================
// FALoggerScreen â€” rebuilt for First Aid (USMLE) page logging only.
// Shows KB entries as FA study log cards with coverage bars.
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/knowledge_base.dart';
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

  List<KnowledgeBaseEntry> _filtered(List<KnowledgeBaseEntry> all) {
    // Only show entries that have been studied (have a lastStudiedAt)
    var list = all.where((e) => e.lastStudiedAt != null).toList();
    // Sort by most recently studied
    list.sort((a, b) =>
        (b.lastStudiedAt ?? '').compareTo(a.lastStudiedAt ?? ''));
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list
        .where((e) =>
            e.pageNumber.toLowerCase().contains(q) ||
            e.title.toLowerCase().contains(q) ||
            e.subject.toLowerCase().contains(q) ||
            e.system.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final items = _filtered(app.knowledgeBase);

    return AppScaffold(
      screenName: 'FA Logger',
      body: Column(
        children: [
          // â”€â”€ Search bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search FA pagesâ€¦',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                  icon: Icon(Icons.search_rounded,
                      size: 20,
                      color: cs.onSurface.withValues(alpha: 0.35)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // â”€â”€ List / empty â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: items.isEmpty
                ? _EmptyState(hasQuery: _query.isNotEmpty)
                : ListView.separated(
                    padding:
                        EdgeInsets.fromLTRB(16, 6, 16, MediaQuery.of(context).padding.bottom + 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _FAEntryCard(entry: items[i]),
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// FA ENTRY CARD
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _FAEntryCard extends StatelessWidget {
  final KnowledgeBaseEntry entry;
  const _FAEntryCard({required this.entry});

  Color _coverageColor(int pct) {
    if (pct <= 0) return Colors.red;
    if (pct < 50) return Colors.orange;
    if (pct < 100) return Colors.amber.shade700;
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Coverage: use revisionCount as a proxy (0 = first study)
    // We store coverage in currentRevisionIndex (0-100 range when used as %)
    // or default to first-study assumed 50%
    final coverage = entry.currentRevisionIndex.clamp(0, 100);
    final coverageColor = _coverageColor(coverage);

    // Page label
    final pageLabel = 'Page ${entry.pageNumber}';

    // Date + time
    String dateLabel = '';
    if (entry.lastStudiedAt != null) {
      final dt = DateTime.tryParse(entry.lastStudiedAt!);
      if (dt != null) {
        dateLabel =
            '${DateFormat('MMM d').format(dt)} Â· ${DateFormat('h:mm a').format(dt)}';
      }
    }

    // Subtopics from topics list
    final subtopics = entry.topics.map((t) => t.name).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // â”€â”€ Header row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    size: 18, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pageLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700),
                    ),
                    if (entry.title.isNotEmpty &&
                        entry.title != 'FA Page ${entry.pageNumber}')
                      Text(
                        entry.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              cs.onSurface.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (dateLabel.isNotEmpty)
                Text(
                  dateLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // â”€â”€ Coverage progress bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: coverage / 100,
                    minHeight: 6,
                    backgroundColor:
                        cs.onSurface.withValues(alpha: 0.08),
                    valueColor:
                        AlwaysStoppedAnimation(coverageColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$coverage%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: coverageColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          // â”€â”€ Subtopic chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (subtopics.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: subtopics
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t,
                          style:
                              theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontSize: 10,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// EMPTY STATE
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1)
                    .withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasQuery
                    ? Icons.search_off_rounded
                    : Icons.menu_book_outlined,
                size: 32,
                color: const Color(0xFF6366F1)
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasQuery
                  ? 'No matching FA pages'
                  : 'No First Aid pages logged yet',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              hasQuery
                  ? 'Try a different search term'
                  : 'Tap + to log your first FA page study',
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
