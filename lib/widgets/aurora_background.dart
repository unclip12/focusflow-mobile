// =============================================================
// AuroraBackground — animated gradient blob background
// Extracted from DashboardScreen for app-wide reuse.
// =============================================================

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:focusflow_mobile/utils/app_colors.dart';

class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.isDark});

  final bool isDark;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _AuroraPainter(
            progress: _controller.value,
            isDark: widget.isDark,
          ),
        );
      },
    );
  }
}

class _AuroraBlob {
  const _AuroraBlob(this.x, this.y, this.radius, this.speed, this.phase);

  final double x;
  final double y;
  final double radius;
  final double speed;
  final double phase;
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter({
    required this.progress,
    required this.isDark,
  });

  final double progress;
  final bool isDark;

  static const List<_AuroraBlob> _blobs = <_AuroraBlob>[
    _AuroraBlob(0.3, 0.2, 300, 0.0003, 0),
    _AuroraBlob(0.7, 0.4, 250, 0.0004, 2),
    _AuroraBlob(0.5, 0.7, 280, 0.00035, 4),
    _AuroraBlob(0.2, 0.8, 220, 0.00045, 1),
    _AuroraBlob(0.8, 0.15, 200, 0.0005, 3),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..color = isDark ? const Color(0xFF0E0E1A) : const Color(0xFFF0EFFF);
    canvas.drawRect(Offset.zero & size, background);

    final colors = DashboardColors.auroraBlobs(isDark);
    final time = progress * 20000;

    for (var index = 0; index < _blobs.length; index++) {
      final blob = _blobs[index];
      final color = colors[index];
      final center = Offset(
        size.width *
            (blob.x + (0.15 * math.sin((time * blob.speed) + blob.phase))),
        size.height *
            (blob.y +
                (0.10 * math.cos((time * blob.speed * 1.3) + blob.phase))),
      );
      final radius = blob.radius * (size.width / 400);
      final gradient = ui.Gradient.radial(
        center,
        radius,
        <Color>[
          color.withValues(alpha: isDark ? 0.50 : 0.30),
          color.withValues(alpha: isDark ? 0.12 : 0.08),
          color.withValues(alpha: 0),
        ],
        const <double>[0, 0.5, 1],
      );
      final paint = Paint()..shader = gradient;
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
