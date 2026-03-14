import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:focusflow_mobile/utils/app_colors.dart';

class LiquidGlassCard extends StatefulWidget {
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.delay = Duration.zero,
    this.glowColor,
    this.onTap,
    this.hero = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Duration delay;
  final Color? glowColor;
  final VoidCallback? onTap;
  final bool hero;
  final BorderRadius borderRadius;

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _rippleController;
  Timer? _entryTimer;
  bool _visible = false;
  bool _pressed = false;
  Offset _rippleOrigin = Offset.zero;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.delay == Duration.zero) {
      _visible = true;
    } else {
      _entryTimer = Timer(widget.delay, () {
        if (!mounted) return;
        setState(() {
          _visible = true;
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant LiquidGlassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delay != widget.delay && !_visible) {
      _entryTimer?.cancel();
      if (widget.delay == Duration.zero) {
        setState(() {
          _visible = true;
        });
      } else {
        _entryTimer = Timer(widget.delay, () {
          if (!mounted) return;
          setState(() {
            _visible = true;
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _entryTimer?.cancel();
    _shimmerController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _pressed = true;
      _rippleOrigin = details.localPosition;
    });
    _rippleController
      ..stop()
      ..reset()
      ..forward();
  }

  void _handleTapEnd([Object? _]) {
    if (!mounted) return;
    setState(() {
      _pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        (isDark ? const Color(0xFF1E1E3A) : const Color(0xFFFFFFFF))
            .withValues(alpha: isDark ? 0.92 : 0.88);
    final borderColor =
        const Color(0xFF6366F1).withValues(alpha: isDark ? 0.35 : 0.25);
    final glowBaseColor = widget.glowColor ?? const Color(0xFF6366F1);
    final glowColor =
        glowBaseColor.withValues(alpha: isDark ? 0.18 : 0.12);
    final glowShadow = BoxShadow(
      color: glowColor,
      blurRadius: isDark ? 24 : 20,
      spreadRadius: isDark ? -4 : -2,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _visible ? 1 : 0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final scale = ui.lerpDouble(0.92, 1.0, value) ?? 1.0;
        final translateY = ui.lerpDouble(30, 0, value) ?? 0;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _handleTapDown,
          onTapCancel: _handleTapEnd,
          onTapUp: _handleTapEnd,
          onTap: widget.onTap,
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: Stack(
              children: <Widget>[
                // if (defaultTargetPlatform == TargetPlatform.iOS)
                //   Positioned.fill(
                //     child: BackdropFilter(
                //       filter: ui.ImageFilter.blur(
                //         sigmaX: 25,
                //         sigmaY: 25,
                //       ),
                //       child: Container(color: Colors.transparent),
                //     ),
                //   ),
                Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: widget.borderRadius,
                    border: Border.all(
                      color: borderColor,
                      width: 1.5,
                    ),
                    boxShadow: <BoxShadow>[glowShadow],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final rippleAlignment = Alignment(
                        ((constraints.maxWidth == 0
                                    ? 0
                                    : _rippleOrigin.dx / constraints.maxWidth) *
                                2) -
                            1,
                        ((constraints.maxHeight == 0
                                    ? 0
                                    : _rippleOrigin.dy / constraints.maxHeight) *
                                2) -
                            1,
                      );

                      return Stack(
                        fit: StackFit.passthrough,
                        children: <Widget>[
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: <Color>[
                                      Colors.white.withValues(
                                        alpha: isDark ? 0.15 : 0.35,
                                      ),
                                      Colors.transparent,
                                      const Color(0xFF6366F1).withValues(
                                        alpha: isDark ? 0.10 : 0.06,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _shimmerController,
                                builder: (context, child) {
                                  final width = constraints.maxWidth;
                                  final shimmerWidth = width * 1.6;
                                  final travel = width + shimmerWidth;
                                  final x = ui.lerpDouble(
                                        shimmerWidth / 2,
                                        -travel,
                                        _shimmerController.value,
                                      ) ??
                                      0;
                                  return Transform.translate(
                                    offset: Offset(x, 0),
                                    child: Transform.rotate(
                                      angle: -0.30,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  width: constraints.maxWidth * 0.45,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: <Color>[
                                        DashboardColors.shimmerTransparent,
                                        DashboardColors.shimmerSoft,
                                        DashboardColors.shimmerBright,
                                        DashboardColors.shimmerSoft,
                                        DashboardColors.shimmerTransparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: FadeTransition(
                                opacity: Tween<double>(
                                  begin: 0.3,
                                  end: 0,
                                ).animate(_rippleController),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: rippleAlignment,
                                      radius: 0.8,
                                      colors: <Color>[
                                        DashboardColors.primary.withValues(
                                          alpha: 0.30,
                                        ),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: widget.borderRadius,
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                      alpha: isDark ? 0.06 : 0.18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          widget.child,
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
