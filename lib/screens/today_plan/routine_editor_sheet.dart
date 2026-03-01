// =============================================================
// RoutineEditorSheet — Create / edit routines with reorderable steps
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/routine.dart';

class RoutineEditorSheet extends StatefulWidget {
  final Routine? existing;
  const RoutineEditorSheet({super.key, this.existing});

  @override
  State<RoutineEditorSheet> createState() => _RoutineEditorSheetState();
}

class _RoutineEditorSheetState extends State<RoutineEditorSheet> {
  final _nameCtrl = TextEditingController();
  final _uuid = const Uuid();
  String _icon = '🌅';
  int _color = 0xFF6366F1;
  List<RoutineStep> _steps = [];

  static const _icons = ['🌅', '🌙', '🏋️', '🧘', '🍽️', '📚', '🛁', '🎯', '💼', '🔄'];
  static const _colors = [
    0xFF6366F1, 0xFF10B981, 0xFF8B5CF6, 0xFFF59E0B,
    0xFFEC4899, 0xFF14B8A6, 0xFFF97316, 0xFF3B82F6,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _icon = widget.existing!.icon;
      _color = widget.existing!.color;
      _steps = List.from(widget.existing!.steps);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addStep() {
    final ctrl = TextEditingController();
    final durCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Step'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Step title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: durCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Estimated minutes (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  _steps.add(RoutineStep(
                    id: _uuid.v4(),
                    title: ctrl.text.trim(),
                    estimatedMinutes: int.tryParse(durCtrl.text),
                    sortOrder: _steps.length,
                  ));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final app = context.read<AppProvider>();
    final now = DateTime.now().toIso8601String();

    final routine = Routine(
      id: widget.existing?.id ?? _uuid.v4(),
      name: _nameCtrl.text.trim(),
      icon: _icon,
      color: _color,
      steps: _steps.asMap().entries.map((e) =>
          e.value.copyWith(sortOrder: e.key)).toList(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    app.upsertRoutine(routine);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scroll) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 32, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit Routine' : 'Create Routine',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Routine name',
                hintText: 'e.g., Morning Routine',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Icon picker
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _icons.map((icon) {
                  final selected = _icon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _icon = icon),
                    child: Container(
                      width: 40,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: selected ? cs.primary.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // Color picker
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _colors.map((c) {
                  final selected = _color == c;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 32,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(
                                color: Color(c).withValues(alpha: 0.5),
                                blurRadius: 8,
                              )]
                            : null,
                      ),
                      child: selected
                          ? const Center(child: Icon(Icons.check_rounded, size: 16, color: Colors.white))
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Steps header
            Row(
              children: [
                Text('Steps', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface,
                )),
                const SizedBox(width: 4),
                Text(
                  '(${_steps.length})',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Step', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),

            // Steps list
            Expanded(
              child: _steps.isEmpty
                  ? Center(
                      child: Text(
                        'Tap "Add Step" to create routine steps',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      scrollController: scroll,
                      itemCount: _steps.length,
                      onReorder: (old, newIdx) {
                        setState(() {
                          if (newIdx > old) newIdx--;
                          final s = _steps.removeAt(old);
                          _steps.insert(newIdx, s);
                        });
                      },
                      itemBuilder: (context, i) {
                        final s = _steps[i];
                        return ListTile(
                          key: Key(s.id),
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(_color).withValues(alpha: 0.15),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(_color),
                              ),
                            ),
                          ),
                          title: Text(
                            s.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          subtitle: s.estimatedMinutes != null
                              ? Text('~${s.estimatedMinutes} min',
                                  style: TextStyle(fontSize: 11,
                                      color: cs.onSurface.withValues(alpha: 0.4)))
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded, size: 18,
                                    color: cs.error.withValues(alpha: 0.6)),
                                onPressed: () => setState(() => _steps.removeAt(i)),
                              ),
                              Icon(Icons.drag_handle_rounded, size: 18,
                                  color: cs.onSurface.withValues(alpha: 0.2)),
                            ],
                          ),
                          dense: true,
                        );
                      },
                    ),
            ),

            const SizedBox(height: 8),

            // Save
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: Color(_color),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isEdit ? 'Save Changes' : 'Create Routine',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
