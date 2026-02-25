// =============================================================
// NavOverlay — spring-animated navigation menu
// G3: Dead screen entries removed. 8 live screens only.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/utils/constants.dart';

// ── MenuItemId → GoRouter route name mapping ──────────────────────
const Map<String, String> _menuIdToRoute = {
  MenuItemId.dashboard:     'dashboard',
  MenuItemId.todaysPlan:    'todays-plan',
  MenuItemId.timeLogger:    'time-logger',
  MenuItemId.faLogger:      'fa-logger',
  MenuItemId.revision:      'revision',
  MenuItemId.knowledgeBase: 'knowledge-base',
  MenuItemId.analytics:     'analytics',
  MenuItemId.settings:      'settings',
};

// ── MenuItemId → Icon mapping ───────────────────────────────────
const Map<String, IconData> _menuIcons = {
  MenuItemId.dashboard:     Icons.dashboard_rounded,
  MenuItemId.todaysPlan:    Icons.today_rounded,
  MenuItemId.timeLogger:    Icons.schedule_rounded,
  MenuItemId.faLogger:      Icons.menu_book_rounded,
  MenuItemId.revision:      Icons.replay_rounded,
  MenuItemId.knowledgeBase: Icons.hub_rounded,
  MenuItemId.analytics:     Icons.bar_chart_rounded,
  MenuItemId.settings:      Icons.settings_rounded,
};

class NavOverlay extends StatefulWidget {
  final String currentScreenName;
  final VoidCallback onClose;

  const NavOverlay({
    super.key,
    required this.currentScreenName,
    required this.onClose,
  });

  @override
  State<NavOverlay> createState() => _NavOverlayState();
}

class _NavOverlayState extends State<NavOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);

    final spring = SpringDescription(
      mass: 1.0,
      stiffness: 300,
      damping: 30,
    );
    final simulation = SpringSimulation(spring, 0.0, 1.0, 0.0);
    _controller.animateWith(simulation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateTo(String routeName) {
    widget.onClose();
    context.goNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final settings = context.watch<SettingsProvider>();
    final menuConfig = settings.menuConfiguration;

    // Build visible menu items in order
    final visibleIds = <String>[];
    for (final id in kDefaultMenuOrder) {
      final config = menuConfig.cast<dynamic>().firstWhere(
            (c) => c.id == id,
            orElse: () => null,
          );
      if (config == null || config.visible) {
        visibleIds.add(id);
      }
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value.clamp(0.0, 1.0);

        return Stack(
          children: [
            // ── Scrim ───────────────────────────────────────────────
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4 * t),
                ),
              ),
            ),

            // ── Menu panel (slides from left) ─────────────────────────
            Positioned(
              top: 0,
              left: (t - 1.0) * 280,
              bottom: 0,
              width: 280,
              child: Material(
                color: cs.surface,
                elevation: 8,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                        child: Row(
                          children: [
                            Icon(Icons.bolt_rounded,
                                color: cs.primary, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'FocusFlow',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: cs.onSurface.withValues(alpha: 0.5)),
                              onPressed: widget.onClose,
                            ),
                          ],
                        ),
                      ),

                      Divider(color: cs.onSurface.withValues(alpha: 0.08)),

                      // ── Menu items ────────────────────────────────────
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          children: [
                            ...visibleIds.map((id) {
                              final label =
                                  kMenuItemLabels[id] ?? id;
                              final icon =
                                  _menuIcons[id] ?? Icons.circle_outlined;
                              final routeName =
                                  _menuIdToRoute[id] ?? 'dashboard';
                              final isActive =
                                  label == widget.currentScreenName;

                              return _NavTile(
                                icon: icon,
                                label: label,
                                isActive: isActive,
                                onTap: () => _navigateTo(routeName),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Individual nav tile ───────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive
            ? cs.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.85),
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
