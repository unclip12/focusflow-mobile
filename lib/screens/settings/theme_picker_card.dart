// =============================================================
// ThemePickerCard — compact card showing theme preview
// 3 colored circles (primary/secondary/background), theme name,
// checkmark if selected. Tap → SettingsProvider.changeTheme().
// =============================================================

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/utils/app_theme.dart';

final List<ThemePreset> kThemePresets = AppTheme.themePresets;

class ThemePickerCard extends StatelessWidget {
  final ThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  const ThemePickerCard({
    super.key,
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final previewBackground =
        preset.previewBackground(theme.brightness == Brightness.dark);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? preset.primary
                : cs.onSurface.withValues(alpha: 0.08),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 3 colour circles ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Circle(color: preset.primary, size: 18),
                const SizedBox(width: 3),
                _Circle(color: preset.secondary, size: 18),
                const SizedBox(width: 3),
                _Circle(color: previewBackground, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            // ── Name ─────────────────────────────────────────────
            Text(
              preset.name,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? preset.primary
                    : cs.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // ── Checkmark ────────────────────────────────────────
            if (selected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.check_circle_rounded,
                    size: 16, color: preset.primary),
              ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final Color color;
  final double size;

  const _Circle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
    );
  }
}
