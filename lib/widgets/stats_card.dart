// =============================================================
// StatsCard / TodayGlance — reusable dashboard stat widgets
// =============================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Single stat tile with icon, label, and value.
class StatsCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;

  const StatsCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
  });

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = widget.accentColor ?? cs.primary;

    // Try to parse a numeric value for animation
    final numericValue = double.tryParse(widget.value.replaceAll(RegExp(r'[^0-9.]'), ''));
    final isNumeric = numericValue != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, size: 20, color: accent),
          ),
          const SizedBox(height: 12),
          if (isNumeric)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: numericValue),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, val, _) {
                return Text(
                  '${val.round()}',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                );
              },
            )
          else
            Text(widget.value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(widget.label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}

/// Today's Glance card — blocks done/total + study hours today.
class TodayGlanceCard extends StatelessWidget {
  final int blocksDone;
  final int blocksTotal;
  final double studyHoursToday;

  const TodayGlanceCard({
    super.key,
    required this.blocksDone,
    required this.blocksTotal,
    required this.studyHoursToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final progress = blocksTotal > 0 ? blocksDone / blocksTotal : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.15),
            cs.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // ── Ring chart ──────────────────────────────────────────
          SizedBox(
            width: 64,
            height: 64,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                trackColor: cs.onSurface.withValues(alpha: 0.08),
                progressColor: cs.primary,
              ),
              child: Center(
                child: Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // ── Stats ──────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Glance",
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStat(
                      label: 'Blocks',
                      value: '$blocksDone/$blocksTotal',
                      icon: Icons.check_circle_outline_rounded,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 20),
                    _MiniStat(
                      label: 'Hours',
                      value: studyHoursToday.toStringAsFixed(1),
                      icon: Icons.schedule_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(value,
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(width: 3),
        Text(label,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12)),
      ],
    );
  }
}

// ── Ring painter ─────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 6.0;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
