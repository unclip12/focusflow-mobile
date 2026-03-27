// =============================================================
// TodoTab — Category-grouped to-do list with time + duration
// Categories: Studies, Daily Life, Other
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/todo_item.dart';

class TodoTab extends StatelessWidget {
  final String dateKey;
  const TodoTab({super.key, required this.dateKey});

  static const _categories = ['Studies', 'Daily Life', 'Other'];
  static const _categoryIcons = {
    'Studies': Icons.school_rounded,
    'Daily Life': Icons.home_rounded,
    'Other': Icons.more_horiz_rounded,
  };
  static const _categoryColors = {
    'Studies': Color(0xFF8B5CF6),
    'Daily Life': Color(0xFF10B981),
    'Other': Color(0xFF6366F1),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final todos = app.getTodoItemsForDate(dateKey);

    return Column(
      children: [
        // ── Add button ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text(
                '${todos.where((t) => t.completed).length} of ${todos.length} done',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddTodo(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),

        // ── Category groups ───────────────────────────────────
        Expanded(
          child: todos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.checklist_rounded,
                          size: 48, color: cs.primary.withValues(alpha: 0.25)),
                      const SizedBox(height: 12),
                      Text(
                        'No to-do items yet',
                        style: TextStyle(
                          fontSize: 15,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + to add a task',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.of(context).padding.bottom + 72 + 24,
                  ),
                  children: _categories.map((cat) {
                    final catItems =
                        todos.where((t) => t.category == cat).toList();
                    if (catItems.isEmpty) return const SizedBox.shrink();
                    final color = _categoryColors[cat]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 6),
                          child: Row(
                            children: [
                              Icon(_categoryIcons[cat], size: 16, color: color),
                              const SizedBox(width: 6),
                              Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${catItems.where((t) => t.completed).length}/${catItems.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...catItems.map((item) => _TodoItemTile(
                              item: item,
                              color: color,
                              onToggle: () {
                                final updated = item.copyWith(
                                  completed: !item.completed,
                                  completedAt: !item.completed
                                      ? DateTime.now().toIso8601String()
                                      : null,
                                );
                                app.upsertTodoItem(updated);
                              },
                              onDelete: () => app.deleteTodoItem(item.id),
                            )),
                        const SizedBox(height: 4),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  void _showAddTodo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddTodoSheet(dateKey: dateKey),
    );
  }
}

// ── Todo Item Tile ──────────────────────────────────────────────
class _TodoItemTile extends StatelessWidget {
  final TodoItem item;
  final Color color;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TodoItemTile({
    required this.item,
    required this.color,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.delete_rounded, color: cs.error),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: item.completed
              ? color.withValues(alpha: 0.05)
              : cs.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          dense: true,
          leading: Checkbox(
            value: item.completed,
            onChanged: (_) => onToggle(),
            activeColor: color,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: item.completed ? TextDecoration.lineThrough : null,
              color: item.completed
                  ? cs.onSurface.withValues(alpha: 0.4)
                  : cs.onSurface,
            ),
          ),
          subtitle: _buildSubtitle(cs),
          trailing: item.scheduledTime != null
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.scheduledTime!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget? _buildSubtitle(ColorScheme cs) {
    final parts = <String>[];
    if (item.estimatedMinutes != null)
      parts.add('~${item.estimatedMinutes} min');
    if (item.notes != null && item.notes!.isNotEmpty) parts.add(item.notes!);
    if (parts.isEmpty) return null;
    return Text(
      parts.join(' • '),
      style:
          TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
    );
  }
}

// ── Add Todo Sheet ──────────────────────────────────────────────
class _AddTodoSheet extends StatefulWidget {
  final String dateKey;
  const _AddTodoSheet({required this.dateKey});

  @override
  State<_AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<_AddTodoSheet> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _category = 'Other';
  TimeOfDay? _scheduledTime;
  int? _estimatedMinutes;
  final _uuid = const Uuid();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    final app = context.read<AppProvider>();
    final todos = app.getTodoItemsForDate(widget.dateKey);

    final item = TodoItem(
      id: _uuid.v4(),
      title: _titleCtrl.text.trim(),
      category: _category,
      scheduledTime: _scheduledTime != null
          ? '${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'
          : null,
      estimatedMinutes: _estimatedMinutes,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
      date: widget.dateKey,
      sortOrder: todos.length,
      createdAt: DateTime.now().toIso8601String(),
    );
    app.upsertTodoItem(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add To-Do',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                )),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Task',
                hintText: 'e.g., Review Anatomy notes',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Category
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['Studies', 'Daily Life', 'Other'].map((cat) {
                    final selected = _category == cat;
                    return ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      selected: selected,
                      onSelected: (_) => setState(() => _category = cat),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Time + Duration
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (t != null) setState(() => _scheduledTime = t);
                    },
                    icon: const Icon(Icons.schedule_rounded, size: 16),
                    label: Text(
                      _scheduledTime != null
                          ? '${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'
                          : 'Time',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _estimatedMinutes = int.tryParse(v),
                    decoration: InputDecoration(
                      labelText: 'Minutes',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Add Task',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
