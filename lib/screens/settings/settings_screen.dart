// =============================================================
// SettingsScreen — grouped settings list via AppScaffold
// Sections: Appearance, Notifications, Menu, Data, About
// Android rules: resizeToAvoidBottomInset: true on Scaffolds,
//                enableDrag: false, useSafeArea: true on sheets.
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/models/app_settings.dart';
import 'package:focusflow_mobile/utils/constants.dart';
import 'package:focusflow_mobile/widgets/app_scaffold.dart';
import 'package:focusflow_mobile/screens/settings/theme_picker_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppScaffold(
      screenName: 'Settings',
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ═════════════════════════════════════════════════════════
          // APPEARANCE
          // ═════════════════════════════════════════════════════════
          _SectionHeader(title: 'Appearance'),
          const SizedBox(height: 8),

          // ── Theme picker (horizontal scroll) ────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: kThemePresets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final preset = kThemePresets[i];
                      return ThemePickerCard(
                        preset: preset,
                        selected: sp.currentTheme == preset.id,
                        onTap: () => sp.changeTheme(preset.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Dark mode toggle ────────────────────────────────────
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            trailing: Switch.adaptive(
              value: sp.isDarkMode,
              activeColor: cs.primary,
              onChanged: (_) => sp.toggleDarkMode(),
            ),
          ),
          const SizedBox(height: 8),

          // ── Font size slider ────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.text_fields_rounded,
                        size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text('Font Size',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                    const Spacer(),
                    Text(
                      sp.fontSize[0].toUpperCase() +
                          sp.fontSize.substring(1),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: kFontSizes.map((size) {
                    final selected = sp.fontSize == size;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => sp.changeFontSize(size),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? cs.primary.withValues(alpha: 0.15)
                                : cs.onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? cs.primary.withValues(alpha: 0.4)
                                  : cs.onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              size[0].toUpperCase() + size.substring(1),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: selected
                                    ? cs.primary
                                    : cs.onSurface.withValues(alpha: 0.5),
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
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ═════════════════════════════════════════════════════════
          // NOTIFICATIONS
          // ═════════════════════════════════════════════════════════
          _SectionHeader(title: 'Notifications'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.do_not_disturb_on_rounded,
            title: 'Quiet Hours',
            subtitle: sp.settings.quietHours.enabled
                ? '${sp.settings.quietHours.start} – ${sp.settings.quietHours.end}'
                : 'Disabled',
            trailing: Switch.adaptive(
              value: sp.settings.quietHours.enabled,
              activeColor: cs.primary,
              onChanged: (_) {
                sp.updateQuietHours(sp.settings.quietHours
                    .copyWith(enabled: !sp.settings.quietHours.enabled));
              },
            ),
          ),
          // ── Time pickers (shown when quiet hours enabled) ───────
          if (sp.settings.quietHours.enabled) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    label: 'Start',
                    time: sp.settings.quietHours.start,
                    onTap: () => _pickTime(
                      context,
                      sp.settings.quietHours.start,
                      (t) => sp.updateQuietHours(
                          sp.settings.quietHours.copyWith(start: t)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimeTile(
                    label: 'End',
                    time: sp.settings.quietHours.end,
                    onTap: () => _pickTime(
                      context,
                      sp.settings.quietHours.end,
                      (t) => sp.updateQuietHours(
                          sp.settings.quietHours.copyWith(end: t)),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // ═════════════════════════════════════════════════════════
          // MENU CONFIGURATION
          // ═════════════════════════════════════════════════════════
          _SectionHeader(title: 'Menu'),
          const SizedBox(height: 8),
          _MenuReorderSection(sp: sp),
          const SizedBox(height: 20),

          // ═════════════════════════════════════════════════════════
          // DATA
          // ═════════════════════════════════════════════════════════
          _SectionHeader(title: 'Data'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.backup_rounded,
                  label: 'Backup Now',
                  color: cs.primary,
                  onTap: () => _showPlaceholder(context, 'Backup'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.restore_rounded,
                  label: 'Restore',
                  color: cs.secondary,
                  onTap: () => _showPlaceholder(context, 'Restore'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ═════════════════════════════════════════════════════════
          // ABOUT
          // ═════════════════════════════════════════════════════════
          _SectionHeader(title: 'About'),
          const SizedBox(height: 8),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow('App', 'FocusFlow'),
                _DetailRow('Version', '1.0.0'),
                _DetailRow('Build', '1'),
                const SizedBox(height: 4),
                Text(
                  'Built with ❤️ for FMGE prep',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Time picker helper ─────────────────────────────────────────
  Future<void> _pickTime(
      BuildContext context, String current, ValueChanged<String> onPicked) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 22,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onPicked(formatted);
    }
  }

  void _showPlaceholder(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action coming soon'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.5),
          ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                      )),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 8),
            Text(label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                )),
            const Spacer(),
            Text(time,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Text(label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                )),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.45),
              )),
          const Spacer(),
          Text(value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MENU REORDER SECTION
// ═══════════════════════════════════════════════════════════════════

class _MenuReorderSection extends StatefulWidget {
  final SettingsProvider sp;
  const _MenuReorderSection({required this.sp});

  @override
  State<_MenuReorderSection> createState() => _MenuReorderSectionState();
}

class _MenuReorderSectionState extends State<_MenuReorderSection> {
  late List<MenuItemConfig> _items;

  @override
  void initState() {
    super.initState();
    _syncItems();
  }

  @override
  void didUpdateWidget(_MenuReorderSection old) {
    super.didUpdateWidget(old);
    _syncItems();
  }

  void _syncItems() {
    final existing = widget.sp.menuConfiguration;
    if (existing.isNotEmpty) {
      _items = existing.toList();
    } else {
      _items = kDefaultMenuOrder
          .map((id) => MenuItemConfig(id: id, visible: true))
          .toList();
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    widget.sp.updateMenuConfig(_items);
  }

  void _toggleVisibility(int index) {
    setState(() {
      _items[index] =
          _items[index].copyWith(visible: !_items[index].visible);
    });
    widget.sp.updateMenuConfig(_items);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: _items.length,
        onReorder: _onReorder,
        proxyDecorator: (child, index, animation) {
          return Material(
            color: Colors.transparent,
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final item = _items[index];
          final label =
              kMenuItemLabels[item.id] ?? item.id;

          return Container(
            key: ValueKey(item.id),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: index < _items.length - 1
                  ? Border(
                      bottom: BorderSide(
                        color: cs.onSurface.withValues(alpha: 0.04),
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(Icons.drag_handle_rounded,
                      size: 20,
                      color: cs.onSurface.withValues(alpha: 0.25)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: item.visible
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                // Visibility toggle
                GestureDetector(
                  onTap: () => _toggleVisibility(index),
                  child: Icon(
                    item.visible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 20,
                    color: item.visible
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
