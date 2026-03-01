// =============================================================
// ActivitySelector — "What do you want to do?" bar
// Horizontal chip selector for quick-access to routines,
// study, shopping, and default chain.
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/default_routine_order.dart';
import 'package:focusflow_mobile/models/routine.dart';
import 'routine_runner_screen.dart';
import 'study_flow_screen.dart';
import 'shopping_flow_overlay.dart';
import 'default_order_sheet.dart';

class ActivitySelector extends StatelessWidget {
  final String dateKey;

  const ActivitySelector({super.key, required this.dateKey});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.08),
            cs.tertiary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rocket_launch_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'What do you want to do?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _openDefaultOrder(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.tune_rounded, size: 18,
                      color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ActivityChip(
                  emoji: '⚡',
                  label: 'Default',
                  color: const Color(0xFF6366F1),
                  onTap: () => _startDefault(context),
                ),
                const SizedBox(width: 8),
                _ActivityChip(
                  emoji: '🌅',
                  label: 'Routine',
                  color: const Color(0xFF10B981),
                  onTap: () => _pickRoutine(context),
                ),
                const SizedBox(width: 8),
                _ActivityChip(
                  emoji: '📚',
                  label: 'Study',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _startStudy(context),
                ),
                const SizedBox(width: 8),
                _ActivityChip(
                  emoji: '🛒',
                  label: 'Shopping',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _startShopping(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startDefault(BuildContext context) {
    final app = context.read<AppProvider>();
    if (app.defaultActivities.isEmpty) {
      _openDefaultOrder(context);
      return;
    }
    DefaultChainRunner.start(context, app.defaultActivities, dateKey);
  }

  void _pickRoutine(BuildContext context) {
    final app = context.read<AppProvider>();
    if (app.routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No routines yet. Create one from the Routines tab!')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RoutinePickerSheet(dateKey: dateKey),
    );
  }

  void _startStudy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyFlowScreen(dateKey: dateKey),
      ),
    );
  }

  void _startShopping(BuildContext context) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (_) => ShoppingFlowOverlay(dateKey: dateKey),
    );
  }

  void _openDefaultOrder(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const DefaultOrderSheet(),
    );
  }
}

// ── Default Chain Runner ────────────────────────────────────────
class DefaultChainRunner {
  static void start(
    BuildContext context,
    List<DefaultActivity> chain,
    String dateKey, {
    int startIndex = 0,
  }) {
    if (startIndex >= chain.length) return;
    final activity = chain[startIndex];
    final app = context.read<AppProvider>();

    switch (activity.type) {
      case ActivityType.morningRoutine:
      case ActivityType.eveningRoutine:
      case ActivityType.lunch:
      case ActivityType.custom:
      case ActivityType.fajrPrayer:
      case ActivityType.zuhrPrayer:
      case ActivityType.asrPrayer:
      case ActivityType.maghribPrayer:
      case ActivityType.ishaPrayer:
        // Try to find linked routine
        if (activity.routineId != null) {
          final routine = app.routines.firstWhere(
            (r) => r.id == activity.routineId,
            orElse: () => app.routines.isNotEmpty ? app.routines.first : _placeholderRoutine(activity),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RoutineRunnerScreen(
                routine: routine,
                dateKey: dateKey,
                onComplete: () {
                  start(context, chain, dateKey, startIndex: startIndex + 1);
                },
              ),
            ),
          );
        } else {
          start(context, chain, dateKey, startIndex: startIndex + 1);
        }
        break;
      case ActivityType.study:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudyFlowScreen(
              dateKey: dateKey,
              onComplete: () {
                start(context, chain, dateKey, startIndex: startIndex + 1);
              },
            ),
          ),
        );
        break;
      case ActivityType.shopping:
        showDialog(
          context: context,
          useSafeArea: false,
          builder: (_) => ShoppingFlowOverlay(dateKey: dateKey),
        ).then((_) {
          start(context, chain, dateKey, startIndex: startIndex + 1);
        });
        break;
      case ActivityType.sleep:
        // End of chain
        break;
    }
  }

  static _placeholderRoutine(DefaultActivity activity) {
    return _emptyRoutine(activity.displayLabel);
  }

  static _emptyRoutine(String name) {
    return Routine(
      id: 'empty',
      name: name,
      icon: '🔄',
      color: 0xFF6366F1,
      steps: [],
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}

// ── Routine Picker Sheet ────────────────────────────────────────
class _RoutinePickerSheet extends StatelessWidget {
  final String dateKey;
  const _RoutinePickerSheet({required this.dateKey});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scroll) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a Routine',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: app.routines.length,
              itemBuilder: (context, i) {
                final r = app.routines[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Text(r.icon, style: const TextStyle(fontSize: 24)),
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${r.steps.length} steps • ~${r.totalEstimatedMinutes} min',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                    trailing: Icon(Icons.play_arrow_rounded, color: cs.primary),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RoutineRunnerScreen(
                            routine: r,
                            dateKey: dateKey,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity Chip ───────────────────────────────────────────────
class _ActivityChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActivityChip({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
