// =============================================================
// HabitCard — card with colored left border, habit name,
// checkbox, streak badge, and frequency label.
// =============================================================

import 'package:flutter/material.dart';

class HabitCard extends StatelessWidget {
  final String name;
  final bool completed;
  final Color color;
  final String frequency;
  final int streakDays;
  final ValueChanged<bool> onToggle;

  const HabitCard({
    super.key,
    required this.name,
    required this.completed,
    required this.color,
    required this.frequency,
    required this.streakDays,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // ── Colored left border ─────────────────────────
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),

            // ── Content ─────────────────────────────────────
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Checkbox
                    GestureDetector(
                      onTap: () => onToggle(!completed),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: completed
                              ? color
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: completed
                                ? color
                                : cs.onSurface.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: completed
                            ? const Icon(Icons.check_rounded,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name + frequency
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: completed
                                  ? cs.onSurface.withValues(alpha: 0.4)
                                  : cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            frequency,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.35),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Streak badge
                    if (streakDays > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🔥',
                                style: const TextStyle(fontSize: 10)),
                            const SizedBox(width: 3),
                            Text(
                              '$streakDays',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
