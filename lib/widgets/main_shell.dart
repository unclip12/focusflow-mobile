// =============================================================
// MainShell — ShellRoute builder widget
// G4: 4 pinned tabs + permanent More tab + fullScreenMode
// =============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:focusflow_mobile/providers/settings_provider.dart';
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
    'dashboard':      Icons.home_rounded,
    'todays-plan':    Icons.today_rounded,
    'fa-logger':      Icons.menu_book_rounded,
    'revision':       Icons.replay_rounded,
    'knowledge-base': Icons.library_books_rounded,
    'time-logger':    Icons.timer_rounded,
    'analytics':      Icons.bar_chart_rounded,
    'settings':       Icons.settings_rounded,
    'tracker':        Icons.local_library_rounded,
  };

  // Normalise /knowledge-base/:id → knowledge-base for tab highlight
  String _routeToTabId(String location) {
    final path = location.startsWith('/') ? location.substring(1) : location;
    return path.split('/').first;
  }

  void _navigateTo(BuildContext context, String routeId) {
    context.go('/$routeId');
  }

  void _showMoreSheet(BuildContext context, List<String> pinnedTabs) {
    final unpinned = kPinnableScreenLabels.keys
        .where((id) => !pinnedTabs.contains(id))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
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
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'More',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: unpinned.length,
                  itemBuilder: (_, i) {
                    final id = unpinned[i];
                    final label = kPinnableScreenLabels[id] ?? id;
                    final icon = _icons[id] ?? Icons.circle_outlined;
                    return InkWell(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _navigateTo(context, id);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 26),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
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

        // Find selected index — fallback to 0 if not in pinned list
        int selectedIndex = pinnedTabs.indexOf(currentTabId);
        if (selectedIndex < 0) selectedIndex = 0;

        final moreIndex = pinnedTabs.length;

        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              if (index == moreIndex) {
                _showMoreSheet(context, pinnedTabs);
              } else if (index < pinnedTabs.length) {
                _navigateTo(context, pinnedTabs[index]);
              }
            },
            destinations: [
              ...List.generate(pinnedTabs.length, (i) {
                final id = pinnedTabs[i];
                final label = kPinnableScreenLabels[id] ?? id;
                final icon = _icons[id] ?? Icons.circle_outlined;
                return NavigationDestination(
                  icon: Icon(icon),
                  label: label,
                );
              }),
              const NavigationDestination(
                icon: Icon(Icons.grid_view_rounded),
                label: 'More',
              ),
            ],
          ),
        );
      },
    );
  }
}
