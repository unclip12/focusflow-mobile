// =============================================================
// MentorSuggestionsBar — horizontal scrollable chip row
// Sits above the input bar. Tap → fills input field text.
// =============================================================

import 'package:flutter/material.dart';

class MentorSuggestionsBar extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const MentorSuggestionsBar({super.key, required this.onSelect});

  static const _suggestions = [
    'What should I study today?',
    'Show my weak areas',
    'Give me a quiz tip',
    "How's my streak?",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final text = _suggestions[i];
          return GestureDetector(
            onTap: () => onSelect(text),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color:        cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(
                  color: cs.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                text,
                style: theme.textTheme.labelMedium?.copyWith(
                  color:      cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
