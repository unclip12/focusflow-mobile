// =============================================================
// AppScaffold — common scaffold used by every screen
// Header: screen name | streak counter
// Auto aurora background + glass header for ultra-premium look
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:focusflow_mobile/utils/app_colors.dart';
import 'package:focusflow_mobile/widgets/aurora_background.dart';

/// Base scaffold for all FocusFlow screens.
///
/// [screenName] — display name shown in the header.
/// [body] — the screen content.
/// [actions] — optional trailing header actions (icons, badges, etc.)
/// [streakCount] — current streak number. Defaults to 0.
/// [floatingActionButton] — optional FAB.
/// [showHeader] — whether to show the glass header bar. Defaults to true.
class AppScaffold extends StatefulWidget {
  final String screenName;
  final Widget body;
  final List<Widget>? actions;
  final int streakCount;
  final Widget? floatingActionButton;
  final bool showHeader;

  const AppScaffold({
    super.key,
    required this.screenName,
    required this.body,
    this.actions,
    this.streakCount = 0,
    this.floatingActionButton,
    this.showHeader = true,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: DashboardColors.background(isDark),
        floatingActionButton: widget.floatingActionButton,
        body: Stack(
          children: <Widget>[
            // ── Aurora background (covers entire screen) ───────
            Positioned.fill(
              child: AuroraBackground(isDark: isDark),
            ),

            // ── Content with SafeArea ─────────────────────────
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // ── Glass header bar ────────────────────────
                  if (widget.showHeader)
                    _GlassHeader(
                      screenName: widget.screenName,
                      streakCount: widget.streakCount,
                      actions: widget.actions,
                      isDark: isDark,
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
            ),
          ],
        ),
      ),
    );
  }
}

// ── Glass header bar ──────────────────────────────────────────────
class _GlassHeader extends StatelessWidget {
  final String screenName;
  final int streakCount;
  final List<Widget>? actions;
  final bool isDark;

  const _GlassHeader({
    required this.screenName,
    required this.streakCount,
    this.actions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.60),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? DashboardColors.glassBorderDark
                    : DashboardColors.glassBorderLight,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // ── Screen name ──────────────────────────────
              Text(
                screenName,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.textPrimary(isDark),
                ),
              ),

              const Spacer(),

              // ── Custom actions ───────────────────────────
              if (actions != null) ...actions!,

              // ── Streak counter ──────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? DashboardColors.primary.withValues(alpha: 0.15)
                      : DashboardColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DashboardColors.primary.withValues(alpha: 0.20),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 14, color: Colors.deepOrange),
                    const SizedBox(width: 4),
                    Text(
                      '$streakCount',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DashboardColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
