// =============================================================
// ThemePickerCard — compact card showing theme preview
// 3 colored circles (primary/secondary/background), theme name,
// checkmark if selected. Tap → SettingsProvider.changeTheme().
// =============================================================

import 'package:flutter/material.dart';

/// Definition of a selectable theme preset.
class ThemePreset {
  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
  });
}

/// All 12 available theme presets.
const List<ThemePreset> kThemePresets = [
  ThemePreset(
      id: 'default',
      name: 'Indigo',
      primary: Color(0xFF6366F1),
      secondary: Color(0xFF818CF8),
      background: Color(0xFF0A0A0F)),
  ThemePreset(
      id: 'violet',
      name: 'Violet',
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFFA78BFA),
      background: Color(0xFF0F0A1A)),
  ThemePreset(
      id: 'rose',
      name: 'Rose',
      primary: Color(0xFFF43F5E),
      secondary: Color(0xFFFB7185),
      background: Color(0xFF1A0A0F)),
  ThemePreset(
      id: 'emerald',
      name: 'Emerald',
      primary: Color(0xFF10B981),
      secondary: Color(0xFF34D399),
      background: Color(0xFF0A1A12)),
  ThemePreset(
      id: 'amber',
      name: 'Amber',
      primary: Color(0xFFF59E0B),
      secondary: Color(0xFFFBBF24),
      background: Color(0xFF1A150A)),
  ThemePreset(
      id: 'cyan',
      name: 'Cyan',
      primary: Color(0xFF06B6D4),
      secondary: Color(0xFF22D3EE),
      background: Color(0xFF0A141A)),
  ThemePreset(
      id: 'pink',
      name: 'Pink',
      primary: Color(0xFFEC4899),
      secondary: Color(0xFFF472B6),
      background: Color(0xFF1A0A14)),
  ThemePreset(
      id: 'orange',
      name: 'Orange',
      primary: Color(0xFFF97316),
      secondary: Color(0xFFFB923C),
      background: Color(0xFF1A100A)),
  ThemePreset(
      id: 'teal',
      name: 'Teal',
      primary: Color(0xFF14B8A6),
      secondary: Color(0xFF2DD4BF),
      background: Color(0xFF0A1A18)),
  ThemePreset(
      id: 'blue',
      name: 'Blue',
      primary: Color(0xFF3B82F6),
      secondary: Color(0xFF60A5FA),
      background: Color(0xFF0A0F1A)),
  ThemePreset(
      id: 'lime',
      name: 'Lime',
      primary: Color(0xFF84CC16),
      secondary: Color(0xFFA3E635),
      background: Color(0xFF121A0A)),
  ThemePreset(
      id: 'slate',
      name: 'Slate',
      primary: Color(0xFF64748B),
      secondary: Color(0xFF94A3B8),
      background: Color(0xFF0F1114)),
];

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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.surface,
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
                _Circle(color: preset.background, size: 18),
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
