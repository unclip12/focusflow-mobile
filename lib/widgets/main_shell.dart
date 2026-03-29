import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focusflow_mobile/providers/settings_provider.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/utils/constants.dart';

const double kNavBarHeight = 72.0;

class MainShell extends StatefulWidget {
  final Widget child;
  final String currentLocation;

  const MainShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

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

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _isExitDialogOpen = false;

  String _routeToTabId(String location) {
    final path = location.startsWith('/') ? location.substring(1) : location;
    return path.split('/').first;
  }

  bool _hasNestedPath(String location) {
    final segments = location.split('/').where((segment) => segment.isNotEmpty);
    return segments.length > 1;
  }

  bool _isDashboardRoute(String location) {
    return _routeToTabId(location) == 'dashboard';
  }

  Future<void> _navigateTo(BuildContext context, String routeId) async {
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0E0E1A).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.88),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                          final label = kPinnableScreenLabels[id] ?? id;
                          final icon =
                              MainShell._icons[id] ?? Icons.circle_outlined;
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(ctx).pop();
                              _navigateTo(context, id);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : DashboardColors.primary
                                        .withValues(alpha: 0.06),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : DashboardColors.primary
                                          .withValues(alpha: 0.10),
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    icon,
                                    size: 24,
                                    color: isDark
                                        ? DashboardColors.primaryLight
                                        : DashboardColors.primary,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: DashboardColors.textPrimary(
                                        isDark,
                                      ),
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

  Future<bool> _showExitDialog(BuildContext context) async {
    if (_isExitDialogOpen) {
      return false;
    }

    _isExitDialogOpen = true;
    try {
      return await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Leave the app?'),
                content: const Text('Press OK to close FocusFlow.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          ) ??
          false;
    } finally {
      _isExitDialogOpen = false;
    }
  }

  Future<void> _handleBackPress(BuildContext context) async {
    final currentLocation = widget.currentLocation;

    if (_hasNestedPath(currentLocation)) {
      await _navigateTo(context, _routeToTabId(currentLocation));
      return;
    }

    if (!_isDashboardRoute(currentLocation)) {
      await _navigateTo(context, 'dashboard');
      return;
    }

    final shouldExit = await _showExitDialog(context);
    if (shouldExit && context.mounted) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        late final Widget shellChild;

        if (settings.fullScreenMode) {
          shellChild = widget.child;
        } else {
          final pinnedTabs = settings.pinnedTabs;
          final currentTabId = _routeToTabId(widget.currentLocation);
          final isDark = Theme.of(context).brightness == Brightness.dark;

          int selectedIndex = pinnedTabs.indexOf(currentTabId);
          final moreIndex = pinnedTabs.length;
          if (currentTabId == MenuItemId.settings) {
            selectedIndex = moreIndex;
          }

          shellChild = Scaffold(
            backgroundColor: DashboardColors.background(isDark),
            body: Stack(
              children: [
                Positioned.fill(
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      padding: MediaQuery.of(context).padding.copyWith(
                            bottom: MediaQuery.of(context).padding.bottom +
                                kNavBarHeight +
                                24,
                          ),
                    ),
                    child: widget.child,
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                  child: _GlassBottomNav(
                    pinnedTabs: pinnedTabs,
                    selectedIndex: selectedIndex,
                    moreIndex: moreIndex,
                    isDark: isDark,
                    icons: MainShell._icons,
                    onTabSelected: (index) {
                      if (index == moreIndex) {
                        _navigateTo(context, MenuItemId.settings);
                      } else if (index < pinnedTabs.length) {
                        _navigateTo(context, pinnedTabs[index]);
                      }
                    },
                    onTabLongPress: (index) {
                      if (index == moreIndex) {
                        _showMoreSheet(context, pinnedTabs);
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            _handleBackPress(context);
          },
          child: shellChild,
        );
      },
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  final List<String> pinnedTabs;
  final int selectedIndex;
  final int moreIndex;
  final bool isDark;
  final Map<String, IconData> icons;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<int> onTabLongPress;

  const _GlassBottomNav({
    required this.pinnedTabs,
    required this.selectedIndex,
    required this.moreIndex,
    required this.isDark,
    required this.icons,
    required this.onTabSelected,
    required this.onTabLongPress,
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
        icon: Icons.settings_rounded,
        label: 'Settings',
        isSelected: selectedIndex == moreIndex,
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0E0E1A).withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.35),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 30,
                spreadRadius: -6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(allItems.length, (i) {
                final item = allItems[i];
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTabSelected(i),
                    onLongPress: () => onTabLongPress(i),
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
    final inactiveColor =
        isDark ? DashboardColors.textSecondary : DashboardColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
