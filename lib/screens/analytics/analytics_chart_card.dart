// =============================================================
// AnalyticsChartCard — reusable card wrapper for fl_chart charts
// Provides: title, optional subtitle, time-range badge, child slot.
// =============================================================

import 'package:flutter/material.dart';

class AnalyticsChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? rangeBadge;  // e.g. "7d" / "30d" / "90d"
  final Widget child;
  final EdgeInsetsGeometry? contentPadding;

  const AnalyticsChartCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.rangeBadge,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color:        cs.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color:       Colors.black.withValues(alpha: 0.04),
            blurRadius:  8,
            offset:      const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (rangeBadge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:        cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      rangeBadge!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:      cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Chart child ─────────────────────────────────────────
          Padding(
            padding: contentPadding ??
                const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}
