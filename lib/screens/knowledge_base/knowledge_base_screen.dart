// =============================================================
// KnowledgeBaseScreen — searchable, filterable list of KB entries
// Uses AppScaffold. Client-side filtering on AppProvider.knowledgeBase.
// Filters: subject chips, system chips, mastery (all/due/mastered).
// Search matches on pageNumber, topic (title), subject.
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/knowledge_base.dart';
import 'package:focusflow_mobile/services/srs_service.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/screens/knowledge_base/kb_entry_card.dart';
import 'package:focusflow_mobile/screens/knowledge_base/kb_entry_detail_screen.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Filters
  String? _selectedSubject;
  String? _selectedSystem;
  _MasteryFilter _masteryFilter = _MasteryFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<KnowledgeBaseEntry> _applyFilters(List<KnowledgeBaseEntry> entries) {
    const String mode = 'balanced';
    var filtered = entries.toList();

    // ── Text search ──────────────────────────────────────────────
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        return e.pageNumber.toLowerCase().contains(q) ||
            e.title.toLowerCase().contains(q) ||
            e.subject.toLowerCase().contains(q);
      }).toList();
    }

    // ── Subject filter ───────────────────────────────────────────
    if (_selectedSubject != null) {
      filtered =
          filtered.where((e) => e.subject == _selectedSubject).toList();
    }

    // ── System filter ────────────────────────────────────────────
    if (_selectedSystem != null) {
      filtered =
          filtered.where((e) => e.system == _selectedSystem).toList();
    }

    // ── Mastery filter ───────────────────────────────────────────
    switch (_masteryFilter) {
      case _MasteryFilter.due:
        filtered = filtered
            .where((e) =>
                SrsService.isDueNow(nextRevisionAt: e.nextRevisionAt))
            .toList();
        break;
      case _MasteryFilter.mastered:
        filtered = filtered
            .where((e) => SrsService.isMastered(
                revisionIndex: e.currentRevisionIndex, mode: mode))
            .toList();
        break;
      case _MasteryFilter.all:
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final filtered = _applyFilters(app.knowledgeBase);

    return AppScaffold(
      screenName: 'Knowledge Base',
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search pages, topics, subjects…',
                hintStyle: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.35)),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 18,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: cs.onSurface.withValues(alpha: 0.05),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Filter bar ─────────────────────────────────────────
          _FilterBar(
            selectedSubject: _selectedSubject,
            selectedSystem: _selectedSystem,
            masteryFilter: _masteryFilter,
            onSubjectChanged: (v) =>
                setState(() => _selectedSubject = v == _selectedSubject ? null : v),
            onSystemChanged: (v) =>
                setState(() => _selectedSystem = v == _selectedSystem ? null : v),
            onMasteryChanged: (v) => setState(() => _masteryFilter = v),
          ),
          const SizedBox(height: 4),

          // ── Results count ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${filtered.length} entries',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Entry list ─────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48,
                            color: cs.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        Text(
                          'No entries found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final entry = filtered[i];
                      return KBEntryCard(
                        entry: entry,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  KBEntryDetailScreen(pageNumber: entry.pageNumber),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Mastery filter enum ─────────────────────────────────────────
enum _MasteryFilter { all, due, mastered }

// ── Filter bar widget ───────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final String? selectedSubject;
  final String? selectedSystem;
  final _MasteryFilter masteryFilter;
  final ValueChanged<String> onSubjectChanged;
  final ValueChanged<String> onSystemChanged;
  final ValueChanged<_MasteryFilter> onMasteryChanged;

  const _FilterBar({
    required this.selectedSubject,
    required this.selectedSystem,
    required this.masteryFilter,
    required this.onSubjectChanged,
    required this.onSystemChanged,
    required this.onMasteryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // ── Mastery toggle chips ─────────────────────────────────
          for (final mf in _MasteryFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(
                label: mf.name[0].toUpperCase() + mf.name.substring(1),
                selected: masteryFilter == mf,
                onTap: () => onMasteryChanged(mf),
              ),
            ),

          // Separator
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            color: cs.onSurface.withValues(alpha: 0.1),
          ),

          // ── Subject chips ──────────────────────────────────────
          for (final subj in kFmgeSubjects)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(
                label: subj,
                selected: selectedSubject == subj,
                onTap: () => onSubjectChanged(subj),
              ),
            ),

          // Separator
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            color: cs.onSurface.withValues(alpha: 0.1),
          ),

          // ── System chips ───────────────────────────────────────
          for (final sys in kBodySystems)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(
                label: sys,
                selected: selectedSystem == sys,
                onTap: () => onSystemChanged(sys),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Individual filter chip ──────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.15)
              : cs.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.4)
                : cs.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.55),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
