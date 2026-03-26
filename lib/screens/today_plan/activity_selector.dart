// =============================================================
// ActivitySelector — "What do you want to do?" bar
// Premium Redesign with glassmorphic chips
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/app_provider.dart';
import 'package:focusflow_mobile/models/default_routine_order.dart';
import 'package:focusflow_mobile/models/daily_flow.dart';
import 'package:focusflow_mobile/models/routine.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.60),
                        Colors.white.withValues(alpha: 0.35),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? DashboardColors.glassBorderDark
                    : DashboardColors.glassBorderLight,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.rocket_launch_rounded,
                          size: 14, color: cs.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () => _openDefaultOrder(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.tune_rounded,
                              size: 16,
                              color: cs.onSurface.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _PremiumChip(
                        emoji: '📋',
                        label: 'Template',
                        color: const Color(0xFF6366F1),
                        isDark: isDark,
                        onTap: () => _openDefaultOrder(context),
                      ),
                      const SizedBox(width: 8),
                      _PremiumChip(
                        emoji: '🌅',
                        label: 'Routine',
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                        onTap: () => _pickRoutine(context),
                      ),
                      const SizedBox(width: 8),
                      _PremiumChip(
                        emoji: '📚',
                        label: 'Study',
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                        onTap: () => _startStudy(context),
                      ),
                      const SizedBox(width: 8),
                      _PremiumChip(
                        emoji: '🛒',
                        label: 'Shopping',
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                        onTap: () => _startShopping(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickRoutine(BuildContext context) =>
      ActivityActions.pickRoutine(context, dateKey);

  void _startStudy(BuildContext context) =>
      ActivityActions.startStudy(context, dateKey);

  void _startShopping(BuildContext context) =>
      ActivityActions.startShopping(context, dateKey);

  void _openDefaultOrder(BuildContext context) =>
      ActivityActions.openDefaultOrder(context, dateKey);
}

// =============================================================
// ActivityActions — Static helper for reusable quick action logic
// Used by both ActivitySelector widget and inline header chips
// =============================================================
class ActivityActions {
  ActivityActions._();

  static void pickRoutine(BuildContext context, String dateKey) {
    final app = context.read<AppProvider>();
    if (app.routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No routines yet. Create one from the Routines tab!')),
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

  static void startStudy(BuildContext context, String dateKey) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyFlowScreen(dateKey: dateKey),
      ),
    );
  }

  static void startShopping(BuildContext context, String dateKey) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (_) => ShoppingFlowOverlay(dateKey: dateKey),
    );
  }

  static void openDefaultOrder(BuildContext context, String dateKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DefaultOrderSheet(dateKey: dateKey),
    );
  }

  /// Add a 25-minute Pomodoro focus timer as a flow activity
  static void startFocusTimer(BuildContext context, String dateKey) {
    final app = context.read<AppProvider>();
    final activity = FlowActivity(
      id: 'focus-${DateTime.now().millisecondsSinceEpoch}',
      label: 'Focus Session',
      icon: '⏱️',
      activityType: 'custom',
      sortOrder: 999,
      category: 'Focus',
      durationSeconds: 25 * 60,
    );
    app.addFlowActivity(dateKey, activity);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏱️ 25-min Focus Session added!'),
        duration: Duration(seconds: 2),
      ),
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
        if (activity.routineId != null) {
          final routine = app.routines.firstWhere(
            (r) => r.id == activity.routineId,
            orElse: () => app.routines.isNotEmpty
                ? app.routines.first
                : _placeholderRoutine(activity),
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
          if (context.mounted) {
            start(context, chain, dateKey, startIndex: startIndex + 1);
          }
        });
        break;
      case ActivityType.sleep:
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
                    leading:
                        Text(r.icon, style: const TextStyle(fontSize: 24)),
                    title: Text(r.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${r.steps.length} steps • ~${r.totalEstimatedMinutes} min',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              cs.onSurface.withValues(alpha: 0.5)),
                    ),
                    trailing:
                        Icon(Icons.play_arrow_rounded, color: cs.primary),
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

// ── Premium Activity Chip ───────────────────────────────────────
class _PremiumChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _PremiumChip({
    required this.emoji,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.18 : 0.12),
            color.withValues(alpha: isDark ? 0.08 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.15),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
