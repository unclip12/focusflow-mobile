import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.decimals = 0,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.style,
    this.textAlign,
  });

  final double value;
  final int decimals;
  final String prefix;
  final String suffix;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> {
  Timer? _timer;
  double _target = 0;

  @override
  void initState() {
    super.initState();
    _schedule(widget.value);
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.delay != widget.delay) {
      _schedule(widget.value);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule(double value) {
    _timer?.cancel();
    if (widget.delay == Duration.zero) {
      if (mounted) {
        setState(() {
          _target = value;
        });
      }
      return;
    }
    _timer = Timer(widget.delay, () {
      if (!mounted) return;
      setState(() {
        _target = value;
      });
    });
  }

  String _format(double value) {
    return '${widget.prefix}${value.toStringAsFixed(widget.decimals)}'
        '${widget.suffix}';
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.style ?? GoogleFonts.inter();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _target),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, value, child) {
        return Text(
          _format(value),
          style: textStyle,
          textAlign: widget.textAlign,
        );
      },
    );
  }
}
