// =============================================================
// AppScaffold — common scaffold used by every screen
// Header: screen name (tap → nav overlay) | streak counter
// =============================================================

import 'package:flutter/material.dart';
import 'package:focusflow_mobile/widgets/nav_overlay.dart';

/// Base scaffold for all FocusFlow screens.
///
/// [screenName] — display name shown in the header (tappable → opens nav).
/// [body] — the screen content.
/// [actions] — optional trailing header actions (icons, badges, etc.)
/// [streakCount] — current streak number. Defaults to 0.
/// [floatingActionButton] — optional FAB.
class AppScaffold extends StatefulWidget {
  final String screenName;
  final Widget body;
  final List<Widget>? actions;
  final int streakCount;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.screenName,
    required this.body,
    this.actions,
    this.streakCount = 0,
    this.floatingActionButton,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _navOpen = false;

  void _toggleNav() => setState(() => _navOpen = !_navOpen);
  void _closeNav() => setState(() => _navOpen = false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      floatingActionButton: widget.floatingActionButton,
      body: Stack(
        children: [
          // ── Main content ──────────────────────────────────────
          Column(
            children: [
              // Safe area top + header
              Container(
                color: cs.surface,
                child: SafeArea(
                  bottom: false,
                  child: _Header(
                    screenName: widget.screenName,
                    streakCount: widget.streakCount,
                    onMenuTap: _toggleNav,
                    actions: widget.actions,
                  ),
                ),
              ),
              // Body — animated page transition
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: slide,
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(widget.screenName),
                    child: widget.body,
                  ),
                ),
              ),
            ],
          ),

          // ── Nav overlay (on top) ─────────────────────────────
          if (_navOpen)
            NavOverlay(
              currentScreenName: widget.screenName,
              onClose: _closeNav,
            ),
        ],
      ),
    );
  }
}

// ── Header bar ──────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String screenName;
  final int streakCount;
  final VoidCallback onMenuTap;
  final List<Widget>? actions;

  const _Header({
    required this.screenName,
    required this.streakCount,
    required this.onMenuTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // ── Screen name (tappable) ───────────────────────────
          GestureDetector(
            onTap: onMenuTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_rounded, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  screenName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ── Custom actions ───────────────────────────────────
          if (actions != null) ...actions!,

          // ── Streak counter ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$streakCount',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
