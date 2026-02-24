// =============================================================
// InfoFilesScreen — grid of study material cards
// Filter chips: All / PDF / Image / Notes
// FAB → AddMaterialSheet
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/study_material.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/screens/info_files/material_card.dart';
import 'package:focusflow_mobile/screens/info_files/add_material_sheet.dart';

class InfoFilesScreen extends StatefulWidget {
  const InfoFilesScreen({super.key});

  @override
  State<InfoFilesScreen> createState() => _InfoFilesScreenState();
}

class _InfoFilesScreenState extends State<InfoFilesScreen> {
  String _filter = 'All';

  static const _filters = ['All', 'PDF', 'IMAGE', 'TEXT'];
  static const _filterLabels = {
    'All':   'All',
    'PDF':   'PDF',
    'IMAGE': 'Image',
    'TEXT':  'Notes',
  };

  List<StudyMaterial> _filtered(List<StudyMaterial> all) {
    if (_filter == 'All') return all;
    return all.where((m) => m.sourceType == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final items = _filtered(app.studyMaterials);

    return AppScaffold(
      screenName: 'Info Files',
      body: Column(
        children: [
          // ── Filter chips ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection:  Axis.horizontal,
                itemCount:        _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f        = _filters[i];
                  final selected = _filter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _filterLabels[f] ?? f,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: selected
                              ? cs.onPrimary
                              : cs.onSurface.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Grid / Empty ────────────────────────────────────
          Expanded(
            child: items.isEmpty
                ? _EmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:  2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => MaterialCard(
                      material: items[i],
                      onTap: () => _showDetail(context, items[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddMaterialSheet(context),
        backgroundColor: cs.primary,
        child: Icon(Icons.add_rounded, color: cs.onPrimary),
      ),
    );
  }

  void _showDetail(BuildContext context, StudyMaterial mat) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      enableDrag:         false,
      useSafeArea:        true,
      backgroundColor:    Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.only(top: 80),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(mat.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(mat.sourceType,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                )),
            const SizedBox(height: 14),
            if (mat.text.isNotEmpty)
              Text(mat.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
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
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.folder_open_rounded,
                  size: 32, color: cs.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 14),
            Text('No materials yet',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 4),
            Text('Tap + to add study materials',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4),
                )),
          ],
        ),
      ),
    );
  }
}
