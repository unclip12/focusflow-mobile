// =============================================================
// DefaultOrderSheet — Configure the default activity chain
// Reorderable list with renaming, task linking, prayer types
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/default_routine_order.dart';
import 'package:intl/intl.dart';
import 'task_linker_sheet.dart';

class DefaultOrderSheet extends StatefulWidget {
  final String dateKey;
  const DefaultOrderSheet({super.key, required this.dateKey});

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
      _activities = [
        DefaultActivity(id: _uuid.v4(), type: ActivityType.fajrPrayer, sortOrder: 0),
        DefaultActivity(id: _uuid.v4(), type: ActivityType.morningRoutine, sortOrder: 1),
        DefaultActivity(id: _uuid.v4(), type: ActivityType.study, sortOrder: 2),
        DefaultActivity(id: _uuid.v4(), type: ActivityType.zuhrPrayer, sortOrder: 3),
        DefaultActivity(id: _uuid.v4(), type: ActivityType.study, sortOrder: 4),
        DefaultActivity(id: _uuid.v4(), type: ActivityType.asrPrayer, sortOrder: 5),
        DefaultActivity(id: _uuid.v4(), type: ActivityType.study, sortOrder: 6),
        DefaultActivity(id: _uuid.v4(), type: ActivityType.maghribPrayer, sortOrder: 7),
        DefaultActivity(id: _uuid.v4(), type: ActivityType.eveningRoutine, sortOrder: 8),
        DefaultActivity(id: _uuid.v4(), type: ActivityType.ishaPrayer, sortOrder: 9),
        DefaultActivity(id: _uuid.v4(), type: ActivityType.sleep, sortOrder: 10),
      ];
    }
  }

  void _addActivity() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Activity',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface,
                  )),
              const SizedBox(height: 4),
              Text('Choose a type or create a custom one',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
              const SizedBox(height: 16),

              // Custom activity first
              _AddOptionTile(
                icon: '✏️', label: 'Custom Activity',
                subtitle: 'Name it yourself',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCustomNameDialog();
                },
              ),
              const Divider(height: 16),

              // Standard types
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: ActivityType.values.map((type) {
                      return _AddOptionTile(
                        icon: type.icon, label: type.label,
                        color: _typeColor(type),
                        onTap: () {
                          setState(() {
                            _activities.add(DefaultActivity(
                              id: _uuid.v4(),
                              type: type,
                              sortOrder: _activities.length,
                            ));
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCustomNameDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Activity'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Activity name...',
            filled: true,
            fillColor: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
              setState(() {
                _activities.add(DefaultActivity(
                  id: _uuid.v4(),
                  type: ActivityType.custom,
                  label: name,
                  sortOrder: _activities.length,
                ));
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _renameActivity(int index) {
    final a = _activities[index];
    final nameCtrl = TextEditingController(text: a.label ?? a.type.label);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Activity'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'New name...',
            filled: true,
            fillColor: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
              setState(() {
                _activities[index] = a.copyWith(label: name);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _linkTasks(int index) {
    final a = _activities[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskLinkerSheet(
        dateKey: '', // empty = all tasks
        initialSelectedIds: a.linkedTaskIds,
        onSave: (ids) {
          setState(() {
            _activities[index] = a.copyWith(linkedTaskIds: ids);
          });
        },
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

    final a = _activities[index];
    // For prayer types, filter to prayer routines
    final isPrayer = a.type == ActivityType.fajrPrayer ||
        a.type == ActivityType.zuhrPrayer ||
        a.type == ActivityType.asrPrayer ||
        a.type == ActivityType.maghribPrayer ||
        a.type == ActivityType.ishaPrayer;
    
    final routines = isPrayer
        ? app.routines.where((r) => r.id.startsWith('prayer_')).toList()
        : app.routines;

    if (routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isPrayer ? 'No prayer routines found' : 'No routines found')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(isPrayer ? 'Link Prayer Routine' : 'Link Routine'),
        children: [
          // Option to unlink
          if (a.routineId != null)
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _activities[index] = DefaultActivity(
                    id: a.id,
                    type: a.type,
                    label: a.label,
                    sortOrder: a.sortOrder,
                    linkedTaskIds: a.linkedTaskIds,
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Row(
                children: [
                  Icon(Icons.link_off_rounded, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Unlink', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ...routines.map((r) {
            final isLinked = a.routineId == r.id;
            return SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _activities[index] = a.copyWith(routineId: r.id);
                });
                Navigator.pop(ctx);
              },
              child: Row(
                children: [
                  Text(r.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(r.name)),
                  if (isLinked)
                    const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF10B981)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _save() {
    final updated = _activities.asMap().entries.map((e) =>
        e.value.copyWith(sortOrder: e.key)).toList();
    context.read<AppProvider>().saveDefaultActivities(updated);
    Navigator.pop(context);
  }

  Color _typeColor(ActivityType type) {
    switch (type) {
      case ActivityType.fajrPrayer: return const Color(0xFF6366F1);
      case ActivityType.zuhrPrayer: return const Color(0xFFF59E0B);
      case ActivityType.asrPrayer: return const Color(0xFFEC4899);
      case ActivityType.maghribPrayer: return const Color(0xFFEF4444);
      case ActivityType.ishaPrayer: return const Color(0xFF6366F1);
      case ActivityType.morningRoutine: return const Color(0xFF10B981);
      case ActivityType.eveningRoutine: return const Color(0xFF8B5CF6);
      case ActivityType.study: return const Color(0xFF3B82F6);
      case ActivityType.shopping: return const Color(0xFFF59E0B);
      case ActivityType.lunch: return const Color(0xFFEC4899);
      case ActivityType.custom: return const Color(0xFF8B5CF6);
      case ActivityType.sleep: return const Color(0xFF6B7280);
    }
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
                Expanded(
                  child: Text(
                    'Activity Template',
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your everyday routine template. Drag to reorder, tap to edit.',
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
                  String? linkedName;
                  if (a.routineId != null) {
                    try {
                      linkedName = app.routines.firstWhere((r) => r.id == a.routineId).name;
                    } catch (_) {}
                  }
                  final hasLinkedTasks = a.linkedTaskIds.isNotEmpty;
                  final color = _typeColor(a.type);

                  return Card(
                    key: Key(a.id),
                    margin: const EdgeInsets.only(bottom: 6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    child: InkWell(
                      onTap: () => _showActivityOptions(i),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            // Type indicator
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(a.displayIcon, style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Label + metadata
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.displayLabel,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  if (linkedName != null || hasLinkedTasks)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        children: [
                                          if (linkedName != null) ...[
                                            Icon(Icons.link_rounded, size: 11, color: cs.primary.withValues(alpha: 0.5)),
                                            const SizedBox(width: 3),
                                            Text(linkedName,
                                                style: TextStyle(fontSize: 10, color: cs.primary.withValues(alpha: 0.6))),
                                          ],
                                          if (linkedName != null && hasLinkedTasks)
                                            const SizedBox(width: 6),
                                          if (hasLinkedTasks) ...[
                                            Icon(Icons.task_alt_rounded, size: 11, color: cs.tertiary.withValues(alpha: 0.5)),
                                            const SizedBox(width: 3),
                                            Text('${a.linkedTaskIds.length} task${a.linkedTaskIds.length == 1 ? '' : 's'}',
                                                style: TextStyle(fontSize: 10, color: cs.tertiary.withValues(alpha: 0.6))),
                                          ],
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Delete + drag handle
                            IconButton(
                              icon: Icon(Icons.close_rounded, size: 16,
                                  color: cs.error.withValues(alpha: 0.4)),
                              onPressed: () => setState(() => _activities.removeAt(i)),
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                            ),
                            Icon(Icons.drag_handle_rounded, size: 18,
                                color: cs.onSurface.withValues(alpha: 0.2)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Add Activity + Save Template row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addActivity,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
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
                    child: const Text('Save Template', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Plan for date buttons
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan this template for…',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _PlanChip(
                          label: '📅 Today',
                          color: const Color(0xFF10B981),
                          onTap: () => _planForDate(context, widget.dateKey),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PlanChip(
                          label: '🗓️ Tomorrow',
                          color: const Color(0xFF3B82F6),
                          onTap: () {
                            final tomorrow = DateTime.now().add(const Duration(days: 1));
                            final key = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
                            _planForDate(context, key);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PlanChip(
                          label: '📆 Pick Date',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => _pickDateAndPlan(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showActivityOptions(int index) {
    final cs = Theme.of(context).colorScheme;
    final a = _activities[index];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(a.displayIcon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(a.displayLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded, size: 20),
              title: const Text('Rename'),
              subtitle: const Text('Give this activity a custom name', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _renameActivity(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded, size: 20),
              title: const Text('Link Routine'),
              subtitle: Text(
                a.routineId != null ? 'Change linked routine' : 'Connect to an existing routine',
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _linkRoutine(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.task_alt_rounded, size: 20),
              title: const Text('Link Tasks'),
              subtitle: Text(
                a.linkedTaskIds.isNotEmpty
                    ? '${a.linkedTaskIds.length} task${a.linkedTaskIds.length == 1 ? '' : 's'} linked'
                    : 'Attach to-dos or study items',
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _linkTasks(index);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, size: 20, color: cs.error),
              title: Text('Remove', style: TextStyle(color: cs.error)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _activities.removeAt(index));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _planForDate(BuildContext context, String dateKey) {
    // Save template first (inline, without popping)
    final updated = _activities.asMap().entries.map((e) =>
        e.value.copyWith(sortOrder: e.key)).toList();
    final app = context.read<AppProvider>();
    app.saveDefaultActivities(updated);

    // Clone template to the target date
    app.planFlowFromTemplate(dateKey).then((_) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Flow planned for $dateKey ✅'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _pickDateAndPlan(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
    );
    if (picked != null && context.mounted) {
      final key = DateFormat('yyyy-MM-dd').format(picked);
      _planForDate(context, key);
    }
  }
}

class _AddOptionTile extends StatelessWidget {
  final String icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AddOptionTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)))
          : null,
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PlanChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PlanChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
