// =============================================================
// DefaultOrderSheet — Configure the default activity chain
// Reorderable list of activities for the "Default" button
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/default_routine_order.dart';

class DefaultOrderSheet extends StatefulWidget {
  const DefaultOrderSheet({super.key});

  @override
  State<DefaultOrderSheet> createState() => _DefaultOrderSheetState();
}

class _DefaultOrderSheetState extends State<DefaultOrderSheet> {
  List<DefaultActivity> _activities = [];
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    if (app.defaultActivities.isNotEmpty) {
      _activities = List.from(app.defaultActivities);
    } else {
      // Seed with a default chain
      _activities = [
        DefaultActivity(id: _uuid.v4(), type: ActivityType.morningRoutine, sortOrder: 0),
        DefaultActivity(id: _uuid.v4(), type: ActivityType.study, sortOrder: 1),
        DefaultActivity(id: _uuid.v4(), type: ActivityType.lunch, sortOrder: 2),
        DefaultActivity(id: _uuid.v4(), type: ActivityType.study, sortOrder: 3),
        DefaultActivity(id: _uuid.v4(), type: ActivityType.shopping, sortOrder: 4),
        DefaultActivity(id: _uuid.v4(), type: ActivityType.eveningRoutine, sortOrder: 5),
      ];
    }
  }

  void _addActivity() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Add Activity'),
        children: ActivityType.values.map((type) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() {
                _activities.add(DefaultActivity(
                  id: _uuid.v4(),
                  type: type,
                  sortOrder: _activities.length,
                ));
              });
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Text(type.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(type.label),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _save() {
    final updated = _activities.asMap().entries.map((e) =>
        e.value.copyWith(sortOrder: e.key)).toList();
    context.read<AppProvider>().saveDefaultActivities(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.read<AppProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
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
            Row(
              children: [
                const Icon(Icons.tune_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Default Activity Chain',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Drag to reorder. These activities will run in sequence when you tap "Default".',
              style: TextStyle(
                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ReorderableListView.builder(
                scrollController: scroll,
                itemCount: _activities.length,
                onReorder: (old, newIdx) {
                  setState(() {
                    if (newIdx > old) newIdx--;
                    final a = _activities.removeAt(old);
                    _activities.insert(newIdx, a);
                  });
                },
                itemBuilder: (context, i) {
                  final a = _activities[i];
                  // Try to find linked routine name
                  String? linkedName;
                  if (a.routineId != null) {
                    try {
                      linkedName = app.routines.firstWhere((r) => r.id == a.routineId).name;
                    } catch (_) {}
                  }

                  return Card(
                    key: Key(a.id),
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Text(a.displayIcon, style: const TextStyle(fontSize: 22)),
                      title: Text(
                        a.displayLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: linkedName != null
                          ? Text('→ $linkedName',
                              style: TextStyle(fontSize: 11,
                                  color: cs.primary.withValues(alpha: 0.7)))
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Link routine
                          if (a.type == ActivityType.morningRoutine ||
                              a.type == ActivityType.eveningRoutine ||
                              a.type == ActivityType.custom)
                            IconButton(
                              icon: Icon(Icons.link_rounded, size: 18,
                                  color: cs.primary.withValues(alpha: 0.5)),
                              onPressed: () => _linkRoutine(i),
                              tooltip: 'Link to routine',
                            ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, size: 18,
                                color: cs.error.withValues(alpha: 0.5)),
                            onPressed: () => setState(() => _activities.removeAt(i)),
                          ),
                          Icon(Icons.drag_handle_rounded, size: 18,
                              color: cs.onSurface.withValues(alpha: 0.2)),
                        ],
                      ),
                      dense: true,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addActivity,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Activity'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _linkRoutine(int index) {
    final app = context.read<AppProvider>();
    if (app.routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a routine first!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Link Routine'),
        children: app.routines.map((r) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() {
                _activities[index] = _activities[index].copyWith(routineId: r.id);
              });
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Text(r.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(r.name),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
