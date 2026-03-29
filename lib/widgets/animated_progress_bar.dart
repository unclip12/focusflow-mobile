import 'dart:async';

import 'package:flutter/material.dart';

import 'package:focusflow_mobile/utils/app_colors.dart';

class AnimatedProgressBar extends StatefulWidget {
  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.delay = Duration.zero,
    this.height = 6,
  });

  final double progress;
  final Color? color;
  final Duration delay;
  final double height;

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar> {
  Timer? _timer;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _schedule(widget.progress);
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress ||
        oldWidget.delay != widget.delay) {
      _schedule(widget.progress);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule(double progress) {
    _timer?.cancel();
    final target = progress.clamp(0, 100).toDouble();
    if (widget.delay == Duration.zero) {
      if (mounted) {
        setState(() {
          _progress = target;
        });
      }
      return;
    }
    _timer = Timer(widget.delay, () {
      if (!mounted) return;
      setState(() {
        _progress = target;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.color ?? DashboardColors.primary;
    final trackColor = isDark
        ? const Color.fromRGBO(255, 255, 255, 0.10)
        : DashboardColors.primary.withValues(alpha: 0.10);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.height),
      child: Container(
        height: widget.height,
        color: trackColor,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: _progress / 100),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value.clamp(0, 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: DashboardColors.progressGradient(color),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: color.withValues(alpha: 0.38),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: SizedBox(height: widget.height),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
