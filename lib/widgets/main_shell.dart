// =============================================================
// MainShell — ShellRoute builder widget
// G4: 4 pinned tabs + permanent More tab + fullScreenMode
// Ultra-premium frosted glass bottom nav with glow indicators
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/utils/constants.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  final String currentLocation;

  const MainShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  // ── Icon map for all pinnable screens ─────────────────────────
  static const Map<String, IconData> _icons = {
    'dashboard': Icons.home_rounded,
    'todays-plan': Icons.today_rounded,
    'fa-logger': Icons.menu_book_rounded,
    'revision': Icons.replay_rounded,
    'knowledge-base': Icons.library_books_rounded,
    'time-logger': Icons.timer_rounded,
    'analytics': Icons.bar_chart_rounded,
    'settings': Icons.settings_rounded,
    'tracker': Icons.local_library_rounded,
  };

  // Normalise /knowledge-base/:id → knowledge-base for tab highlight
  String _routeToTabId(String location) {
    final path = location.startsWith('/') ? location.substring(1) : location;
    return path.split('/').first;
  }

  void _navigateTo(BuildContext context, String routeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastActiveTab', routeId);
    if (context.mounted) {
      context.go('/$routeId');
    }
  }

  void _showMoreSheet(BuildContext context, List<String> pinnedTabs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unpinned = kPinnableScreenLabels.keys
        .where((id) => !pinnedTabs.contains(id))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0E0E1A).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.88),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24)),
                border: Border.all(
                  color: isDark
                      ? DashboardColors.glassBorderDark
                      : DashboardColors.glassBorderLight,
                  width: 0.5,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        'More',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: DashboardColors.textPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: unpinned.length,
                        itemBuilder: (_, i) {
                          final id = unpinned[i];
                          final label =
                              kPinnableScreenLabels[id] ?? id;
                          final icon =
                              _icons[id] ?? Icons.circle_outlined;
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(ctx).pop();
                              _navigateTo(context, id);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: isDark
                                    ? Colors.white
                                        .withValues(alpha: 0.06)
                                    : DashboardColors.primary
                                        .withValues(alpha: 0.06),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white
                                          .withValues(alpha: 0.08)
                                      : DashboardColors.primary
                                          .withValues(alpha: 0.10),
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(icon,
                                      size: 24,
                                      color: isDark
                                          ? DashboardColors
                                              .primaryLight
                                          : DashboardColors.primary),
                                  const SizedBox(height: 6),
                                  Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: DashboardColors
                                          .textPrimary(isDark),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        // Full screen mode — just return child, AppScaffold handles nav
        if (settings.fullScreenMode) {
          return child;
        }

        final pinnedTabs = settings.pinnedTabs;
        final currentTabId = _routeToTabId(currentLocation);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Find selected index — fallback to 0 if not in pinned list
        int selectedIndex = pinnedTabs.indexOf(currentTabId);
        if (selectedIndex < 0) selectedIndex = 0;

        final moreIndex = pinnedTabs.length;

        return Scaffold(
          backgroundColor: DashboardColors.background(isDark),
          body: child,
          extendBody: true,
          bottomNavigationBar: _GlassBottomNav(
            pinnedTabs: pinnedTabs,
            selectedIndex: selectedIndex,
            moreIndex: moreIndex,
            isDark: isDark,
            icons: _icons,
            onTabSelected: (index) {
              if (index == moreIndex) {
                _showMoreSheet(context, pinnedTabs);
              } else if (index < pinnedTabs.length) {
                _navigateTo(context, pinnedTabs[index]);
              }
            },
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// FROSTED GLASS BOTTOM NAV
// ══════════════════════════════════════════════════════════════════

class _GlassBottomNav extends StatelessWidget {
  final List<String> pinnedTabs;
  final int selectedIndex;
  final int moreIndex;
  final bool isDark;
  final Map<String, IconData> icons;
  final ValueChanged<int> onTabSelected;

  const _GlassBottomNav({
    required this.pinnedTabs,
    required this.selectedIndex,
    required this.moreIndex,
    required this.isDark,
    required this.icons,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = <_NavItem>[
      ...List.generate(pinnedTabs.length, (i) {
        final id = pinnedTabs[i];
        return _NavItem(
          icon: icons[id] ?? Icons.circle_outlined,
          label: kPinnableScreenLabels[id] ?? id,
          isSelected: i == selectedIndex,
        );
      }),
      _NavItem(
        icon: Icons.grid_view_rounded,
        label: 'More',
        isSelected: false,
      ),
    ];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0E0E1A).withValues(alpha: 0.78)
                : Colors.white.withValues(alpha: 0.82),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? DashboardColors.glassBorderDark
                    : DashboardColors.glassBorderLight,
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(allItems.length, (i) {
                final item = allItems[i];
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTabSelected(i),
                    child: _NavButton(
                      item: item,
                      isDark: isDark,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
  });
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isDark;

  const _NavButton({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final activeColor = DashboardColors.primary;
    final inactiveColor = isDark
        ? DashboardColors.textSecondary
        : DashboardColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Glow dot indicator ──────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: item.isSelected ? 20 : 0,
          height: 3,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: item.isSelected ? activeColor : Colors.transparent,
            boxShadow: item.isSelected
                ? <BoxShadow>[
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.50),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        // ── Icon ─────────────────────────────────────────
        AnimatedScale(
          scale: item.isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Icon(
            item.icon,
            size: 22,
            color: item.isSelected ? activeColor : inactiveColor,
          ),
        ),
        const SizedBox(height: 3),
        // ── Label ────────────────────────────────────────
        Text(
          item.label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: item.isSelected ? FontWeight.w600 : FontWeight.w400,
            color: item.isSelected ? activeColor : inactiveColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
