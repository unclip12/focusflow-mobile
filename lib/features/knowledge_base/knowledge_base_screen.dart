import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import 'kb_provider.dart';

class KnowledgeBaseScreen extends ConsumerStatefulWidget {
  const KnowledgeBaseScreen({super.key});
  @override
  ConsumerState<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends ConsumerState<KnowledgeBaseScreen> {
  final _searchCtrl = TextEditingController();
  static const _staticCats = ['All', 'General', 'FMGE', 'FA', 'Clinical', 'Theory', 'Notes'];

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final filtered  = ref.watch(filteredKBProvider);
    final selCat    = ref.watch(kbCategoryProvider);
    final entryCount = ref.watch(kbProvider).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Knowledge Base', style: Theme.of(context).textTheme.displayMedium),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGlow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$entryCount entries',
                            style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => ref.read(kbSearchProvider.notifier).state = v,
                    decoration: InputDecoration(
                      hintText: 'Search entries...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref.read(kbSearchProvider.notifier).state = '';
                              })
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _staticCats.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: selCat == cat,
                          onSelected: (_) => ref.read(kbCategoryProvider.notifier).state = cat,
                          selectedColor: AppColors.accentGlow,
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 56, color: AppColors.accent),
                      const SizedBox(height: 12),
                      Text('No entries yet', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Tap + to add your first note',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ).animate().fadeIn(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 0.85,
                  crossAxisSpacing: 12, mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _KBCard(entry: filtered[i])
                      .animate(delay: (i * 30).ms)
                      .fadeIn()
                      .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut),
                  childCount: filtered.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ).animate().scale(delay: 300.ms, curve: Curves.easeOutBack),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddEntrySheet(
        onAdd: (t, c, cat, tags) => ref.read(kbProvider.notifier).add(t, c, cat, tags),
      ),
    );
  }
}

class _KBCard extends ConsumerWidget {
  final KBEntry entry;
  const _KBCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _showDetail(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accentGlow, borderRadius: BorderRadius.circular(6)),
            child: Text(entry.category,
                style: const TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          Text(entry.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Expanded(
            child: Text(entry.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                maxLines: 4, overflow: TextOverflow.ellipsis),
          ),
          if (entry.tags.isNotEmpty) ...[const SizedBox(height: 8),
            Wrap(spacing: 4, children: entry.tags.take(2).map((t) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentGlow, borderRadius: BorderRadius.circular(4)),
                child: Text('#$t', style: const TextStyle(fontSize: 9, color: AppColors.accentLight)),
              )
            ).toList()),
          ],
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65, maxChildSize: 0.95,
        builder: (_, ctrl) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C26) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: ctrl,
            children: [
              Center(child: Container(width: 40, height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(3)))),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGlow, borderRadius: BorderRadius.circular(8)),
                child: Text(entry.category, style: const TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
              const SizedBox(height: 12),
              Text(entry.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text(entry.content, style: Theme.of(context).textTheme.bodyLarge),
              if (entry.tags.isNotEmpty) ...[const SizedBox(height: 16),
                Wrap(spacing: 8, children: entry.tags.map((t) =>
                  Chip(label: Text('#$t'), backgroundColor: AppColors.accentGlow,
                    labelStyle: const TextStyle(color: AppColors.accent, fontSize: 12))
                ).toList()),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () { ref.read(kbProvider.notifier).delete(entry.id); Navigator.pop(context); },
                icon: const Icon(Icons.delete_rounded, color: AppColors.error),
                label: const Text('Delete Entry', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddEntrySheet extends StatefulWidget {
  final void Function(String, String, String, List<String>) onAdd;
  const _AddEntrySheet({required this.onAdd});
  @override State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _titleCtrl   = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _tagCtrl     = TextEditingController();
  String _category   = 'General';
  final _tags        = <String>[];
  static const _cats = ['General', 'FMGE', 'FA', 'Clinical', 'Theory', 'Notes'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C26) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 20),
            Text('Add Entry', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: _titleCtrl, autofocus: true,
                decoration: const InputDecoration(hintText: 'Title...')),
            const SizedBox(height: 12),
            TextField(controller: _contentCtrl, maxLines: 4,
                decoration: const InputDecoration(hintText: 'Content / notes...')),
            const SizedBox(height: 16),
            Text('Category', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: _cats.map((c) => FilterChip(
              label: Text(c), selected: _category == c,
              onSelected: (_) => setState(() => _category = c),
              selectedColor: AppColors.accentGlow,
            )).toList()),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _tagCtrl,
                  decoration: const InputDecoration(hintText: 'Add tag...'))),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.accent),
                onPressed: () {
                  if (_tagCtrl.text.trim().isNotEmpty) {
                    setState(() { _tags.add(_tagCtrl.text.trim()); _tagCtrl.clear(); });
                  }
                },
              ),
            ]),
            if (_tags.isNotEmpty) Wrap(
              spacing: 8,
              children: _tags.map((t) => Chip(
                label: Text(t),
                onDeleted: () => setState(() => _tags.remove(t)),
              )).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (_titleCtrl.text.trim().isNotEmpty) {
                    widget.onAdd(_titleCtrl.text.trim(), _contentCtrl.text.trim(), _category, List.from(_tags));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Entry', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
