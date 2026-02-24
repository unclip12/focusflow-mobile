// =============================================================
// AddHabitSheet — bottom sheet for adding a new habit.
// Fields: name, frequency (daily/weekdays/custom), color picker.
// Android rules: enableDrag: false, useSafeArea: true (set by caller).
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddHabitSheet extends StatefulWidget {
  final void Function(String name, String frequency, Color color) onSave;

  const AddHabitSheet({super.key, required this.onSave});

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final _nameCtrl = TextEditingController();
  String _frequency = 'Daily';
  int _selectedColorIdx = 0;

  static const _frequencies = ['Daily', 'Weekdays', 'Custom'];
  static const _habitColors = [
    Color(0xFF4CAF50), // Green
    Color(0xFF2196F3), // Blue
    Color(0xFFFF9800), // Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    HapticFeedback.lightImpact();
    widget.onSave(name, _frequency, _habitColors[_selectedColorIdx]);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ───────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Header ───────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'New Habit',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Form ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name field
                  Text('Habit Name',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'e.g. Meditate, Exercise...',
                      prefixIcon: Icon(Icons.edit_rounded,
                          size: 18,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                      filled: true,
                      fillColor: cs.onSurface.withValues(alpha: 0.04),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: cs.onSurface.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: cs.onSurface.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: cs.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Frequency selector
                  Text('Frequency',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 8),
                  Row(
                    children: _frequencies.map((f) {
                      final selected = _frequency == f;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _frequency = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? cs.primary.withValues(alpha: 0.15)
                                  : cs.onSurface.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? cs.primary.withValues(alpha: 0.4)
                                    : cs.onSurface
                                        .withValues(alpha: 0.08),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                f,
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
                                  color: selected
                                      ? cs.primary
                                      : cs.onSurface
                                          .withValues(alpha: 0.5),
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Color picker
                  Text('Color',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 8),
                  Row(
                    children:
                        List.generate(_habitColors.length, (i) {
                      final selected = _selectedColorIdx == i;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColorIdx = i),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _habitColors[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? cs.onSurface
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: _habitColors[i]
                                          .withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: selected
                              ? const Icon(Icons.check_rounded,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            SizedBox(
                height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}
