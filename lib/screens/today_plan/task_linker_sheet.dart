// =============================================================
// TaskLinkerSheet — bottom sheet to link tasks to flow activities
// Shows to-dos, study plan items, routines with multi-select
// Plus inline creation of new tasks/routines
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/todo_item.dart';

class TaskLinkerSheet extends StatefulWidget {
  final String dateKey;
  final List<String> initialSelectedIds;
  final ValueChanged<List<String>> onSave;

  const TaskLinkerSheet({
    super.key,
    required this.dateKey,
    this.initialSelectedIds = const [],
    required this.onSave,
  });

  @override
  State<TaskLinkerSheet> createState() => _TaskLinkerSheetState();
}

class _TaskLinkerSheetState extends State<TaskLinkerSheet> {
  late Set<String> _selected;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelectedIds);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final allTodos = app.todoItems;
    final routines = app.routines;

    // Merge date-specific and all items for linking
    final linkableItems = <_LinkableItem>[];

    // Add todos
    for (final t in allTodos) {
      if (_search.isNotEmpty &&
          !t.title.toLowerCase().contains(_search.toLowerCase())) continue;
      linkableItems.add(_LinkableItem(
        id: t.id,
        title: t.title,
        subtitle: '${t.category} • ${t.date}',
        icon: Icons.check_circle_outline_rounded,
        color: cs.primary,
      ));
    }

    // Add routines
    for (final r in routines) {
      if (_search.isNotEmpty &&
          !r.name.toLowerCase().contains(_search.toLowerCase())) continue;
      linkableItems.add(_LinkableItem(
        id: r.id,
        title: r.name,
        subtitle: '${r.steps.length} steps • ~${r.totalEstimatedMinutes}min',
        icon: Icons.repeat_rounded,
        color: Color(r.color),
      ));
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Link Tasks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      )),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      widget.onSave(_selected.toList());
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Save (${_selected.length})'),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search tasks & routines...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor:
                      cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),

            // Quick create buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _QuickCreateChip(
                    label: '+ New Task',
                    onTap: () => _createNewTodo(context),
                  ),
                  const SizedBox(width: 8),
                  _QuickCreateChip(
                    label: '+ New Routine',
                    onTap: () {
                      // Navigate to routine editor
                      Navigator.pop(context);
                      // The user can create from the Routines tab
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // List
            Expanded(
              child: linkableItems.isEmpty
                  ? Center(
                      child: Text(
                        'No items found',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: linkableItems.length,
                      itemBuilder: (ctx, i) {
                        final item = linkableItems[i];
                        final isSelected = _selected.contains(item.id);
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isSelected
                                ? BorderSide(
                                    color: cs.primary.withValues(alpha: 0.4))
                                : BorderSide.none,
                          ),
                          color: isSelected
                              ? cs.primary.withValues(alpha: 0.06)
                              : cs.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                          child: ListTile(
                            dense: true,
                            leading: Icon(item.icon,
                                size: 20, color: item.color),
                            title: Text(item.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                )),
                            subtitle: Text(item.subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                )),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selected.add(item.id);
                                  } else {
                                    _selected.remove(item.id);
                                  }
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selected.remove(item.id);
                                } else {
                                  _selected.add(item.id);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _createNewTodo(BuildContext context) {
    final nameCtrl = TextEditingController();
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Task'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Task name...',
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final id = const Uuid().v4();
              final todo = TodoItem(
                id: id,
                title: name,
                category: 'Other',
                date: widget.dateKey,
                sortOrder: 0,
                createdAt: DateTime.now().toIso8601String(),
              );
              context.read<AppProvider>().upsertTodoItem(todo);
              setState(() => _selected.add(id));
              Navigator.pop(ctx);
            },
            child: const Text('Create & Link'),
          ),
        ],
      ),
    );
  }
}

class _LinkableItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _LinkableItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _QuickCreateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickCreateChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ActionChip(
      label: Text(label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cs.primary,
          )),
      onPressed: onTap,
      avatar: null,
      backgroundColor: cs.primary.withValues(alpha: 0.06),
      side: BorderSide(color: cs.primary.withValues(alpha: 0.15)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
