// =============================================================
// showAppBottomSheet — reusable draggable liquid-glass bottom sheet
// Pull up to expand, pull down to dismiss. Frosted glass theme.
// =============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:focusflow_mobile/utils/app_colors.dart';

/// Shows a modal bottom sheet that is:
///  • Draggable (pull up to expand, pull all the way down to close)
///  • Liquid-glass themed (frosted blur + glass borders)
///
/// [builder] receives a [ScrollController] that MUST be attached to
/// any scrollable child (ListView, SingleChildScrollView, etc.) so
/// the drag-to-expand gesture chains properly with inner scrolling.
///
/// For non-scrollable content, just ignore the controller.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, ScrollController scrollController) builder,
  double initialChildSize = 0.5,
  double minChildSize = 0.3,
  double maxChildSize = 0.95,
  bool snap = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return _GlassDraggableSheet<T>(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        snap: snap,
        contentBuilder: builder,
      );
    },
  );
}

class _GlassDraggableSheet<T> extends StatelessWidget {
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool snap;
  final Widget Function(BuildContext, ScrollController) contentBuilder;

  const _GlassDraggableSheet({
    required this.initialChildSize,
    required this.minChildSize,
    required this.maxChildSize,
    required this.snap,
    required this.contentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snap: snap,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0E0E1A).withValues(alpha: 0.82)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: isDark
                      ? DashboardColors.glassBorderDark
                      : DashboardColors.glassBorderLight,
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  // ── Glass drag handle ──────────────────────
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // ── Content ────────────────────────────────
                  Expanded(
                    child: contentBuilder(context, scrollController),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
